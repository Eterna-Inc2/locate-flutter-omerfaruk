import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/device_provider.dart';
import 'screens/home_screen.dart';
import 'screens/device_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color softSurface = Color(0xFFF8F8F8); // updated
    const Color softOnSurface = Color(0xFF1F2937);

    final ColorScheme lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E5BFF),
      brightness: Brightness.light,
    ).copyWith(surface: softSurface, onSurface: softOnSurface);

    final ThemeData lightTheme = ThemeData(
      colorScheme: lightScheme,
      scaffoldBackgroundColor: softSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: lightScheme.surface,
        foregroundColor: lightScheme.onSurface,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightScheme.surface,
        indicatorColor: lightScheme.primary.withOpacity(0.10),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: selected
                ? lightScheme.primary
                : lightScheme.onSurface.withOpacity(0.7),
          );
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return TextStyle(
            color: selected
                ? lightScheme.primary
                : lightScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      useMaterial3: true,
    );

    return ChangeNotifierProvider(
      create: (context) => DeviceProvider(),
      child: MaterialApp(
        title: 'Locate',
        theme: lightTheme,
        themeMode: ThemeMode.light, // force light mode
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [const HomeScreen(), const DeviceListScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Harita',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Cihazlar',
          ),
        ],
      ),
    );
  }
}
