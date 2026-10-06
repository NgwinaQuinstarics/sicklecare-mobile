import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';

/// AI helper backed by Groq's OpenAI-compatible Chat Completions API.
///
/// Reads key from Hive (saved by user in-app) or falls back to `.env`.
/// The assistant is tuned for the CAMEROONIAN context. If no key is configured
/// or the request fails, it returns a smart, interactive local conversational
/// fallback so the chat screen always stays fully usable.
class AIService {
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// Groq production model. Change here if Groq rotates model ids.
  static const _model = 'llama-3.3-70b-versatile';

  static const _system =
      'You are Sika, the SickleCare assistant — a warm and practical health '
      'assistant for people living with sickle cell disease and their '
      'caregivers in CAMEROON. '
      'Always ground your advice in the Cameroonian reality:\n'
      '- Local, affordable foods: ndole, eru/okok, bitterleaf, okra (gombo), '
      'beans (haricots), groundnuts (arachides), plantain, cassava (manioc), '
      'sweet potato, moringa, dark leafy greens, oranges, mango, guava, papaya, '
      'watermelon, pineapple, and baobab juice (bouye).\n'
      '- Hydration needs in a hot, tropical and dusty harmattan climate.\n'
      '- The local health system: health centres, district and regional '
      'hospitals, and CHU.\n'
      '- Malaria and infections are common crisis triggers locally: encourage '
      'mosquito nets, prompt treatment of fever, vaccination, folic acid and '
      'good hydration.\n'
      'Be concise (short paragraphs or bullet points). ALWAYS reply in the same '
      'language the user writes in (French or English). Never give a diagnosis. '
      'Do not prescribe medicine, choose dosages, change treatment, or tell a '
      'patient to stop/start medication. For those requests, explain that only '
      'their clinician can decide and suggest sharing their SickleCare report. '
      'For severe pain, chest pain, difficulty breathing, high fever, or signs '
      'of stroke, tell them to go to the nearest hospital immediately or call '
      'local emergency services.';

  static Future<String> ask(
    String prompt, {
    List<Map<String, String>>? history,
    String? healthContext,
  }) async {
    if (_hasEmergencySymptoms(prompt)) {
      return _emergencyReply(prompt);
    }
    if (_isUnsafeMedicationRequest(prompt)) {
      return _medicalBoundaryReply(prompt);
    }

    String? key;
    try {
      final box = Hive.box('app_cache');
      key = box.get('user_groq_api_key') ?? box.get('user_openai_api_key');
    } catch (_) {}

    if (key == null || key.isEmpty) {
      key =
          dotenv.maybeGet('GROQ_API_KEY') ?? dotenv.maybeGet('OPENAI_API_KEY');
    }

    if (key == null || key.isEmpty) {
      return _fallback(prompt, healthContext: healthContext);
    }

    try {
      final system = healthContext == null || healthContext.trim().isEmpty
          ? _system
          : '$_system\n\nUse this private user health context to personalize '
              'your answer. Do not expose private fields unless the user asks. '
              'Health context:\n$healthContext';
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': system},
                ...?history,
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.5,
              'max_tokens': 700,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final content = data['choices']?[0]?['message']?['content'];
        if (content is String && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
      return _fallback(prompt, healthContext: healthContext);
    } catch (_) {
      return _fallback(prompt, healthContext: healthContext);
    }
  }

  static Future<String> dailyAdvice(String healthContext) {
    return ask(
      'Give one short daily reminder or health advice for today. Use the user '
      'health context, focus on hydration, pain, fever risk, reminders, or '
      'nutrition. Keep it under 70 words.',
      healthContext: healthContext,
    );
  }

  /// Cameroon-flavoured offline fallback — purely keyword-based on the user's
  /// message. Never checks healthContext here (that was causing the same-answer
  /// bug since "today hydration: 0 ml" matched on every single unmatched query).
  static String _fallback(String prompt, {String? healthContext}) {
    final p = prompt.toLowerCase().trim();

    // --- Language detection ---
    final isFr = RegExp(
      r'(bonjour|salut|merci|aide|crise|douleur|eau|boire|manger|nourri|'
      r'aliment|palu|fievre|fièvre|froid|temps|rappels|drépano|drepano|'
      r'comment|quoi|pourquoi|oui|non|bien|jour|soir|matin|ça|est-ce|'
      r'medicament|médicament|sang|hôpital|hopital|docteur|conseil|santé)',
    ).hasMatch(p);

    // --- 0. Emergency / Mental Health ---
    if (RegExp(
            r'(die|suicide|kill|end my life|mort|mourir|tuer|suicider|désespoir|desespoir)')
        .hasMatch(p)) {
      return isFr
          ? '🚨 URGENCE :\nSika est un assistant virtuel et ne peut pas gérer les urgences médicales ou psychologiques.\n\nS\'il vous plaît, parlez-en immédiatement à un proche, rendez-vous aux urgences de l\'hôpital le plus proche, ou contactez un professionnel de santé. Vous n\'êtes pas seul(e).'
          : '🚨 EMERGENCY:\nSika is a virtual assistant and cannot handle medical or psychological emergencies.\n\nPlease speak to a loved one immediately, go to the nearest hospital emergency room, or contact a healthcare professional. You are not alone.';
    }

    // --- 1. Greetings ---
    if (RegExp(r'\b(hello|hi|hey|yo|good morning|good evening|good afternoon)\b')
            .hasMatch(p) ||
        RegExp(r'\b(bonjour|salut|coucou|bonsoir)\b').hasMatch(p)) {
      return isFr
          ? 'Bonjour ! 👋 Je suis Sika, votre assistante SickleCare. Comment vous sentez-vous aujourd\'hui ? Posez-moi une question sur la douleur, l\'hydratation, l\'alimentation, le paludisme, ou autre chose !'
          : 'Hello! 👋 I\'m Sika, your SickleCare health assistant. How are you feeling today? Ask me about pain management, hydration, nutrition, malaria prevention, or anything else!';
    }

    // --- 2. How are you ---
    if (p.contains('how are you') ||
        p.contains('how do you do') ||
        p.contains('comment ca va') ||
        p.contains('ça va') ||
        p.contains('comment tu vas') ||
        p.contains('comment allez')) {
      return isFr
          ? 'Je vais très bien, merci de demander ! 😊 Et vous, comment vous sentez-vous aujourd\'hui ? Avez-vous bu assez d\'eau ?'
          : 'I\'m doing great, thanks for asking! 😊 How are you feeling today? Have you been drinking enough water?';
    }

    // --- 3. Thanks ---
    if (RegExp(r'\b(thank|thanks|merci|cool|super|parfait|great|awesome|ok)\b')
        .hasMatch(p)) {
      return isFr
          ? 'De rien ! 😊 N\'hésitez pas si vous avez d\'autres questions. Prenez soin de vous et restez hydraté(e) !'
          : 'You\'re welcome! 😊 Feel free to ask more questions anytime. Take care and stay hydrated!';
    }

    // --- 4. Identity ---
    if (p.contains('who are you') ||
        p.contains('your name') ||
        p.contains('what are you') ||
        p.contains('qui es-tu') ||
        p.contains('ton nom') ||
        p.contains('tu es qui') ||
        p.contains('c\'est quoi sika')) {
      return isFr
          ? 'Je m\'appelle Sika ! 🩺 Je suis l\'assistante virtuelle de SickleCare, conçue pour accompagner les personnes drépanocytaires et leurs familles au Cameroun. Je peux vous aider avec l\'hydratation, la nutrition, la gestion de la douleur, et les rappels.'
          : 'I\'m Sika! 🩺 I\'m the SickleCare health companion, designed to support people living with sickle cell disease and their caregivers in Cameroon. I can help with hydration, nutrition, pain management, and reminders.';
    }

    // --- 5. What can you do ---
    if (p.contains('what can you') ||
        p.contains('help me') ||
        p.contains('what do you do') ||
        p.contains('que peux-tu') ||
        p.contains('aide-moi') ||
        p.contains('tu fais quoi') ||
        p.contains('comment tu peux')) {
      return isFr
          ? 'Je peux vous aider avec :\n• 💧 Hydratation et rappels d\'eau\n• 🥗 Nutrition locale camerounaise\n• 💊 Gestion de la douleur\n• 🦟 Prévention du paludisme\n• 🌡️ Que faire en cas de fièvre\n• ❄️ Protection contre le froid\n• ⏰ Configuration des rappels\nPosez-moi n\'importe quelle question !'
          : 'I can help you with:\n• 💧 Hydration and water reminders\n• 🥗 Local Cameroonian nutrition\n• 💊 Pain management tips\n• 🦟 Malaria prevention\n• 🌡️ What to do when you have fever\n• ❄️ Staying warm in cold weather\n• ⏰ Setting up reminders\nJust ask me anything!';
    }

    // --- 6. Pain / Crisis ---
    if (RegExp(r'(pain|crisis|hurt|ache|sore|douleur|crise|mal|souffr)')
        .hasMatch(p)) {
      return isFr
          ? '🩹 Pour la douleur :\n• Repos complet dans un endroit calme\n• Compresses tièdes (jamais froides !)\n• Buvez beaucoup d\'eau tiède\n• Prenez vos médicaments prescrits\n\n⚠️ Si la douleur est thoracique, si vous avez du mal à respirer ou une forte fièvre → rendez-vous immédiatement à l\'hôpital le plus proche !'
          : '🩹 For pain:\n• Rest completely in a quiet place\n• Apply warm compresses (never cold!)\n• Drink plenty of warm water\n• Take your prescribed medications\n\n⚠️ If you have chest pain, difficulty breathing, or high fever → go to the nearest hospital immediately!';
    }

    // --- 7. Water / Hydration ---
    if (RegExp(r'(water|hydrat|drink|thirst|eau|boire|soif|liquide)')
        .hasMatch(p)) {
      return isFr
          ? '💧 Hydratation pour la drépanocytose :\n• Buvez 2,5 à 3 litres d\'eau par jour (10-12 verres)\n• En période de chaleur ou d\'harmattan, buvez encore plus\n• L\'eau aide les globules rouges à circuler et prévient les crises\n• Évitez l\'alcool et les sodas excessifs\n• Activez le rappel d\'eau dans l\'écran Rappels !'
          : '💧 Hydration for sickle cell:\n• Drink 2.5 to 3 liters daily (10-12 cups)\n• In hot or harmattan weather, drink even more\n• Water keeps red blood cells flowing and prevents crises\n• Avoid excess alcohol and sugary drinks\n• Enable the water reminder in the Reminders screen!';
    }

    // --- 8. Food / Diet ---
    if (RegExp(
            r'(food|diet|eat|nutri|meal|vitamin|manger|aliment|nourri|repas|vitamine|régime)')
        .hasMatch(p)) {
      return isFr
          ? '🥗 Alimentation locale recommandée :\n• Légumes verts : ndolé, eru, gombo, moringa\n• Protéines : haricots, arachides, poisson, œufs\n• Féculents : plantain, patate douce, manioc\n• Fruits riches en vitamine C : orange, mangue, goyave, papaye\n• Prenez de l\'acide folique quotidiennement\n• Évitez l\'alcool et les boissons très froides'
          : '🥗 Recommended local foods:\n• Green vegetables: ndole, eru, okra, moringa\n• Protein: beans, groundnuts, fish, eggs\n• Starchy foods: plantain, sweet potato, cassava\n• Vitamin C fruits: oranges, mangoes, guavas, papaya\n• Take folic acid daily\n• Avoid alcohol and very cold drinks';
    }

    // --- 9. Cold / Weather ---
    if (RegExp(
            r'(cold|weather|warm|chill|harmattan|froid|chaud|chaleur|température)')
        .hasMatch(p)) {
      return isFr
          ? '❄️ Protection contre le froid et l\'harmattan :\n• Couvrez-vous chaudement (chaussettes, pull-over)\n• Évitez les douches froides — préférez l\'eau tiède\n• Buvez des boissons tièdes\n• Le vent poussiéreux de l\'harmattan contracte les vaisseaux sanguins et peut déclencher une crise'
          : '❄️ Cold and harmattan protection:\n• Dress warmly (wear socks, sweaters)\n• Avoid cold baths — use warm water\n• Drink warm fluids\n• The dusty harmattan wind constricts blood vessels and can trigger a crisis';
    }

    // --- 10. Malaria / Fever ---
    if (RegExp(r'(malaria|palu|fever|fievre|fièvre|mosquit|moustiq)')
        .hasMatch(p)) {
      return isFr
          ? '🦟 Prévention du paludisme :\n• Dormez sous une moustiquaire imprégnée chaque nuit\n• Lavez-vous les mains régulièrement\n• Traitez toute fièvre rapidement — consultez un centre de santé\n• Le paludisme est l\'un des principaux déclencheurs de crises drépanocytaires au Cameroun'
          : '🦟 Malaria prevention:\n• Sleep under an insecticide-treated bed net every night\n• Wash hands frequently\n• Treat any fever promptly — visit a health center\n• Malaria is one of the top sickle cell crisis triggers in Cameroon';
    }

    // --- 11. Reminders / Alarms ---
    if (RegExp(r'(alarm|reminder|notif|rappel|reveil|réveil|alarme)')
        .hasMatch(p)) {
      return isFr
          ? '⏰ Rappels SickleCare :\n• Allez dans l\'écran "Rappels" pour configurer des alarmes\n• Activez le rappel d\'eau automatique (toutes les 30 min, 1h ou 2h)\n• Créez des alarmes personnalisées pour vos médicaments\n• Assurez-vous d\'autoriser les notifications dans les paramètres de votre téléphone'
          : '⏰ SickleCare Reminders:\n• Go to the "Reminders" screen to set up alarms\n• Enable automatic water reminders (every 30 min, 1hr, or 2hrs)\n• Create custom alarms for medications\n• Make sure notifications are enabled in your phone settings';
    }

    // --- 12. Medication ---
    if (RegExp(
            r'(medic|drug|pill|tablet|folic|hydroxy|medicament|médicament|comprimé|traitement)')
        .hasMatch(p)) {
      return isFr
          ? '💊 Médicaments importants :\n• Prenez l\'acide folique tous les jours comme prescrit\n• L\'hydroxyurée réduit la fréquence des crises (sur prescription)\n• Ne prenez JAMAIS de médicaments non prescrits par votre médecin\n• Consultez votre médecin si vos douleurs changent de nature'
          : '💊 Important medications:\n• Take folic acid daily as prescribed\n• Hydroxyurea reduces crisis frequency (by prescription)\n• NEVER take medications not prescribed by your doctor\n• See your doctor if your pain patterns change';
    }

    // --- 13. Sickle cell info ---
    if (RegExp(
            r"(sickle|drepa|drepano|drépano|anemia|anémie|genotype|génotype|hbs|hbss|hbsc|what is|c'est quoi)")
        .hasMatch(p)) {
      return isFr
          ? '🩸 La drépanocytose est une maladie génétique du sang. Les globules rouges deviennent rigides en forme de faucille, bloquant la circulation sanguine. Les génotypes courants sont SS, SC, et S-bêta thalassémie. L\'hydratation, l\'acide folique, et éviter le froid/infections sont essentiels pour prévenir les crises.'
          : '🩸 Sickle cell disease is a genetic blood disorder where red blood cells become rigid and sickle-shaped, blocking blood flow. Common genotypes are SS, SC, and S-beta thalassemia. Hydration, folic acid, and avoiding cold/infections are key to preventing crises.';
    }

    // --- 14. Hospital / Emergency ---
    if (RegExp(
            r'(hospital|emergency|urgenc|doctor|clinic|hôpital|hopital|docteur|clinique|centre de santé)')
        .hasMatch(p)) {
      return isFr
          ? '🏥 En cas d\'urgence :\n• Douleur thoracique, difficulté à respirer, forte fièvre, faiblesse d\'un côté → allez immédiatement à l\'hôpital\n• Rendez-vous au centre de santé, hôpital de district, ou CHU le plus proche\n• Appelez les urgences locales si nécessaire'
          : '🏥 In case of emergency:\n• Chest pain, difficulty breathing, high fever, one-sided weakness → go to the hospital immediately\n• Visit the nearest health center, district hospital, or CHU\n• Call local emergency services if needed';
    }

    // --- 15. Exercise / Sport ---
    if (RegExp(
            r'(exercis|sport|run|walk|gym|activit|yoga|exercice|marche|courir)')
        .hasMatch(p)) {
      return isFr
          ? '🏃 Activité physique et drépanocytose :\n• Les exercices légers comme la marche, le yoga et la natation douce sont bénéfiques\n• Évitez les efforts intenses et prolongés\n• Restez bien hydraté(e) pendant l\'activité\n• Arrêtez-vous immédiatement si vous ressentez de la douleur'
          : '🏃 Exercise and sickle cell:\n• Light activities like walking, yoga, and gentle swimming are beneficial\n• Avoid intense or prolonged exertion\n• Stay well-hydrated during activity\n• Stop immediately if you feel any pain';
    }

    // --- 16. Pregnancy ---
    if (RegExp(
            r'(pregnan|baby|child|birth|enceint|bébé|grossesse|accouche|enfant)')
        .hasMatch(p)) {
      return isFr
          ? '🤰 Grossesse et drépanocytose :\n• Un suivi médical spécialisé est crucial\n• Hydratation renforcée et acide folique indispensable\n• Consultez régulièrement votre gynécologue et hématologue\n• Faites le test de dépistage du partenaire avant la grossesse'
          : '🤰 Pregnancy and sickle cell:\n• Specialized medical monitoring is crucial\n• Increased hydration and folic acid are essential\n• See your gynecologist and hematologist regularly\n• Get your partner tested before pregnancy';
    }

    // --- 17. Sleep ---
    if (RegExp(
            r'(sleep|rest|tired|fatigue|dormir|repos|fatigué|sommeil|insomni)')
        .hasMatch(p)) {
      return isFr
          ? '😴 Repos et sommeil :\n• Dormez suffisamment (7-9 heures par nuit)\n• Le repos aide votre corps à se régénérer\n• Gardez une bouteille d\'eau près de votre lit\n• Dormez sous une moustiquaire imprégnée'
          : '😴 Rest and sleep:\n• Get enough sleep (7-9 hours per night)\n• Rest helps your body recover\n• Keep a water bottle near your bed\n• Sleep under an insecticide-treated bed net';
    }

    // --- 18. Stress ---
    if (RegExp(r'(stress|anxi|worry|depress|mental|moral|inquiet|anxié|soucis)')
        .hasMatch(p)) {
      return isFr
          ? '🧠 Bien-être mental :\n• Le stress peut déclencher des crises drépanocytaires\n• Parlez de vos émotions avec vos proches ou un professionnel\n• La respiration profonde et la méditation peuvent aider\n• N\'hésitez pas à rejoindre un groupe de soutien drépanocytaire'
          : '🧠 Mental wellness:\n• Stress can trigger sickle cell crises\n• Talk about your feelings with loved ones or a professional\n• Deep breathing and meditation can help\n• Consider joining a sickle cell support group';
    }

    // --- 19. Good / Fine / Okay / Yes / No / Short answers ---
    if (RegExp(r"^(ok|okay|yes|no|oui|non|bien|d'accord|fine|good|bad|not bad|ça va|alright|sure|yep|nope|hmm|oh)$")
            .hasMatch(p) ||
        p.length <= 3) {
      return isFr
          ? 'D\'accord ! 😊 Si vous avez besoin de quelque chose, n\'hésitez pas. Je suis là pour vous aider avec :\n• Hydratation 💧\n• Alimentation 🥗\n• Gestion de la douleur 🩹\n• Rappels ⏰\nQue souhaitez-vous savoir ?'
          : 'Got it! 😊 If you need anything, just ask. I\'m here to help with:\n• Hydration 💧\n• Nutrition 🥗\n• Pain management 🩹\n• Reminders ⏰\nWhat would you like to know?';
    }

    // --- 20. Default conversational reply (catch-all) ---
    return isFr
        ? 'Merci pour votre message ! Je suis Sika et je peux vous conseiller sur :\n• 💧 L\'hydratation\n• 🥗 L\'alimentation locale\n• 🩹 La gestion de la douleur\n• 🦟 Le paludisme\n• ❄️ Le froid et l\'harmattan\n• 💊 Les médicaments\n• ⏰ Les rappels\nDites-moi ce qui vous intéresse !'
        : 'Thanks for your message! I\'m Sika and I can advise you on:\n• 💧 Hydration\n• 🥗 Local nutrition\n• 🩹 Pain management\n• 🦟 Malaria prevention\n• ❄️ Cold weather\n• 💊 Medications\n• ⏰ Reminders\nTell me what you\'d like to know!';
  }

  static bool _hasEmergencySymptoms(String prompt) {
    final p = prompt.toLowerCase();
    return RegExp(
      r'(chest pain|difficulty breathing|can.?t breathe|shortness of breath|'
      r'high fever|stroke|weakness on one side|confusion|severe pain|'
      r'douleur thoracique|respirer|souffle|forte fi[eè]vre|avc|'
      r'faiblesse.*côté|confusion|douleur intense)',
    ).hasMatch(p);
  }

  static bool _isUnsafeMedicationRequest(String prompt) {
    final p = prompt.toLowerCase();
    final doseOrChange = RegExp(
      r'(what dose|which dose|how much|dosage|dose|increase|decrease|'
      r'stop taking|start taking|can i take|should i take|posologie|'
      r'combien.*prendre|augmenter|diminuer|arr[eê]ter|commencer|'
      r'puis-je prendre|dois-je prendre)',
    ).hasMatch(p);
    final medication = RegExp(
      r'(medicine|medication|drug|pill|tablet|hydroxy|folic|opioid|'
      r'morphine|tramadol|ibuprofen|diclofenac|antibiotic|transfusion|'
      r'm[eé]dicament|comprim[eé]|traitement|hydroxyur[eé]e|'
      r'acide folique|antibiotique)',
    ).hasMatch(p);
    return doseOrChange && medication;
  }

  static String _medicalBoundaryReply(String prompt) {
    final isFr = RegExp(
      r'(posologie|combien|prendre|augmenter|diminuer|arr[eê]ter|commencer|m[eé]dicament|traitement|dois-je|puis-je)',
    ).hasMatch(prompt.toLowerCase());

    return isFr
        ? 'Je ne peux pas choisir une dose, modifier un traitement, ni te dire d’arrêter ou commencer un médicament. Cela doit être décidé par ton médecin. Si tes symptômes changent, contacte ton soignant; si douleur thoracique, difficulté à respirer, forte fièvre ou confusion, va immédiatement à l’hôpital. Tu peux aussi exporter le rapport médecin SickleCare pour le partager.'
        : 'I cannot choose a dose, change treatment, or tell you to stop/start a medication. That needs your clinician. If symptoms are changing, contact your care team; if you have chest pain, breathing trouble, high fever, or confusion, go to hospital now. You can export the SickleCare doctor report to share.';
  }

  static String _emergencyReply(String prompt) {
    final isFr = RegExp(
      r'(douleur|respirer|fi[eè]vre|faiblesse|côté|confusion|urgence|hopital|hôpital)',
    ).hasMatch(prompt.toLowerCase());

    return isFr
        ? 'URGENCE POSSIBLE : ces symptômes peuvent être graves chez une personne drépanocytaire. Va immédiatement à l’hôpital le plus proche ou appelle les urgences locales. Sika ne peut pas diagnostiquer ni remplacer un professionnel de santé.'
        : 'POSSIBLE EMERGENCY: these symptoms can be serious for someone with sickle cell disease. Go to the nearest hospital now or call local emergency services. Sika cannot diagnose or replace a health professional.';
  }
}
