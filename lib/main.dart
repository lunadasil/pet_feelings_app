import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const WeatherApp());

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Info',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
      ),
      home: const _TabsNonScrollableDemo(),
    );
  }
}

class _TabsNonScrollableDemo extends StatefulWidget {
  const _TabsNonScrollableDemo();
  @override
  State<_TabsNonScrollableDemo> createState() => _TabsNonScrollableDemoState();
}

class _TabsNonScrollableDemoState extends State<_TabsNonScrollableDemo> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final tabs = const ['Current', '7-Day', 'Settings', 'About'];

  final TextEditingController _cityCtrl = TextEditingController();
  String? city;
  String? condition;
  int? tempC;
  List<_DayForecast> forecast = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Random _rngFor(String seed) => Random(seed.hashCode);

  String _randCondition(Random r) => ['Sunny', 'Cloudy', 'Rainy', 'Windy', 'Stormy'][r.nextInt(5)];

  void _fetchCurrent() {
    final c = _cityCtrl.text.trim();
    if (c.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a city name first.')));
      return;
    }
    final r = _rngFor(c + DateTime.now().day.toString());
    setState(() {
      city = c;
      tempC = 15 + r.nextInt(16); // 15..30
      condition = _randCondition(r);
    });
  }

  void _fetch7Day() {
    final c = _cityCtrl.text.trim();
    if (c.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a city name first.')));
      return;
    }
    final r = _rngFor(c); // stable for the city
    final today = DateTime.now();
    final list = <_DayForecast>[];
    for (int i = 0; i < 7; i++) {
      final d = today.add(Duration(days: i));
      final t = 15 + r.nextInt(16);
      final cond = _randCondition(r);
      list.add(_DayForecast(date: d, tempC: t, condition: cond));
    }
    setState(() {
      city = c;
      forecast = list;
    });
    _tabController.animateTo(1); // jump to 7-Day tab
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Info'),
        bottom: TabBar(controller: _tabController, tabs: [for (final t in tabs) Tab(text: t)]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Current
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'e.g., Atlanta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(onPressed: _fetchCurrent, child: const Text('Fetch Current')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(onPressed: _fetch7Day, child: const Text('Fetch 7-Day')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (city != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(city!, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Temperature: ${tempC ?? '--'} °C'),
                      Text('Condition: ${condition ?? '--'}'),
                    ]),
                  ),
                ),
              ],
            ],
          ),

          // Tab 2: 7-Day
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.05),
            child: (forecast.isEmpty)
                ? const Center(child: Text('No forecast yet. Use "Fetch 7-Day".'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: forecast.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final f = forecast[i];
                      final weekday = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][f.date.weekday % 7];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${f.tempC}°')),
                          title: Text('$weekday • ${f.date.month}/${f.date.day}'),
                          subtitle: Text(f.condition),
                        ),
                      );
                    },
                  ),
          ),

          // Tab 3: Settings
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Use Dark Mode'),
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (_) {
                  final platformDark = Theme.of(context).brightness == Brightness.dark;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Switch theme from the OS/IDE. Currently: ${platformDark ? 'Dark' : 'Light'}')),
                  );
                },
                secondary: const Icon(Icons.dark_mode),
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Note'),
                subtitle: Text('This simple app simulates data for class activity.'),
              ),
            ],
          ),

          // Tab 4: About
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '7-Day Weather App\nBuilt for GitHub Collaboration Activity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomAppBar(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Commit at each checkpoint • See README/notes'),
        ),
      ),
    );
  }
}

class _DayForecast {
  final DateTime date;
  final int tempC;
  final String condition;
  _DayForecast({required this.date, required this.tempC, required this.condition});
} //Commit Checkpoint: Basic UI with input field and button 
// Commit checkpoint: Simulated weather data for input city
// Commit checkpoint: Displayed simulated weather information