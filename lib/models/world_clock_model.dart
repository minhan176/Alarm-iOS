class WorldClockModel {
  final String id;
  final String city;
  final String timezone;
  final String country;

  WorldClockModel({
    required this.id,
    required this.city,
    required this.timezone,
    required this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city': city,
      'timezone': timezone,
      'country': country,
    };
  }

  factory WorldClockModel.fromJson(Map<String, dynamic> json) {
    return WorldClockModel(
      id: json['id'],
      city: json['city'],
      timezone: json['timezone'],
      country: json['country'],
    );
  }

  WorldClockModel copyWith({
    String? id,
    String? city,
    String? timezone,
    String? country,
  }) {
    return WorldClockModel(
      id: id ?? this.id,
      city: city ?? this.city,
      timezone: timezone ?? this.timezone,
      country: country ?? this.country,
    );
  }
}
