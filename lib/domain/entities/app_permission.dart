class AppPermission {
  final String id;
  final String section;
  final List<String> permittedRoles;

  const AppPermission({
    required this.id,
    required this.section,
    required this.permittedRoles,
  });

  AppPermission copyWith({
    String? id,
    String? section,
    List<String>? permittedRoles,
  }) {
    return AppPermission(
      id: id ?? this.id,
      section: section ?? this.section,
      permittedRoles: permittedRoles ?? this.permittedRoles,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'section': section,
      'permittedRoles': permittedRoles,
    };
  }

  factory AppPermission.fromMap(Map<String, dynamic> map) {
    return AppPermission(
      id: map['id'] as String? ?? '',
      section: map['section'] as String? ?? '',
      permittedRoles: (map['permittedRoles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
