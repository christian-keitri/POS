class Category {
  final int id;
  final String name;
  final String? description;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt()
          ?? (json['sort_order'] as num?)?.toInt()
          ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'sortOrder': sortOrder,
      };
}
