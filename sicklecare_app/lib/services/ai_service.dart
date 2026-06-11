import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AI helper backed by Groq's OpenAI-compatible Chat Completions API.
///
/// Reads `GROQ_API_KEY` (falls back to `OPENAI_API_KEY`) from `.env`.
/// The assistant is tuned for the CAMEROONIAN context. If no key is configured
/// or the request fails, it returns a safe canned answer so the chat screen
/// always stays usable (never crashes).
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
      'For severe pain, chest pain, difficulty breathing, high fever, or signs '
      'of stroke, tell them to go to the nearest hospital immediately or call '
      'local emergency services.';

  static Future<String> ask(
    String prompt, {
    List<Map<String, String>>? history,
  }) async {
    final key =
        dotenv.maybeGet('GROQ_API_KEY') ?? dotenv.maybeGet('OPENAI_API_KEY');
    if (key == null || key.isEmpty) {
      return _fallback(prompt);
    }

    try {
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
                {'role': 'system', 'content': _system},
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
      return _fallback(prompt);
    } catch (_) {
      return _fallback(prompt);
    }
  }

  /// Cameroon-flavoured offline fallback (bilingual FR/EN keywords).
  static String _fallback(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('pain') || p.contains('crisis') || p.contains('douleur') ||
        p.contains('crise')) {
      return 'Pour la douleur : repos, compresse tiède, bois beaucoup d\'eau et '
          'prends le traitement prescrit par ton médecin. Si la douleur est '
          'forte, ou en cas de douleur à la poitrine, difficulté à respirer ou '
          'fièvre élevée — va immédiatement à l\'hôpital le plus proche.';
    }
    if (p.contains('water') || p.contains('hydrat') || p.contains('drink') ||
        p.contains('eau') || p.contains('boire')) {
      return 'Vise 2,5 à 3 L d\'eau par jour, davantage en pleine chaleur. La '
          'déshydratation est l\'un des déclencheurs de crise les plus '
          'fréquents, donc bois régulièrement toute la journée.';
    }
    if (p.contains('food') || p.contains('diet') || p.contains('eat') ||
        p.contains('nutri') || p.contains('manger') || p.contains('aliment') ||
        p.contains('nourri')) {
      return 'Privilégie des aliments locaux : légumes verts (ndolé, eru, '
          'gombo), haricots, arachides, plantain, patate, moringa, et des '
          'fruits riches en vitamine C (orange, mangue, goyave, papaye). Pense '
          'à l\'acide folique et limite l\'alcool et les boissons très froides.';
    }
    if (p.contains('cold') || p.contains('weather') || p.contains('froid') ||
        p.contains('harmattan') || p.contains('temps')) {
      return 'Le froid et l\'harmattan (vent sec et poussiéreux) peuvent '
          'déclencher une crise. Couvre-toi (surtout mains et pieds), reste '
          'hydraté et évite les changements brusques de température.';
    }
    if (p.contains('malaria') || p.contains('palu') || p.contains('fever') ||
        p.contains('fievre') || p.contains('fièvre')) {
      return 'Le paludisme et les infections sont des déclencheurs fréquents de '
          'crise au Cameroun. Dors sous moustiquaire, traite la fièvre '
          'rapidement, et consulte vite en cas de fièvre élevée.';
    }
    return 'Je peux t\'aider sur l\'hydratation, la nutrition, la gestion de la '
        'douleur, les rappels et les soins au quotidien (contexte camerounais). '
        'Pose-moi une question pour commencer.';
  }
}
