double? parseMoneyInput(String value) {
  final normalized = value
      .trim()
      .replaceAll(RegExp(r'[^0-9,.-]'), '');

  if (normalized.isEmpty || normalized == '-' || normalized == ',' ||
      normalized == '.') {
    return null;
  }

  final commaIndex = normalized.lastIndexOf(',');
  final dotIndex = normalized.lastIndexOf('.');
  final decimalIndex = commaIndex > dotIndex ? commaIndex : dotIndex;
  final hasBothSeparators = commaIndex >= 0 && dotIndex >= 0;

  final digits = StringBuffer();

  for (var index = 0; index < normalized.length; index++) {
    final character = normalized[index];

    if (character == '-' && index == 0) {
      digits.write(character);
    } else if (character.codeUnitAt(0) >= 48 &&
        character.codeUnitAt(0) <= 57) {
      digits.write(character);
    } else if (index == decimalIndex) {
      digits.write('.');
    } else if (!hasBothSeparators && character == '.') {
      // Com ponto como separador decimal, somente a última ocorrência vale.
    }
  }

  return double.tryParse(digits.toString());
}
