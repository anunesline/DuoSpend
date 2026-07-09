import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/consumer_profile_entity.dart';
import '../../domain/repositories/consumer_profile_repository.dart';
import '../mappers/consumer_profile_mapper.dart';
import '../models/consumer_profile_model.dart';

class FirestoreConsumerProfileRepository implements ConsumerProfileRepository {
  final FirebaseFirestore _firestore;
  final ConsumerProfileMapper _mapper;

  FirestoreConsumerProfileRepository({
    FirebaseFirestore? firestore,
    ConsumerProfileMapper? mapper,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _mapper = mapper ?? const ConsumerProfileMapper();

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection('consumers');
  }

  @override
  Future<List<ConsumerProfileEntity>> getAll() async {
    final snapshot = await _collection.get();

    return snapshot.docs
        .map((doc) => ConsumerProfileModel.fromMap(doc.data()))
        .map(_mapper.toEntity)
        .toList();
  }

  @override
  Future<List<ConsumerProfileEntity>> getByWalletId(
    String walletId,
  ) async {
    final snapshot = await _collection
        .where(
          'walletId',
          isEqualTo: walletId,
        )
        .get();

    return snapshot.docs
        .map((doc) => ConsumerProfileModel.fromMap(doc.data()))
        .map(_mapper.toEntity)
        .toList();
  }

  @override
  Future<ConsumerProfileEntity?> getById(
    String id,
  ) async {
    final doc = await _collection.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final model = ConsumerProfileModel.fromMap(doc.data()!);

    return _mapper.toEntity(model);
  }

  @override
  Future<void> save(
    ConsumerProfileEntity consumer,
  ) async {
    final model = _mapper.toModel(consumer);

    await _collection.doc(consumer.id).set(
          model.toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> delete(
    String id,
  ) async {
    await _collection.doc(id).delete();
  }
}