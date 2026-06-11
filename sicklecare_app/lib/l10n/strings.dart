import 'package:flutter/widgets.dart';

/// Lightweight bilingual (FR/EN) string table.
///
/// Access via `context.l10n` then a getter, e.g. `context.l10n.signIn`.
class L10n {
  final bool fr;
  const L10n(this.fr);

  static const supportedLocales = [Locale('en'), Locale('fr')];

  String tr(String en, String frv) => fr ? frv : en;

  // ---- Generic ----
  String get appTagline =>
      tr('Care • Awareness • Community', 'Soin • Sensibilisation • Communauté');
  String get disclaimer => tr(
      'Sika gives general information only — not a medical diagnosis. Always consult a health professional; in an emergency, go to the nearest hospital.',
      "Sika donne des informations générales, pas un diagnostic médical. Consulte toujours un professionnel de santé ; en cas d'urgence, va à l'hôpital le plus proche.");
  String get save => tr('Save', 'Enregistrer');
  String get cancel => tr('Cancel', 'Annuler');
  String get delete => tr('Delete', 'Supprimer');
  String get required => tr('Required', 'Requis');
  String get retry => tr('Retry', 'Réessayer');
  String get email => tr('Email', 'E-mail');
  String get password => tr('Password', 'Mot de passe');
  String get fullName => tr('Full name', 'Nom complet');
  String get validEmail => tr('Enter a valid email', 'Entre un e-mail valide');
  String get min6 => tr('Min 6 characters', '6 caractères minimum');
  String get signOut => tr('Sign out', 'Se déconnecter');

  // ---- Bottom navigation ----
  String get navHome => tr('Home', 'Accueil');
  String get navTracking => tr('Tracking', 'Suivi');
  String get navCheckin => tr('Check-in', 'Check-in');
  String get navReminders => tr('Reminders', 'Rappels');
  String get navAssistant => tr('Assistant', 'Assistant');

  // ---- Dashboard ----
  String hello(String name) => tr('Hello, $name', 'Bonjour, $name');
  String get helloNoName => tr('Hello', 'Bonjour');
  String get hydration => tr('Hydration', 'Hydratation');
  String get pain => tr('Pain', 'Douleur');
  String get lastReading => tr('Last reading', 'Dernier relevé');
  String get notLoggedYet => tr('Not logged yet', 'Pas encore noté');
  String get nextReminder => tr('Next reminder', 'Prochain rappel');
  String get noActiveReminder => tr('No active reminder', 'Aucun rappel actif');
  String get dailyCheckin => tr('Daily check-in', 'Check-in du jour');
  String get dailyCheckinSub => tr('Log your pain, hydration and mood',
      'Note ta douleur, ton hydratation et ton humeur');
  String get quickActions => tr('Quick actions', 'Actions rapides');
  String get aiAssistant => tr('Ask Sika', 'Demander à Sika');
  String get explore => tr('Explore', 'Explorer');
  String get hydrationDiet => tr('Hydration & diet', 'Hydratation & régime');
  String get nutritionTips => tr('Menus & tips', 'Menus & conseils');
  String get weatherCare => tr('Weather & care', 'Météo & soins');
  String get weatherTipsSub =>
      tr('Tips for the weather', 'Conseils selon le temps');
  String get supportEmergency => tr('Support & emergency', 'Soutien & urgence');
  String get contactEmergencySub =>
      tr('Contact & emergency call', "Contact & appel d'urgence");

  String formatDayDate(DateTime d) {
    const enWd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const frWd = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
    const enMo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const frMo = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    final wd = (fr ? frWd : enWd)[d.weekday - 1];
    final mo = (fr ? frMo : enMo)[d.month - 1];
    return '$wd ${d.day} $mo';
  }

  String dayName(int weekday) {
    const en = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const frd = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return (fr ? frd : en)[weekday - 1];
  }

  // ---- Login / Signup ----
  String get welcomeBack => tr('Welcome back', 'Bon retour');
  String get signInSubtitle => tr('Sign in to your SickleCare account',
      'Connecte-toi à ton compte SickleCare');
  String get forgotPassword =>
      tr('Forgot password?', 'Mot de passe oublié ?');
  String get signIn => tr('Sign in', 'Se connecter');
  String get noAccount => tr("Don't have an account?", 'Pas de compte ?');
  String get signUp => tr('Sign up', "S'inscrire");
  String get enterEmailReset => tr('Enter your email to reset password',
      'Entre ton e-mail pour réinitialiser le mot de passe');
  String get resetEmailSent => tr('Password reset email sent',
      'E-mail de réinitialisation envoyé');
  String get loginFailed => tr('Login failed', 'Échec de la connexion');
  String get createAccount => tr('Create account', 'Créer un compte');
  String get joinSickleCare => tr('Join SickleCare', 'Rejoins SickleCare');
  String get genotypeHint =>
      tr('Genotype (e.g. AA, AS, SS)', 'Génotype (ex. AA, AS, SS)');
  String get acceptTerms => tr('I accept the Terms & Conditions',
      "J'accepte les conditions d'utilisation");
  String get mustAcceptTerms => tr('Please accept the terms to continue',
      'Veuillez accepter les conditions pour continuer');

  // ---- Tracker ----
  String get trackerTitle => tr('Check-in', 'Check-in');
  String get painLevel => tr('Pain level', 'Niveau de douleur');
  String level(int n) => tr('Level: $n / 10', 'Niveau : $n / 10');
  String get water => tr('Water (ml)', 'Eau (ml)');
  String get mood => tr('Mood', 'Humeur');
  String get notes => tr('Notes', 'Notes');
  String get saveEntry => tr('Save entry', "Enregistrer l'entrée");
  String get savedEntry =>
      tr("Saved today's entry", 'Entrée du jour enregistrée');

  // ---- Reminders ----
  String get remindersTitle => tr('Reminders', 'Rappels');
  String get newLabel => tr('New', 'Nouveau');
  String get newReminder => tr('New reminder', 'Nouveau rappel');
  String get title => tr('Title', 'Titre');
  String get note => tr('Note', 'Note');
  String timeLabel(String t) => tr('Time: $t', 'Heure : $t');
  String get pick => tr('Pick', 'Choisir');
  String get repeatDaily => tr('Repeat daily', 'Répéter chaque jour');
  String get addReminder => tr('Add reminder', 'Ajouter le rappel');
  String get noReminders => tr('No reminders yet', 'Aucun rappel');
  String get noRemindersSub => tr(
      'Set medication, hydration and clinic reminders.',
      'Programme tes rappels médicaments, hydratation et rendez-vous.');
  String get daily => tr('daily', 'chaque jour');

  // ---- History / Suivi ----
  String get historyTitle => tr('Tracking', 'Suivi');
  String get noEntries => tr('No entries yet', 'Aucune entrée');
  String get noEntriesSub => tr('Log a daily entry to start seeing trends.',
      'Enregistre une entrée pour voir tes tendances.');
  String painMl(int p, int ml) =>
      tr('Pain $p/10 · $ml ml', 'Douleur $p/10 · $ml ml');
  String get trends => tr('Trends', 'Tendances');
  String get legendPain => tr('Pain (/10)', 'Douleur (/10)');
  String get legendWater => tr('Water (ml)', 'Eau (ml)');

  // ---- Hydration & nutrition ----
  String get hydrationNutritionTitle =>
      tr('Hydration & Nutrition', 'Hydratation & Nutrition');
  String get weekMenu => tr("This week's menu", 'Menu de la semaine');
  String weekOf(String date) => tr('Week of $date', 'Semaine du $date');
  String get breakfast => tr('Breakfast', 'Petit-déjeuner');
  String get lunch => tr('Lunch', 'Déjeuner');
  String get dinner => tr('Dinner', 'Dîner');
  String get snack => tr('Snack', 'Collation');
  String get editMenu => tr('Edit', 'Modifier');
  String get menuSaved => tr('Menu updated', 'Menu mis à jour');
  String get resetWeekMenu =>
      tr('Reset this week', 'Réinitialiser la semaine');
  String get menuReset => tr('Menu reset', 'Menu réinitialisé');
  String get editDayMenu => tr('Edit the day', 'Modifier la journée');
  String get hydrationGoals =>
      tr('💧 Hydration goals', "💧 Objectifs d'hydratation");
  List<String> get hydrationGoalsItems => fr
      ? const [
          '• Adultes : 2,5 à 3 L d\'eau par jour.',
          '• Évite l\'alcool et les boissons très froides.',
          '• Bois plus quand il fait chaud et à l\'effort.',
          '• Garde une bouteille d\'eau sur toi.',
        ]
      : const [
          '• Adults: 2.5–3 L of water daily.',
          '• Avoid alcohol and very cold drinks.',
          '• Drink more on hot days and during exercise.',
          '• Carry a water bottle everywhere.',
        ];
  String get foodsHelp => tr('🥗 Foods that help', '🥗 Aliments qui aident');
  List<String> get foodsHelpItems => fr
      ? const [
          '• Légumes verts : ndolé, eru, épinards',
          '• Haricots, lentilles, arachides',
          '• Plantain, manioc, patate, céréales complètes',
          '• Agrumes et fruits (orange, mangue, goyave, papaye)',
          '• Poisson et protéines maigres',
        ]
      : const [
          '• Leafy greens: ndolé, eru, spinach',
          '• Beans, lentils, groundnuts',
          '• Plantain, cassava, sweet potato, whole grains',
          '• Citrus and fruit (orange, mango, guava, papaya)',
          '• Fish and lean protein',
        ];
  String get avoid => tr('⚠️ Try to avoid', '⚠️ À éviter');
  List<String> get avoidItems => fr
      ? const [
          '• Excès d\'alcool',
          '• Tabac',
          '• Froid extrême / harmattan',
          '• Déshydratation et haute altitude',
        ]
      : const [
          '• Excess alcohol',
          '• Smoking',
          '• Extreme cold / harmattan',
          '• Dehydration & high altitude',
        ];

  // ---- Support ----
  String get supportTitle => tr('Support', 'Soutien');
  String get emergency => tr('Emergency', 'Urgence');
  String get emergencyText => tr(
      'If you have severe pain, chest pain, breathing trouble or fever — get medical help now.',
      'En cas de douleur intense, douleur à la poitrine, difficulté à respirer ou fièvre — consulte immédiatement.');
  String get callEmergency =>
      tr('Call emergency (112)', 'Appeler les urgences (112)');
  String get contactTeam => tr('Contact the SickleCare team',
      "Contacter l'équipe SickleCare");
  String get name => tr('Name', 'Nom');
  String get subject => tr('Subject', 'Sujet');
  String get message => tr('Message', 'Message');
  String get sendMessage => tr('Send message', 'Envoyer le message');
  String get messageSent => tr("Message sent. We'll be in touch soon.",
      'Message envoyé. Nous reviendrons vers toi bientôt.');
  String failed(String e) => tr('Failed: $e', 'Échec : $e');

  // ---- Profile ----
  String get profileTitle => tr('Profile', 'Profil');
  String get genotype => tr('Genotype', 'Génotype');
  String get phone => tr('Phone', 'Téléphone');
  String get saveChanges => tr('Save changes', 'Enregistrer');
  String get profileUpdated => tr('Profile updated', 'Profil mis à jour');

  // ---- Settings ----
  String get settingsTitle => tr('Settings', 'Réglages');
  String get myProfile => tr('My profile', 'Mon profil');
  String get tapToEdit =>
      tr('Tap to edit your details', 'Touche pour modifier tes infos');
  String get theme => tr('Theme', 'Thème');
  String get system => tr('System', 'Système');
  String get light => tr('Light', 'Clair');
  String get dark => tr('Dark', 'Sombre');
  String get language => tr('Language', 'Langue');
  String get appVersion => tr('App version', "Version de l'app");
  String get website => tr('Visit our website', 'Visiter le site web');
  String get deleteAccount => tr('Delete account', 'Supprimer le compte');
  String get deleteAccountConfirm =>
      tr('Delete your account?', 'Supprimer ton compte ?');
  String get deleteAccountBody => tr(
      'This permanently deletes your account and data. This cannot be undone.',
      'Cela supprime définitivement ton compte et tes données. Action irréversible.');
  String get accountDeleted => tr('Account deleted', 'Compte supprimé');
  String get reauthNeeded => tr(
      'Please sign out and sign in again, then retry.',
      'Déconnecte-toi puis reconnecte-toi, et réessaie.');
  String themeName(String mode) {
    switch (mode) {
      case 'light':
        return light;
      case 'dark':
        return dark;
      default:
        return system;
    }
  }

  // ---- Admin ----
  String get adminTitle => tr('Admin', 'Admin');
  String get editHomeContent =>
      tr('Edit home content', "Modifier le contenu d'accueil");
  String get heroTitle => tr('Hero title', 'Titre principal');
  String get heroBody => tr('Hero body', 'Texte principal');
  String get contentUpdated => tr('Content updated', 'Contenu mis à jour');
  String get recentMessages =>
      tr('Recent contact messages', 'Messages récents');
  String get noMessages => tr('No messages yet.', 'Aucun message.');
  String get noSubject => tr('(no subject)', '(sans sujet)');

  // ---- Sika (AI assistant) ----
  String get assistantTitle => 'Sika';
  String get askAnything => tr('Ask Sika anything…', 'Pose ta question à Sika…');
  String get aiIntro => tr(
      "Hi, I'm Sika, your SickleCare assistant. Ask me about hydration, pain, nutrition, reminders — anything about daily sickle-cell care.",
      "Bonjour, je suis Sika, ton assistant SickleCare. Pose-moi tes questions sur l'hydratation, la douleur, la nutrition, les rappels — tout sur les soins au quotidien.");
  String get clearChat => tr('Clear chat', 'Effacer le chat');
  String get clearHistory => tr('Clear history', "Effacer l'historique");
  String get about => tr('About', 'À propos');
  String get aboutSikaTitle => tr('About Sika', 'À propos de Sika');
  String get aboutSikaBody => tr(
      'Sika is your SickleCare assistant, tailored to the Cameroonian context. It offers general guidance on hydration, nutrition, pain and daily care. Sika is NOT a doctor and does not replace professional medical advice — in an emergency, go to the nearest hospital.',
      "Sika est ton assistant SickleCare, adapté au contexte camerounais. Il donne des conseils généraux sur l'hydratation, la nutrition, la douleur et les soins quotidiens. Sika n'est PAS un médecin et ne remplace pas un avis médical professionnel — en cas d'urgence, va à l'hôpital le plus proche.");
  String get chatCleared => tr('Chat cleared', 'Chat effacé');
  String get historyCleared => tr('History cleared', 'Historique effacé');
  List<String> get aiSuggestions => fr
      ? const [
          'Pourquoi ai-je des crises de douleur ?',
          "Combien d'eau dois-je boire ?",
          'Meilleurs aliments pour la drépanocytose',
          'Conseils pour le froid / harmattan',
        ]
      : const [
          'Why do I get pain crises?',
          'How much water should I drink?',
          'Best foods for sickle cell',
          'Tips for cold / harmattan',
        ];

  // ---- Weather ----
  String get weatherTitle => tr('Weather & Care', 'Météo & soins');
  String get weatherError => tr(
      'Could not get the weather. Please turn on location and grant the permission, then retry.',
      "Impossible d'obtenir la météo. Active la localisation et autorise l'accès, puis réessaie.");
  String get humidity => tr('Humidity', 'Humidité');
  String get wind => tr('Wind', 'Vent');
  String get todaysTip => tr("Today's tip", 'Conseil du jour');
  String get openAppSettings =>
      tr('Open app settings', 'Ouvrir les réglages');
  String get adviceCold => tr(
      'Cold day — dress warmly in layers. Cold can trigger pain crises.',
      'Journée fraîche — couvre-toi en plusieurs couches. Le froid peut déclencher une crise.');
  String get adviceHot => tr(
      'Hot day — drink extra water and stay in the shade.',
      "Forte chaleur — bois plus d'eau et reste à l'ombre.");
  String get adviceDry => tr(
      'Low humidity — keep hydrating throughout the day.',
      "Air sec — hydrate-toi tout au long de la journée.");
  String get adviceNormal => tr(
      'Pleasant conditions — keep your normal hydration routine.',
      "Conditions agréables — garde ta routine d'hydratation habituelle.");
  String weatherSummary(String en) {
    if (!fr) return en;
    switch (en) {
      case 'Clear sky':
        return 'Ciel dégagé';
      case 'Partly cloudy':
        return 'Partiellement nuageux';
      case 'Overcast':
        return 'Couvert';
      case 'Fog':
        return 'Brouillard';
      case 'Rain':
        return 'Pluie';
      case 'Snow':
        return 'Neige';
      case 'Showers':
        return 'Averses';
      case 'Thunderstorm':
        return 'Orage';
      default:
        return 'Météo';
    }
  }

  // ---- Voice / export / terms ----
  String get exportPdf => tr('Export to PDF', 'Exporter en PDF');
  String get listening => tr('Listening…', 'Écoute…');
  String get readAloud => tr('Read aloud', 'Lire à voix haute');
  String get acceptTermsPrefix => tr('I accept the ', "J'accepte les ");
  String get termsLink => tr('Terms & Conditions', "conditions d'utilisation");
}

extension L10nContext on BuildContext {
  L10n get l10n => L10n(Localizations.localeOf(this).languageCode == 'fr');
}
