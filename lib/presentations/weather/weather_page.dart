// lib/presentations/weather/weather_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:g_weather_forecast/objects/weather_data.dart';
import 'package:g_weather_forecast/presentations/weather/weather_cubit.dart';
import 'package:g_weather_forecast/presentations/weather/weather_state.dart';
import 'package:g_weather_forecast/widgets/city_search_card.dart';

import '../../objects/location.dart';
import '../../widgets/current_weather_card.dart';
import '../../widgets/forecast_card.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  static Widget newInstance() => BlocProvider(
    create: (context) => WeatherCubit(),
    child: const WeatherPage(),
  );

  @override
  State<WeatherPage> createState() => _WeatherPage();
}

class _WeatherPage extends State<WeatherPage> {
  WeatherCubit get cubit => context.read<WeatherCubit>();
  final TextEditingController typeAheadController = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    typeAheadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WeatherCubit, WeatherState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.error}')),
          );
        }
        if (state.updateTextField && state.currentWeather != null) {
          if (typeAheadController.text != state.currentWeather!.cityName) {
            typeAheadController.text = state.currentWeather!.cityName;
          }
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Desktop layout
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSearchColumn(context),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildWeatherContent(),
                ),
              ],
            );
          } else {
            // Mobile layout
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchColumn(context),
                  const SizedBox(height: 20),
                  _buildWeatherContent(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CitySearchCard(
          suggestionsCallback: cubit.searchCities,
          typeAheadController: typeAheadController,
          onCitySelected: (location) {
            cubit.setCityID(location.id?.toString() ?? '');
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => cubit.getWeather(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'Search',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'or',
            style: TextStyle(color: Theme.of(context).colorScheme.surface),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => cubit.getWeatherForCurrentLocation(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'Use Current Location',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherContent() {
    return BlocBuilder<WeatherCubit, WeatherState>(
      builder: (context, state) {
        if (state.isLoading && state.currentWeather == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.currentWeather == null && state.forecast == null) {
          return const Center(
              child: Text('Search for a city to see the weather.'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (state.currentWeather != null)
                _buildCurrentWeatherCard(context, state.currentWeather!),
              const SizedBox(height: 20),
              if (state.forecast != null)
                _buildForecastSection(context, state.forecast!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentWeatherCard(
      BuildContext context, WeatherData currentWeather) {
    return CurrentWeatherCard(weather: currentWeather);
  }

  Widget _buildForecastSection(
      BuildContext context, List<WeatherData> forecast) {
    final displayedForecast = _isExpanded
        ? forecast
        : (forecast.length > 4 ? forecast.take(4).toList() : forecast);
    final forecastDays = forecast.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isExpanded ? '$forecastDays-Day Forecast' : '4-Day Forecast',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
            double minWidth = 140.0;
            if (cardWidth < minWidth) {
              cardWidth = (constraints.maxWidth - (1 * 16)) / 2;
            }

            return Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: displayedForecast
                  .map((weather) =>
                  ForecastCard(width: cardWidth, weather: weather))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        if (forecast.length > 4)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              child: Text(
                _isExpanded ? 'Show less' : 'Show more',
                style:
                TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ),
      ],
    );
  }
}
