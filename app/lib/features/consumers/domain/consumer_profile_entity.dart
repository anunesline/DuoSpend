import './consumer_type.dart';

class ConsumerProfileEntity {
  final String id;
  final String name;
  final ConsumerType type;
  final String? icon;
  final String? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ConsumerProfileEntity({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  ConsumerProfileEntity copyWith({
    String? id,
    String? name,
    ConsumerType? type,
    String? icon,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsumerProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPerson => type == ConsumerType.person;
  bool get isHouse => type == ConsumerType.house;
  bool get isPet => type == ConsumerType.pet;
  bool get isFamily => type == ConsumerType.family;
}