// lib/widgets/city_search_card.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:g_weather_forecast/objects/location.dart';

class CitySearchCard extends StatelessWidget {
  final FutureOr<Iterable<Location>?> Function(String) suggestionsCallback;
  final Function(Location) onCitySelected;
  final TextEditingController typeAheadController;

  const CitySearchCard({
    super.key,
    required this.suggestionsCallback,
    required this.onCitySelected,
    required this.typeAheadController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter a City Name',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TypeAheadField<Location>(
              controller: typeAheadController,
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'e.g., New York, London, Tokyo',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(color: Colors.black),
                );
              },
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty) {
                  return [
                    Location(
                        id: 2717933,
                        name: "Ha Noi",
                        region: "",
                        country: "Vietnam"),
                    Location(
                        id: 2718413,
                        name: "Ho Chi Minh City",
                        region: "",
                        country: "Vietnam"),
                  ];
                }
                try {
                  final suggestions = await suggestionsCallback(pattern);
                  return suggestions?.toList();
                } catch (e) {
                  return [];
                }
              },
              itemBuilder: (context, Location suggestion) {
                String subtitleText = suggestion.region != null && suggestion.region!.isNotEmpty
                    ? '${suggestion.region!}, ${suggestion.country!}'
                    : suggestion.country ?? '';
                return ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(suggestion.name ?? ''),
                  subtitle: Text(subtitleText),
                );
              },
              onSelected: (Location suggestion) {
                final newText = suggestion.name ?? '';
                typeAheadController.text = newText;
                typeAheadController.selection = TextSelection.fromPosition(
                  TextPosition(offset: newText.length),
                );
                onCitySelected(suggestion);
              },
            ),
          ],
        ),
      ),
    );
  }
}
