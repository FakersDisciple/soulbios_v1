import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/subscription_service.dart';
import 'theme.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline persistence (web compatible)
  try {
    await Hive.initFlutter();

    // Open Hive boxes for caching
    await Hive.openBox('memories');
    await Hive.openBox('patterns');
    await Hive.openBox('destinations');
    await Hive.openBox('user_preferences');
    await Hive.openBox('api_cache');
    await Hive.openBox('image_cache');
    await Hive.openBox('usage_tracking');

    debugPrint('✅ Hive initialized successfully');
  } catch (e) {
    debugPrint('❌ Hive initialization failed: $e');
  }

  // Initialize subscription service (skip on web for now)
  if (!kIsWeb) {
    try {
      await SubscriptionService.instance.initialize();
      debugPrint('✅ Subscription service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize subscription service: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: SoulBiosMainApp(),
    ),
  );
}

class SoulBiosMainApp extends StatelessWidget {
  const SoulBiosMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoulBios - Conscious Living',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark, // Force dark theme for SoulBios aesthetic
      home: const SoulBiosApp(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
