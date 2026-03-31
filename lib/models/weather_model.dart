class Weather {
  final String description;
  final double temp;
  final String city;

  Weather({
    required this.description,
    required this.temp,
    required this.city,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      description: json['weather'][0]['description'],
      temp: json['main']['temp'].toDouble(),
      city: json['name'],
    );
  }
}