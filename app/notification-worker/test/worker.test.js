import {test, beforeEach, afterEach} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import worker from '../src/index.js';

const id = '12345678-1234-4234-8234-123456789abc';
const secondId = '22345678-1234-4234-8234-123456789abc';
const field = (stringValue) => ({stringValue});
let db, env, task, members, uid, calls, provider, authStatus, taskStatus, claims, failUpdate;
const originalFetch = globalThis.fetch;
beforeEach(() => {
  db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  env = {FIREBASE_PROJECT_ID: 'project', FIREBASE_WEB_API_KEY: 'public',
    ONESIGNAL_APP_ID: 'app', ONESIGNAL_REST_API_KEY: 'test-secret',
    DB: {prepare(sql) { return {bind(...args) { return {
      async first() {return db.prepare(sql).get(...args) ?? null;},
      async run() {
        if (failUpdate && sql.startsWith('UPDATE')) throw Error('D1 unavailable');
        return db.prepare(sql).run(...args);
      },
    };}};}}};
  task = {status: field('pending'), scope: field('shared'),
    scopeId: field('household:alice|bob'), assigneeId: field('bob'), title: field('Private title')};
  members = ['alice', 'bob']; uid = 'alice'; calls = []; authStatus = 200; taskStatus = 200;
  claims = {aud: 'project', iss: 'https://securetoken.google.com/project', sub: uid, exp: Date.now()/1000+3600};
  failUpdate = false;
  provider = () => Response.json({id: 'message'});
  globalThis.fetch = async (url, options) => {
    calls.push({url, options});
    if (url.includes('identitytoolkit')) return Response.json({users: [{localId: uid}]}, {status: authStatus});
    if (url.includes('/documents/household_tasks/')) return Response.json({fields: task}, {status: taskStatus});
    if (url.endsWith(':runQuery')) return Response.json([{document: {fields: {
      type: field('shared'), memberIds: {arrayValue: {values: members.map(field)}},
    }}}]);
    if (url === 'https://api.onesignal.com/notifications') return provider(options);
    throw Error(`Unexpected URL: ${url}`);
  };
});
afterEach(() => {globalThis.fetch = originalFetch; db.close();});
function request(body = {reminderId: id, taskId: 'task'}, token = true) {
  const jwt = `header.${Buffer.from(JSON.stringify(claims)).toString('base64url')}.signature`;
  return worker.fetch(new Request('https://worker/household/reminders', {
    method: 'POST', headers: token ? {Authorization: `Bearer ${jwt}`} : {}, body: JSON.stringify(body),
  }), env);
}
const pushes = () => calls.filter(c => c.url.includes('onesignal.com'));
for (const [name, setup, status] of [
  ['invalid token', () => {authStatus = 400;}, 401],
  ['expired token', () => {claims.exp = 1;}, 401],
  ['wrong Firebase project', () => {claims.aud = 'other';}, 401],
  ['missing task', () => {taskStatus = 404;}, 404],
  ['personal task', () => {task.scope = field('personal');}, 409],
  ['completed task', () => {task.status = field('completed');}, 409],
  ['sender outside household', () => {uid = 'mallory'; claims.sub = uid;}, 403],
  ['disconnected household', () => {members = ['alice'];}, 403],
  ['different household membership', () => {members.push('eve');}, 403],
  ['self recipient', () => {task.assigneeId = field('alice');}, 409],
  ['recipient outside household', () => {task.assigneeId = field('eve');}, 409],
  ['unassigned task', () => {delete task.assigneeId;}, 409],
]) test(name, async () => {setup(); assert.equal((await request()).status, status); assert.equal(pushes().length, 0);});
test('missing token', async () => {assert.equal((await request(undefined, false)).status, 401); assert.equal(calls.length, 0);});
test('strict input validation', async () => {
  for (const body of [null, {}, {reminderId: id, taskId: {}}, {reminderId: 'bad', taskId: 'task'}]) {
    assert.equal((await request(body)).status, 400);
  }
  assert.equal(pushes().length, 0);
});
test('derives only partner from Firestore and uses Firebase token for reads', async () => {
  const response = await request({reminderId: id, taskId: 'task', recipientUserId: 'eve', senderUserId: 'bob'});
  assert.equal(response.status, 200); assert.equal((await response.json()).ok, true);
  const payload = JSON.parse(pushes()[0].options.body);
  assert.deepEqual(payload.include_aliases, {external_id: ['bob']});
  assert.equal(payload.target_channel, 'push'); assert.equal(payload.idempotency_key, id);
  assert.equal(payload.included_segments, undefined); assert.equal(payload.include_subscription_ids, undefined);
  assert.ok(!JSON.stringify(payload).includes('Private title'));
  assert.match(calls.find(c => c.url.includes('firestore')).options.headers.authorization, /^Bearer /);
});
test('same reminder returns success without another push', async () => {
  await request(); const retry = await request();
  assert.equal(retry.status, 200); assert.equal((await retry.json()).idempotent, true); assert.equal(pushes().length, 1);
});
test('identifier cannot be reused for another task or sender', async () => {
  await request();
  assert.equal((await request({reminderId: id, taskId: 'other'})).status, 409);
  uid = 'bob'; claims.sub = uid; task.assigneeId = field('alice');
  assert.equal((await request()).status, 409); assert.equal(pushes().length, 1);
});
test('replay still validates current membership', async () => {
  await request(); members = ['alice']; assert.equal((await request()).status, 403);
});
test('cooldown rejects a new reminder', async () => {
  await request(); const result = await request({reminderId: secondId, taskId: 'task'});
  assert.equal(result.status, 429); assert.ok((await result.json()).retryAfterSeconds > 0); assert.equal(pushes().length, 1);
});
test('concurrent requests send once', async () => {
  const responses = await Promise.all([request(), request()]);
  assert.ok(responses.some(r => r.status === 200)); assert.equal(pushes().length, 1);
});
for (const [name, reply, status] of [
  ['provider rejection', () => Response.json({errors: ['bad']}, {status: 500}), 502],
  ['no subscribed recipient', () => Response.json({id: '', errors: ['not subscribed']}), 422],
  ['malformed provider success', () => new Response('invalid'), 502],
  ['null provider success', () => Response.json(null), 502],
  ['network timeout', () => {throw Error('timeout');}, 503],
]) test(name, async () => {
  provider = reply; const result = await request(); assert.equal(result.status, status);
  assert.ok(!(await result.json()).ok);
  provider = () => Response.json({id: 'message'});
  assert.equal((await request()).status, 200);
  assert.equal(JSON.parse(pushes()[0].options.body).idempotency_key, JSON.parse(pushes()[1].options.body).idempotency_key);
});
test('accepted push followed by D1 failure retries with the same provider key', async () => {
  failUpdate = true; assert.equal((await request()).status, 500);
  failUpdate = false; assert.equal((await request()).status, 200);
  assert.equal(JSON.parse(pushes()[0].options.body).idempotency_key, JSON.parse(pushes()[1].options.body).idempotency_key);
});
test('ambiguous reminder cannot resend after provider idempotency expires', async () => {
  provider = () => {throw Error('timeout');}; await request();
  db.prepare('UPDATE partner_reminders SET created_at_ms = 0').run();
  assert.equal((await request()).status, 409); assert.equal(pushes().length, 1);
});
