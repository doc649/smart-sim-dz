# Écran affichant la liste complète des contacts avec recherche et appel optimisé

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_sim_dz/models/contact_with_operator.dart';
import 'package:smart_sim_dz/utils/operator_detector.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool _isLoading = true;
  bool _permissionDenied = false;
  List<ContactWithOperator> _processedContacts = [];
  List<ContactWithOperator> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();

  Operator _sim1Operator = Operator.unknown;
  Operator _sim2Operator = Operator.unknown;

  // Clés pour SharedPreferences
  static const String sim1PrefKey = 'sim1_operator';
  static const String sim2PrefKey = 'sim2_operator';
  static const String smartCallCounterKey = 'smart_call_counter';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterContacts);
    _initializeContacts();
  }

  Future<void> _initializeContacts() async {
    await _loadPreferences();
    await _checkPermissionAndLoadContacts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sim1Operator = Operator.values[prefs.getInt(sim1PrefKey) ?? Operator.unknown.index];
      _sim2Operator = Operator.values[prefs.getInt(sim2PrefKey) ?? Operator.unknown.index];
    });
  }

  Future<void> _checkPermissionAndLoadContacts() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _permissionDenied = false; });

    final status = await Permission.contacts.status;
    if (!mounted) return;

    if (status.isGranted) {
      await _loadAndProcessContacts();
    } else {
      // La permission devrait avoir été demandée sur l'écran d'accueil
      // Si on arrive ici sans permission, c'est un cas anormal ou l'utilisateur l'a révoquée
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAndProcessContacts() async {
    try {
      final List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: false);
      if (!mounted) return;

      List<ContactWithOperator> processed = [];
      for (var contact in contacts) {
        String? phoneNumber = contact.phones.isNotEmpty ? contact.phones.first.number : null;
        Operator operator = Operator.unknown;
        if (phoneNumber != null) {
          operator = detectOperator(phoneNumber);
        }
        processed.add(ContactWithOperator(
          contact: contact,
          operator: operator,
          primaryPhoneNumber: phoneNumber,
        ));
      }

      processed.sort((a, b) => (a.contact.displayName).toLowerCase().compareTo((b.contact.displayName).toLowerCase()));

      if (mounted) {
        setState(() {
          _processedContacts = processed;
          _filteredContacts = processed;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement/traitement des contacts: $e');
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des contacts.')),
        );
      }
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        _filteredContacts = _processedContacts.where((c) {
          final name = c.contact.displayName.toLowerCase();
          final phone = c.primaryPhoneNumber?.toLowerCase() ?? '';
          return name.contains(query) || phone.contains(query);
        }).toList();
      });
    }
  }

  int? _getRecommendedSimSlot(Operator contactOperator) {
    if (contactOperator == Operator.unknown) return null;
    if (_sim1Operator == contactOperator) return 1;
    if (_sim2Operator == contactOperator) return 2;
    return null;
  }

  Future<void> _incrementSmartCallCounter() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(smartCallCounterKey) ?? 0;
    currentCount++;
    await prefs.setInt(smartCallCounterKey, currentCount);
    // Pas besoin de setState ici car le compteur est affiché sur HomeScreen
  }

  Future<void> _makeCall(String? phoneNumber, int? recommendedSimSlot) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro de téléphone invalide.')),
        );
      }
      return;
    }

    if (recommendedSimSlot != null) {
      await _incrementSmartCallCounter();
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (!mounted) return;
      bool launched = await launchUrl(launchUri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de lancer l\"appel vers $phoneNumber')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du lancement de l\"appel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        // Intégrer la barre de recherche dans l'AppBar ou en dessous
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou numéro...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_permissionDenied) {
      return _buildPermissionDeniedWidget();
    } else if (_filteredContacts.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'Aucun contact à afficher.'
              : 'Aucun contact trouvé pour "${_searchController.text}"',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    } else {
      return ListView.builder(
        itemCount: _filteredContacts.length,
        itemBuilder: (context, index) {
          final item = _filteredContacts[index];
          final contactName = item.contact.displayName;
          final phoneNumber = item.primaryPhoneNumber ?? 'Numéro inconnu';
          final operator = item.operator;
          final recommendedSim = _getRecommendedSimSlot(operator);
          final logoPath = getOperatorLogoPath(operator);
          final operatorColor = getOperatorColor(operator);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: logoPath.isNotEmpty ? Colors.transparent : operatorColor,
              child: logoPath.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        logoPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackAvatar(operator, contactName),
                      ),
                    )
                  : _buildFallbackAvatar(operator, contactName),
            ),
            title: Text(contactName),
            subtitle: Text(phoneNumber),
            trailing: recommendedSim != null
                ? ElevatedButton.icon(
                    icon: const Icon(Icons.phone, size: 16),
                    label: Text('SIM $recommendedSim'),
                    onPressed: () => _makeCall(phoneNumber, recommendedSim),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: operatorColor,
                      foregroundColor: Colors.white, // Assurer la lisibilité
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.phone_forwarded),
                    tooltip: 'Appeler (Opérateur inconnu ou non configuré)',
                    onPressed: () => _makeCall(phoneNumber, null),
                    color: colorScheme.onSurfaceVariant, // Couleur discrète
                  ),
            onTap: () => _makeCall(phoneNumber, recommendedSim),
          );
        },
      );
    }
  }

  Widget _buildFallbackAvatar(Operator operator, String displayName) {
    String initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?';
    return Text(
      initials,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPermissionDeniedWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contact_page_outlined, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Accès aux contacts refusé',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Smart SIM DZ a besoin d\'accéder à vos contacts pour fonctionner. Veuillez accorder la permission dans les paramètres de votre appareil.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: openAppSettings,
              child: const Text('Ouvrir les Paramètres'),
            ),
          ],
        ),
      ),
    );
  }
}

