// lib/widgets/forecast_card.dart
import 'package:flutter/material.dart';
import 'package:g_weather_forecast/objects/weather_data.dart';
import 'package:intl/intl.dart';

class ForecastCard extends StatelessWidget {
  final double width;
  final WeatherData weather;

  const ForecastCard({
    super.key,
    required this.width,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  DateFormat('(yyyy-MM-dd)').format(weather.date),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface
                  )
              ),
              const SizedBox(height: 8),
              Image.network(weather.iconUrl, width: 40, height: 40),
              const SizedBox(height: 8),
              Text(
                  'Temp: ${weather.temperature.toStringAsFixed(2)}°C',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
              ),
              const SizedBox(height: 4),
              Text(
                  'Wind: ${weather.windSpeed.toStringAsFixed(2)} M/S',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
              ),
              const SizedBox(height: 4),
              Text(
                  'Humidity: ${weather.humidity}%',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
