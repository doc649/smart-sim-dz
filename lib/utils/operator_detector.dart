import 'package:flutter/material.dart';

enum Operator {
  mobilis,
  djezzy,
  ooredoo,
  unknown
}

// Fonction pour détecter l'opérateur basé sur le préfixe
Operator detectOperator(String phoneNumber) {
  // Nettoyer le numéro (supprimer espaces, +, etc.)
  String cleanedNumber = phoneNumber.replaceAll(RegExp(r'\s+|-|\(|\)|\+'), '');

  // Gérer les numéros internationaux algériens
  if (cleanedNumber.startsWith("213")) {
    cleanedNumber = "0${cleanedNumber.substring(3)}";
  }

  // Vérifier les préfixes officiels (source ARPCE)
  // Mobilis: 06xx
  // Djezzy: 07xx
  // Ooredoo: 05xx
  if (cleanedNumber.startsWith("06")) {
    return Operator.mobilis;
  } else if (cleanedNumber.startsWith("07")) {
    return Operator.djezzy;
  } else if (cleanedNumber.startsWith("05")) {
    return Operator.ooredoo;
  } else {
    return Operator.unknown;
  }
}

// Fonction pour obtenir la couleur associée à l'opérateur (peut être affinée)
Color getOperatorColor(Operator operator) {
  switch (operator) {
    case Operator.mobilis:
      return Colors.blue.shade700;
    case Operator.djezzy:
      return Colors.red.shade700;
    case Operator.ooredoo:
      // Utiliser une couleur orange/rouge plus proche du logo Ooredoo
      return const Color(0xFFE60012); // Rouge Ooredoo
    case Operator.unknown:
    default:
      return Colors.grey.shade600;
  }
}

// Fonction pour obtenir le nom de l'opérateur
String getOperatorName(Operator operator) {
  switch (operator) {
    case Operator.mobilis:
      return "Mobilis";
    case Operator.djezzy:
      return "Djezzy";
    case Operator.ooredoo:
      return "Ooredoo";
    case Operator.unknown:
    default:
      return "Inconnu";
  }
}

// Fonction pour obtenir le chemin du logo de l'opérateur
String getOperatorLogoPath(Operator operator) {
  switch (operator) {
    case Operator.mobilis:
      return "assets/logos/mobilis_logo.png";
    case Operator.djezzy:
      return "assets/logos/djezzy_logo.png";
    case Operator.ooredoo:
      return "assets/logos/ooredoo_logo.png";
    case Operator.unknown:
    default:
      // Retourner un chemin vide ou un logo placeholder si nécessaire
      return ""; // Ou "assets/logos/unknown_logo.png"
  }
}

