# Smart SIM DZ - Refonte Moderne

## Présentation

Ce projet est une refonte moderne de l'application "Smart SIM DZ". L'objectif était de moderniser l'interface utilisateur en adoptant les dernières tendances UI/UX (Material 3, Bento Grid), d'améliorer la base de code, et d'intégrer les fonctionnalités clés discutées, tout en assurant la compatibilité avec les versions récentes d'Android (notamment Android 14).

## Modifications et Améliorations

*   **Interface Utilisateur Moderne :**
    *   Adoption de Material 3 pour les composants et le thème.
    *   Thème dynamique (Material You) s'adaptant au fond d'écran de l'utilisateur (sur Android 12+).
    *   Thèmes clair et sombre améliorés.
    *   Écran d'accueil réorganisé en "Bento Grid" pour une meilleure lisibilité et un accès rapide aux informations clés (Statut SIM, Compteur d'appels optimisés, Recherche rapide).
    *   Écran de contacts dédié avec barre de recherche intégrée.
    *   Écran de paramètres revu avec configuration des SIM et liste des codes USSD organisée par opérateur.
*   **Base de Code :**
    *   Mise à jour des dépendances (Flutter, Gradle, AGP, plugins).
    *   Remplacement du plugin obsolète `contacts_service` par `flutter_contacts`.
    *   Refactoring du code pour utiliser la nouvelle API de `flutter_contacts`.
    *   Correction de nombreux bugs de compilation et d'exécution liés aux incompatibilités de versions et aux API dépréciées.
    *   Optimisation du code selon les recommandations de l'analyseur Flutter (utilisation de `const`, suppression des `print`, etc.).
*   **Fonctionnalités :**
    *   Affichage des logos des opérateurs (Mobilis, Djezzy, Ooredoo) à côté du nom.
    *   Détection de l'opérateur basée sur les préfixes officiels.
    *   Configuration manuelle des opérateurs pour chaque SIM dans les paramètres.
    *   Affichage d'un compteur d'appels optimisés (incrémenté lors d'un appel via le bouton SIM recommandé).
    *   Bouton d'appel intelligent sur la liste des contacts, suggérant la SIM à utiliser en fonction de l'opérateur du contact et des SIM configurées.
    *   Accès rapide aux codes USSD courants (solde, rechargement) depuis l'écran des paramètres, organisés par opérateur.
    *   Fonctionnalité de partage de l'application.
    *   Gestion des permissions de contacts améliorée.
    *   Intégration d'une bannière publicitaire AdMob (désactivée si l'utilisateur devient premium - fonctionnalité premium non implémentée).

## Instructions

### Prérequis

*   Flutter SDK installé (version utilisée lors du développement : stable 3.x.x - à vérifier avec `flutter --version`)
*   Android SDK configuré
*   Un appareil ou émulateur Android (Android 14 recommandé pour tester toutes les fonctionnalités)

### Compilation et Installation

1.  **Cloner le dépôt :**
    ```bash
    git clone https://github.com/doc649/smart-sim-dz.git
    cd smart-sim-dz
    ```
2.  **Récupérer les dépendances :**
    ```bash
    flutter pub get
    ```
3.  **Compiler l'APK (debug) :**
    ```bash
    flutter build apk --debug
    ```
    L'APK se trouvera dans `build/app/outputs/flutter-apk/app-debug.apk`.
4.  **Installer l'APK :** Transférez le fichier `app-debug.apk` sur votre appareil Android et installez-le (assurez-vous d'avoir autorisé l'installation depuis des sources inconnues).

### Utilisation

1.  **Premier Lancement :** L'application demandera l'autorisation d'accéder à vos contacts. Accordez-la pour que l'application puisse fonctionner.
2.  **Configuration Initiale :** Allez dans l'écran "Paramètres" (icône roue dentée en haut à droite) et sélectionnez les opérateurs correspondants à vos cartes SIM 1 et SIM 2. C'est essentiel pour la fonctionnalité d'appel intelligent.
3.  **Écran d'Accueil :**
    *   Visualisez le statut de vos SIM configurées.
    *   Voyez le nombre d'appels optimisés effectués.
    *   Appuyez sur la barre de recherche pour accéder à la liste complète des contacts.
4.  **Écran Contacts :**
    *   Recherchez des contacts par nom ou numéro.
    *   Pour chaque contact, l'opérateur détecté (basé sur le préfixe) est affiché.
    *   Si l'opérateur du contact correspond à l'une de vos SIM configurées, un bouton "SIM X" (avec la couleur de l'opérateur) apparaît. Appuyez dessus pour lancer l'appel via la SIM recommandée (cela incrémente le compteur d'appels optimisés).
    *   Si l'opérateur est inconnu ou ne correspond à aucune de vos SIM, une icône d'appel standard apparaît.
5.  **Écran Paramètres :**
    *   Modifiez la configuration de vos opérateurs SIM à tout moment.
    *   Accédez aux codes USSD utiles pour chaque opérateur en dépliant la section correspondante.
    *   Appuyez sur un code USSD pour le lancer.

## Prochaines Étapes Possibles

*   Implémenter la fonctionnalité Premium (suppression des pubs, fonctionnalités avancées).
*   Améliorer la détection de l'opérateur (prise en compte de la portabilité via API externe si possible).
*   Ajouter des contacts favoris sur l'écran d'accueil.
*   Permettre la saisie du code pour les USSD de rechargement.
*   Affiner l'interface utilisateur et ajouter des animations.


