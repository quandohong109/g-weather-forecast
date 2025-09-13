class Location {
  final int? id;
  final String? name;
  final String? region;
  final String? country;

  Location({
    this.id,
    this.name,
    this.region,
    this.country,
  });

  factory Location.fromMap(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as int?,
      name: json['name'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
    );
  }
}