import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/utils/money_parser.dart';

void main() {
  group('parseMoneyInput', () {
    test('aceita vírgula e ponto como separador decimal', () {
      expect(parseMoneyInput('100,50'), 100.50);
      expect(parseMoneyInput('100.50'), 100.50);
    });

    test('normaliza valores monetários com separador de milhar', () {
      expect(parseMoneyInput('R\$ 1.234,56'), 1234.56);
      expect(parseMoneyInput(r'$ 1,234.56'), 1234.56);
    });

    test('rejeita entrada sem valor numérico', () {
      expect(parseMoneyInput('R\$ .'), isNull);
      expect(parseMoneyInput(''), isNull);
    });
  });
}
