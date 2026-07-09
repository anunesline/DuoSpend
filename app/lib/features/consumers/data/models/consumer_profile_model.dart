class ConsumerProfileModel {
  final String id;
  final String? walletId;
  final String name;
  final String type;
  final String? icon;
  final String? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConsumerProfileModel({
    required this.id,
    this.walletId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'walletId': walletId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ConsumerProfileModel.fromMap(Map<String, dynamic> map) {
    return ConsumerProfileModel(
      id: map['id'] ?? '',
      walletId: map['walletId'],
      name: map['name'] ?? '',
      type: map['type'] ?? 'person',
      icon: map['icon'],
      color: map['color'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.tryParse(
            map['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }
}