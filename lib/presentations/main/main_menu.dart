import 'package:flutter/material.dart';
import 'package:g_weather_forecast/presentations/weather/weather_page.dart';
import '../subscription/subscription_page.dart';

class MainMenu extends StatefulWidget {
  final int initialIndex;
  const MainMenu({super.key, this.initialIndex = 0});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  late int index;

  final List<Widget> _widgetList = [
    WeatherPage.newInstance(),
    SubscriptionPage.newInstance(),
  ];

  final List<String> _titles = [
    'Weather Dashboard',
    'Subscription',
  ];

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(flex: 1),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      _titles[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.wb_sunny_rounded,
                          color: index == 0 ? Colors.yellow : Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            index = 0;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.email_rounded,
                          color: index == 1 ? Colors.yellow : Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            index = 1;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _widgetList[index],
          ),
        ],
      ),
    );
  }
}
