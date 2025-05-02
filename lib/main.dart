import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Importer AdMob
import 'package:smart_sim_dz/screens/home_screen.dart';

// Couleurs de base pour le thème (si dynamic color n'est pas dispo)
const _brandColor = Colors.teal;

void main() {
  // Assurer l'initialisation des Widgets Flutter
  WidgetsFlutterBinding.ensureInitialized();
  // Initialiser le SDK Mobile Ads
  MobileAds.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser DynamicColorBuilder pour le thème Material You
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Utiliser les couleurs dynamiques si disponibles
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Utiliser les couleurs de base sinon
          lightColorScheme = ColorScheme.fromSeed(seedColor: _brandColor);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: _brandColor,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Smart SIM DZ',
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
            // Personnaliser d'autres aspects du thème clair si nécessaire
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
            // Personnaliser d'autres aspects du thème sombre si nécessaire
          ),
          themeMode: ThemeMode.system, // Suit le thème du système
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false, // Masquer la bannière de débogage
        );
      },
    );
  }
}
