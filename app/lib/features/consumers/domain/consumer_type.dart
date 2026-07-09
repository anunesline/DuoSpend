enum ConsumerType {
  person,
  house,
  pet,
  family;

  String get label {
    switch (this) {
      case ConsumerType.person:
        return 'Pessoa';
      case ConsumerType.house:
        return 'Casa';
      case ConsumerType.pet:
        return 'Pet';
      case ConsumerType.family:
        return 'Família';
    }
  }

  String get value {
    switch (this) {
      case ConsumerType.person:
        return 'person';
      case ConsumerType.house:
        return 'house';
      case ConsumerType.pet:
        return 'pet';
      case ConsumerType.family:
        return 'family';
    }
  }

  static ConsumerType fromValue(String value) {
    switch (value) {
      case 'house':
        return ConsumerType.house;
      case 'pet':
        return ConsumerType.pet;
      case 'family':
        return ConsumerType.family;
      case 'person':
      default:
        return ConsumerType.person;
    }
  }
}