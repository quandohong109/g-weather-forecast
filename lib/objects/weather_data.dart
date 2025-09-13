class WeatherData {
  final String cityName;
  final DateTime date;
  final double temperature;
  final double windSpeed;
  final int humidity;
  final String condition;
  final String iconUrl;

  WeatherData({
    required this.cityName,
    required this.date,
    required this.temperature,
    required this.windSpeed,
    required this.humidity,
    required this.condition,
    required this.iconUrl,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['cityName'],
      date: DateTime.parse(json['date']),
      temperature: json['temperature'],
      windSpeed: json['windSpeed'],
      humidity: json['humidity'],
      condition: json['condition'],
      iconUrl: json['iconUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'date': date.toIso8601String(),
      'temperature': temperature,
      'windSpeed': windSpeed,
      'humidity': humidity,
      'condition': condition,
      'iconUrl': iconUrl,
    };
  }
}