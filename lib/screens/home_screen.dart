# Refonte de HomeScreen avec Bento Grid et Material 3

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_sim_dz/models/contact_with_operator.dart';
import 'package:smart_sim_dz/utils/operator_detector.dart';
import 'package:smart_sim_dz/screens/settings_screen.dart';
import 'package:smart_sim_dz/screens/contacts_screen.dart'; // Écran séparé pour la liste complète
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _permissionDenied = false;
  Operator _sim1Operator = Operator.unknown;
  Operator _sim2Operator = Operator.unknown;
  int _smartCallCounter = 0;
  bool _isPremium = false;

  // AdMob Banner Ad
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  final String _adUnitId = "ca-app-pub-3940256099942544/6300978111"; // ID de test

  // Clés pour SharedPreferences
  static const String sim1PrefKey = 'sim1_operator';
  static const String sim2PrefKey = 'sim2_operator';
  static const String smartCallCounterKey = 'smart_call_counter';
  static const String premiumStatusKey = 'is_premium';

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadPreferences();
    await _requestContactsPermission(); // Vérifier les permissions au démarrage
    if (!_isPremium) {
      _loadBannerAd();
    }
    if (mounted) {
      setState(() {
        _isLoading = false; // Fin du chargement initial
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sim1Operator = Operator.values[prefs.getInt(sim1PrefKey) ?? Operator.unknown.index];
      _sim2Operator = Operator.values[prefs.getInt(sim2PrefKey) ?? Operator.unknown.index];
      _smartCallCounter = prefs.getInt(smartCallCounterKey) ?? 0;
      _isPremium = prefs.getBool(premiumStatusKey) ?? false;
    });
  }

  void _loadBannerAd() {
    if (_isPremium || !mounted) return;

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          print('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  Future<void> _requestContactsPermission() async {
    final status = await Permission.contacts.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() {
        _permissionDenied = true;
      });
    }
  }

  // Fonction pour partager l'application
  void _shareApp() {
    const String appLink = "https://play.google.com/store/apps/details?id=com.example.smart_sim_dz"; // Placeholder
    const String message = "Découvrez Smart SIM DZ, l'application qui vous aide à choisir la bonne SIM pour appeler en Algérie et économiser ! Téléchargez-la ici : $appLink";
    Share.share(message);
  }

  void _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    await _loadPreferences(); // Recharger les préférences après retour
    // Gérer la bannière AdMob en fonction du statut premium
    if (!_isPremium && !_isBannerAdLoaded) _loadBannerAd();
    if (_isPremium && _isBannerAdLoaded) {
      if (mounted) {
        setState(() {
          _isBannerAdLoaded = false;
          _bannerAd?.dispose();
          _bannerAd = null;
        });
      }
    }
  }

  void _navigateToContacts() {
     if (_permissionDenied) {
        // Afficher un dialogue ou un message indiquant que la permission est requise
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Permission Requise"),
            content: const Text("L'accès aux contacts est nécessaire pour utiliser cette fonctionnalité. Veuillez accorder la permission dans les paramètres de l'application."),
            actions: <Widget>[
              TextButton(
                child: const Text("Annuler"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text("Paramètres"),
                onPressed: () {
                  openAppSettings(); // Ouvre les paramètres de l'application
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
        return;
      }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart SIM DZ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager l\"application',
            onPressed: _shareApp,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuration',
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBentoGrid(colorScheme, textTheme),
      bottomNavigationBar: !_isPremium && _isBannerAdLoaded && _bannerAd != null
          ? SafeArea(
            child: Container(
                color: colorScheme.surfaceVariant, // Couleur de fond pour la bannière
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),)
          : null,
    );
  }

  Widget _buildBentoGrid(ColorScheme colorScheme, TextTheme textTheme) {
    // Utiliser GridView.count pour une grille simple, ou un layout plus complexe si besoin
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Bloc Recherche Rapide (prend toute la largeur)
          _buildSearchBlock(colorScheme, textTheme),
          const SizedBox(height: 16),
          // Grille pour les autres blocs
          GridView.count(
            crossAxisCount: 2, // 2 colonnes
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Désactiver le scroll interne
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildSimStatusBlock(colorScheme, textTheme),
              _buildSmartCallCounterBlock(colorScheme, textTheme),
              // Ajouter d'autres blocs ici si nécessaire (ex: Contacts Favoris, Actions Rapides)
            ],
          ),
        ],
      ),
    );
  }

  // --- Widgets pour les Blocs de la Bento Grid --- //

  Widget _buildSearchBlock(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
       // Utiliser le style Filled pour un look plus intégré
      elevation: 0,
      color: colorScheme.surfaceVariant,
      child: InkWell(
        onTap: _navigateToContacts, // Naviguer vers l'écran des contacts au clic
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(Icons.search, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                'Rechercher des contacts...', // Texte indicatif
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimStatusBlock(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statut SIM', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSecondaryContainer)),
            const Spacer(),
            _buildSimRow(1, _sim1Operator, colorScheme),
            const SizedBox(height: 8),
            _buildSimRow(2, _sim2Operator, colorScheme),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: Icon(Icons.settings, color: colorScheme.onSecondaryContainer.withOpacity(0.7)),
                tooltip: 'Configurer les SIM',
                onPressed: _navigateToSettings,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSimRow(int simSlot, Operator operator, ColorScheme colorScheme) {
    final logoPath = getOperatorLogoPath(operator);
    final operatorName = getOperatorName(operator);
    final operatorColor = getOperatorColor(operator);

    return Row(
      children: [
        Text('SIM $simSlot: ', style: TextStyle(color: colorScheme.onSecondaryContainer)),
        if (logoPath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Image.asset(logoPath, height: 16, errorBuilder: (c, e, s) => const SizedBox.shrink()),
          )
        else if (operator != Operator.unknown)
           CircleAvatar(backgroundColor: operatorColor, radius: 8), // Pastille de couleur si pas de logo
        Expanded(
          child: Text(
            operatorName,
            style: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSmartCallCounterBlock(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      color: colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Appels Optimisés', style: textTheme.titleMedium?.copyWith(color: colorScheme.onTertiaryContainer)),
            const SizedBox(height: 8),
            Text(
              '$_smartCallCounter',
              style: textTheme.headlineMedium?.copyWith(color: colorScheme.onTertiaryContainer, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

}

