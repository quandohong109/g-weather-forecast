import 'package:flutter/material.dart';
import 'package:g_weather_forecast/objects/weather_data.dart';
import 'package:intl/intl.dart';

class CurrentWeatherCard extends StatelessWidget {
  final WeatherData weather;
  const CurrentWeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.cityName} (${DateFormat('yyyy-MM-dd').format(weather.date)})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Temperature: ${weather.temperature.toStringAsFixed(2)}°C',
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Wind: ${weather.windSpeed.toStringAsFixed(2)} M/S',
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Humidity: ${weather.humidity}%',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Image.network(
                    weather.iconUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.fill,
                  ),
                  const SizedBox(width: 10),
                  Text(weather.condition, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
