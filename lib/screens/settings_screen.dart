# Écran des paramètres pour configurer les SIM et afficher les codes USSD

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_sim_dz/utils/operator_detector.dart';
import 'package:url_launcher/url_launcher.dart'; // Pour lancer les codes USSD

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Operator _sim1Operator = Operator.unknown;
  Operator _sim2Operator = Operator.unknown;
  bool _isLoading = true;

  // Clés pour SharedPreferences
  static const String sim1PrefKey = 'sim1_operator';
  static const String sim2PrefKey = 'sim2_operator';

  // Map des codes USSD par opérateur
  final Map<Operator, List<Map<String, String>>> _ussdCodes = {
    Operator.djezzy: [
      {'name': 'Consulter solde', 'code': '*710#'},
      {'name': 'Recharger', 'code': '*720*CODE#'},
      // Ajouter d'autres codes Djezzy
    ],
    Operator.mobilis: [
      {'name': 'Consulter solde', 'code': '*222#'},
      {'name': 'Recharger', 'code': '*666*CODE#'},
      // Ajouter d'autres codes Mobilis
    ],
    Operator.ooredoo: [
      {'name': 'Consulter solde', 'code': '*200#'},
      {'name': 'Recharger', 'code': '*111*CODE#'},
      // Ajouter d'autres codes Ooredoo
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sim1Operator = Operator.values[prefs.getInt(sim1PrefKey) ?? Operator.unknown.index];
      _sim2Operator = Operator.values[prefs.getInt(sim2PrefKey) ?? Operator.unknown.index];
      _isLoading = false;
    });
  }

  Future<void> _saveOperatorPreference(int simSlot, Operator operator) async {
    final prefs = await SharedPreferences.getInstance();
    final key = simSlot == 1 ? sim1PrefKey : sim2PrefKey;
    await prefs.setInt(key, operator.index);
    if (mounted) {
      setState(() {
        if (simSlot == 1) {
          _sim1Operator = operator;
        } else {
          _sim2Operator = operator;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opérateur SIM $simSlot mis à jour.')),
      );
    }
  }

  Future<void> _launchUssdCode(String code) async {
    // Remplacer 'CODE' par une demande à l'utilisateur si nécessaire
    if (code.contains('CODE')) {
      // Pour l'instant, on informe juste qu'il faut remplacer le code
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplacer CODE par votre code de rechargement.')),
      );
      return; // Ou ouvrir un dialogue pour saisir le code
    }

    final Uri launchUri = Uri(scheme: 'tel', path: Uri.encodeComponent(code));
    try {
      if (!mounted) return;
      bool launched = await launchUrl(launchUri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de lancer le code USSD $code')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du lancement du code USSD: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              children: [
                _buildSimConfigurationSection(textTheme, colorScheme),
                const Divider(height: 32),
                _buildUssdSection(textTheme, colorScheme),
                // Ajouter d'autres sections si nécessaire (ex: A propos, Premium)
              ],
            ),
    );
  }

  Widget _buildSimConfigurationSection(TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration des Opérateurs SIM',
            style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 16),
          _buildOperatorDropdown(1, _sim1Operator, colorScheme),
          const SizedBox(height: 16),
          _buildOperatorDropdown(2, _sim2Operator, colorScheme),
        ],
      ),
    );
  }

  Widget _buildOperatorDropdown(int simSlot, Operator currentOperator, ColorScheme colorScheme) {
    return DropdownButtonFormField<Operator>(
      value: currentOperator,
      decoration: InputDecoration(
        labelText: 'Opérateur SIM $simSlot',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
      ),
      items: Operator.values.map((Operator operator) {
        final logoPath = getOperatorLogoPath(operator);
        final operatorName = getOperatorName(operator);
        return DropdownMenuItem<Operator>(
          value: operator,
          child: Row(
            children: [
              if (logoPath.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Image.asset(logoPath, height: 20, errorBuilder: (c, e, s) => const SizedBox.shrink()),
                )
              else if (operator != Operator.unknown)
                 CircleAvatar(backgroundColor: getOperatorColor(operator), radius: 10), // Pastille
              const SizedBox(width: 8),
              Text(operatorName),
            ],
          ),
        );
      }).toList(),
      onChanged: (Operator? newValue) {
        if (newValue != null) {
          _saveOperatorPreference(simSlot, newValue);
        }
      },
    );
  }

  Widget _buildUssdSection(TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Codes USSD Utiles',
            style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 16),
          // Utiliser ExpansionPanelList pour organiser par opérateur
          ExpansionPanelList(
            elevation: 1,
            expandedHeaderPadding: EdgeInsets.zero,
            children: _ussdCodes.entries.where((entry) => entry.key != Operator.unknown).map<ExpansionPanel>((entry) {
              final operator = entry.key;
              final codes = entry.value;
              final logoPath = getOperatorLogoPath(operator);
              final operatorName = getOperatorName(operator);

              return ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return ListTile(
                    leading: logoPath.isNotEmpty
                        ? Image.asset(logoPath, height: 24, errorBuilder: (c, e, s) => const SizedBox.shrink())
                        : CircleAvatar(backgroundColor: getOperatorColor(operator), radius: 12),
                    title: Text(operatorName, style: textTheme.titleMedium),
                  );
                },
                body: Column(
                  children: codes.map((codeMap) {
                    return ListTile(
                      title: Text(codeMap['name']!),
                      subtitle: Text(codeMap['code']!),
                      trailing: IconButton(
                        icon: const Icon(Icons.send_to_mobile),
                        tooltip: 'Lancer le code',
                        onPressed: () => _launchUssdCode(codeMap['code']!),
                      ),
                      onTap: () => _launchUssdCode(codeMap['code']!),
                    );
                  }).toList(),
                ),
                isExpanded: true, // Garder ouvert par défaut ou gérer l'état
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

