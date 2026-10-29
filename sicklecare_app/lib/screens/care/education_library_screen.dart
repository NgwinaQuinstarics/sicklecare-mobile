import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_banner.dart';

/// A session-only learning-library preview.
///
/// This deliberately contains no clinical instructions or published medical
/// claims. It lets the team review the information architecture and the
/// preparation workflow before editorial and clinical sources are connected.
class EducationLibraryScreen extends StatefulWidget {
  const EducationLibraryScreen({super.key});

  @override
  State<EducationLibraryScreen> createState() => _EducationLibraryScreenState();
}

class _EducationLibraryScreenState extends State<EducationLibraryScreen> {
  _LearningCategory _selectedCategory = _LearningCategory.all;
  final Set<String> _readTopicIds = <String>{};

  List<_LearningTopic> get _visibleTopics => _topics
      .where(
        (topic) =>
            _selectedCategory == _LearningCategory.all ||
            topic.category == _selectedCategory,
      )
      .toList(growable: false);

  void _openTopic(_LearningTopic topic) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final sheetL = sheetContext.l10n;
        final cs = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TopicIcon(icon: topic.icon, color: topic.color),
                  const SizedBox(height: 16),
                  Text(
                    topic.title(sheetL),
                    style: Theme.of(sheetContext).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topic.description(sheetL),
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    sheetL.tr(
                        'What you can prepare', 'Ce que tu peux préparer'),
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...topic.preparationPrompts(sheetL).map(
                        (prompt) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 20,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(prompt)),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 10),
                  StatusBanner(
                    tone: StatusBannerTone.warning,
                    title: sheetL.tr(
                      'Editorial review required',
                      'Validation éditoriale requise',
                    ),
                    message: sheetL.tr(
                      'This is a UI preview, not medical advice. Discuss personal care questions with a qualified clinician.',
                      'Ceci est un aperçu d’interface, pas un avis médical. Discute de tes questions personnelles avec un professionnel qualifié.',
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    key: Key('learning-topic-read-${topic.id}'),
                    onPressed: () {
                      setState(() => _readTopicIds.add(topic.id));
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l.tr(
                              'Marked as reviewed for this preview session.',
                              'Marqué comme consulté pour cette session d’aperçu.',
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.done_rounded),
                    label: Text(
                      sheetL.tr('Mark as reviewed', 'Marquer comme consulté'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final completed = _readTopicIds.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tr('Learning & support', 'Apprendre & se préparer')),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              key: const Key('learning-library-list'),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                StatusBanner(
                  tone: StatusBannerTone.info,
                  title: l.tr(
                      'Learning-library preview', 'Aperçu de la bibliothèque'),
                  message: l.tr(
                    'This layout uses temporary, non-clinical content. Sources and articles must be reviewed before publication.',
                    'Cette interface utilise du contenu temporaire et non clinique. Les sources et articles doivent être validés avant publication.',
                  ),
                ),
                const SizedBox(height: 16),
                _LearningHero(
                  completed: completed,
                  total: _topics.length,
                  title: l.tr(
                    'Make each care conversation easier to prepare',
                    'Prépare plus facilement chaque échange avec l’équipe de soins',
                  ),
                  subtitle: l.tr(
                    'Save questions, organise observations and explore support topics at your own pace.',
                    'Note tes questions, organise tes observations et découvre des thèmes de soutien à ton rythme.',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l.tr('Browse planned topics', 'Parcourir les thèmes prévus'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.tr(
                    'Choose a topic to review the proposed format.',
                    'Choisis un thème pour découvrir le format proposé.',
                  ),
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _LearningCategory.values.map((category) {
                    final selected = category == _selectedCategory;
                    return ChoiceChip(
                      key: Key('learning-category-${category.name}'),
                      label: Text(category.label(l)),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 14),
                ..._visibleTopics.map(
                  (topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TopicCard(
                      key: Key('learning-topic-${topic.id}'),
                      topic: topic,
                      isRead: _readTopicIds.contains(topic.id),
                      onTap: () => _openTopic(topic),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.tr('Review status', 'Statut de validation'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                _ReviewStatusCard(
                  title: l.tr('Sources & review', 'Sources & validation'),
                  subtitle: l.tr(
                    'No clinical sources are published in this preview.',
                    'Aucune source clinique n’est publiée dans cet aperçu.',
                  ),
                  icon: Icons.fact_check_outlined,
                ),
                const SizedBox(height: 10),
                _ReviewStatusCard(
                  title:
                      l.tr('Myth-versus-fact cards', 'Cartes mythe ou réalité'),
                  subtitle: l.tr(
                    'Planned for qualified editorial review before it appears here.',
                    'Prévues après validation éditoriale qualifiée avant leur affichage ici.',
                  ),
                  icon: Icons.auto_stories_outlined,
                ),
                const SizedBox(height: 18),
                StatusBanner(
                  tone: StatusBannerTone.warning,
                  title: l.tr('Need personal guidance?',
                      'Besoin d’un conseil personnel ?'),
                  message: l.tr(
                    'Use the emergency card for urgent symptoms, or contact your care team for individual advice.',
                    'Utilise la carte d’urgence en cas de symptôme urgent, ou contacte ton équipe de soins pour un conseil individuel.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningHero extends StatelessWidget {
  const _LearningHero({
    required this.completed,
    required this.total,
    required this.title,
    required this.subtitle,
  });

  final int completed;
  final int total;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : completed / total;
    return SectionCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cs.primary, Color.lerp(cs.primary, Colors.black, .26)!],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.menu_book_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: .9)),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: .25),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completed / $total',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    super.key,
    required this.topic,
    required this.isRead,
    required this.onTap,
  });

  final _LearningTopic topic;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopicIcon(icon: topic.icon, color: topic.color),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic.title(l),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    if (isRead)
                      Icon(
                        Icons.check_circle,
                        color: cs.primary,
                        semanticLabel: l.tr('Reviewed', 'Consulté'),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  topic.description(l),
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  topic.category.label(l),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: topic.color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _TopicIcon extends StatelessWidget {
  const _TopicIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color),
      );
}

class _ReviewStatusCard extends StatelessWidget {
  const _ReviewStatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              context.l10n.tr('Planned', 'Prévu'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LearningCategory { all, visit, routine, support }

extension on _LearningCategory {
  String label(L10n l) => switch (this) {
        _LearningCategory.all => l.tr('All topics', 'Tous les thèmes'),
        _LearningCategory.visit => l.tr('Visit prep', 'Préparer une visite'),
        _LearningCategory.routine =>
          l.tr('Daily planning', 'Routine quotidienne'),
        _LearningCategory.support => l.tr('Support', 'Soutien'),
      };
}

class _LearningTopic {
  const _LearningTopic({
    required this.id,
    required this.category,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.preparationPrompts,
  });

  final String id;
  final _LearningCategory category;
  final IconData icon;
  final Color color;
  final String Function(L10n l) title;
  final String Function(L10n l) description;
  final List<String> Function(L10n l) preparationPrompts;
}

const _topics = <_LearningTopic>[
  _LearningTopic(
    id: 'visit-prep',
    category: _LearningCategory.visit,
    icon: Icons.event_note_outlined,
    color: Color(0xFF9D4C49),
    title: _visitPrepTitle,
    description: _visitPrepDescription,
    preparationPrompts: _visitPrepPrompts,
  ),
  _LearningTopic(
    id: 'everyday-checkins',
    category: _LearningCategory.routine,
    icon: Icons.monitor_heart_outlined,
    color: Color(0xFF3E6E9C),
    title: _checkinsTitle,
    description: _checkinsDescription,
    preparationPrompts: _checkinsPrompts,
  ),
  _LearningTopic(
    id: 'medicine-questions',
    category: _LearningCategory.visit,
    icon: Icons.medication_outlined,
    color: Color(0xFF5E8B74),
    title: _medicineQuestionsTitle,
    description: _medicineQuestionsDescription,
    preparationPrompts: _medicineQuestionsPrompts,
  ),
  _LearningTopic(
    id: 'support-circle',
    category: _LearningCategory.support,
    icon: Icons.groups_2_outlined,
    color: Color(0xFF8A5C9E),
    title: _supportCircleTitle,
    description: _supportCircleDescription,
    preparationPrompts: _supportCirclePrompts,
  ),
];

String _visitPrepTitle(L10n l) =>
    l.tr('Prepare for a visit', 'Préparer une visite');
String _visitPrepDescription(L10n l) => l.tr(
      'Organise questions and information you want to discuss with your care team.',
      'Organise les questions et informations à discuter avec ton équipe de soins.',
    );
List<String> _visitPrepPrompts(L10n l) => [
      l.tr('Write the questions you want to ask.',
          'Note les questions que tu souhaites poser.'),
      l.tr('Bring your current medicines or medication list.',
          'Apporte tes médicaments actuels ou leur liste.'),
      l.tr('Note recent changes you would like to describe.',
          'Note les changements récents que tu souhaites décrire.'),
    ];

String _checkinsTitle(L10n l) =>
    l.tr('Everyday check-ins', 'Suivi au quotidien');
String _checkinsDescription(L10n l) => l.tr(
      'Plan the observations that are useful for your own care conversation.',
      'Planifie les observations utiles pour échanger sur tes soins.',
    );
List<String> _checkinsPrompts(L10n l) => [
      l.tr('Choose a simple way to note how you feel.',
          'Choisis une façon simple de noter comment tu te sens.'),
      l.tr('Keep any questions that come up between visits.',
          'Conserve les questions qui surgissent entre les visites.'),
      l.tr('Review what you want to share with your care team.',
          'Relis ce que tu souhaites partager avec ton équipe de soins.'),
    ];

String _medicineQuestionsTitle(L10n l) =>
    l.tr('Questions about medicines', 'Questions sur les médicaments');
String _medicineQuestionsDescription(L10n l) => l.tr(
      'Use this space to prepare questions for your prescriber or pharmacist.',
      'Utilise cet espace pour préparer tes questions au prescripteur ou au pharmacien.',
    );
List<String> _medicineQuestionsPrompts(L10n l) => [
      l.tr('Write down the name of the medicine you want to discuss.',
          'Note le nom du médicament dont tu veux parler.'),
      l.tr('Bring questions about the instructions you were given.',
          'Apporte tes questions sur les consignes reçues.'),
      l.tr('Do not change a prescription from this preview.',
          'Ne modifie pas une ordonnance depuis cet aperçu.'),
    ];

String _supportCircleTitle(L10n l) =>
    l.tr('Support and privacy', 'Soutien et confidentialité');
String _supportCircleDescription(L10n l) => l.tr(
      'Think through who you would like involved in your support circle.',
      'Réfléchis aux personnes que tu souhaites inclure dans ton cercle de soutien.',
    );
List<String> _supportCirclePrompts(L10n l) => [
      l.tr('Decide what information you are comfortable sharing.',
          'Décide quelles informations tu es à l’aise de partager.'),
      l.tr('List a trusted person you may want to involve.',
          'Note une personne de confiance que tu pourrais impliquer.'),
      l.tr('Ask your care team about available support resources.',
          'Demande à ton équipe de soins les ressources de soutien disponibles.'),
    ];
