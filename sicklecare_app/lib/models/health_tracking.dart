/// A medication card and reminder displayed in the warrior experience.
class MedicationPlan {
  const MedicationPlan({
    required this.id,
    required this.name,
    required this.dosage,
    required this.scheduleLabel,
    this.nextDoseAt,
    this.reminderEnabled = true,
    this.isActive = true,
    this.instructions = '',
  });

  final String id;
  final String name;
  final String dosage;
  final String scheduleLabel;
  final DateTime? nextDoseAt;
  final bool reminderEnabled;
  final bool isActive;
  final String instructions;

  MedicationPlan copyWith({
    String? id,
    String? name,
    String? dosage,
    String? scheduleLabel,
    DateTime? nextDoseAt,
    bool? reminderEnabled,
    bool? isActive,
    String? instructions,
  }) {
    return MedicationPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      scheduleLabel: scheduleLabel ?? this.scheduleLabel,
      nextDoseAt: nextDoseAt ?? this.nextDoseAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isActive: isActive ?? this.isActive,
      instructions: instructions ?? this.instructions,
    );
  }
}

/// A presentation-level crisis log. It does not encode a clinical assessment.
class PainCrisis {
  const PainCrisis({
    required this.id,
    required this.startedAt,
    required this.intensity,
    required this.symptoms,
    required this.affectedAreas,
    this.endedAt,
    this.notes = '',
    this.actionTaken = '',
    this.requiresMedicalAttention = false,
  }) : assert(intensity >= 0 && intensity <= 10);

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int intensity;
  final List<String> symptoms;
  final List<String> affectedAreas;
  final String notes;
  final String actionTaken;
  final bool requiresMedicalAttention;

  bool get isOngoing => endedAt == null;

  PainCrisis copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? intensity,
    List<String>? symptoms,
    List<String>? affectedAreas,
    String? notes,
    String? actionTaken,
    bool? requiresMedicalAttention,
  }) {
    return PainCrisis(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      intensity: intensity ?? this.intensity,
      symptoms: symptoms ?? this.symptoms,
      affectedAreas: affectedAreas ?? this.affectedAreas,
      notes: notes ?? this.notes,
      actionTaken: actionTaken ?? this.actionTaken,
      requiresMedicalAttention:
          requiresMedicalAttention ?? this.requiresMedicalAttention,
    );
  }
}

enum HealthTimelineEventType {
  symptom,
  crisis,
  medication,
  hydration,
  appointment,
  note,
}

extension HealthTimelineEventTypeLabel on HealthTimelineEventType {
  String get label {
    switch (this) {
      case HealthTimelineEventType.symptom:
        return 'Symptom';
      case HealthTimelineEventType.crisis:
        return 'Pain crisis';
      case HealthTimelineEventType.medication:
        return 'Medication';
      case HealthTimelineEventType.hydration:
        return 'Hydration';
      case HealthTimelineEventType.appointment:
        return 'Appointment';
      case HealthTimelineEventType.note:
        return 'Health note';
    }
  }
}

/// A chronological item for the health-history UI.
class HealthTimelineEvent {
  const HealthTimelineEvent({
    required this.id,
    required this.occurredAt,
    required this.type,
    required this.title,
    this.description = '',
    this.severity,
  }) : assert(severity == null || (severity >= 0 && severity <= 10));

  final String id;
  final DateTime occurredAt;
  final HealthTimelineEventType type;
  final String title;
  final String description;
  final int? severity;

  HealthTimelineEvent copyWith({
    String? id,
    DateTime? occurredAt,
    HealthTimelineEventType? type,
    String? title,
    String? description,
    int? severity,
  }) {
    return HealthTimelineEvent(
      id: id ?? this.id,
      occurredAt: occurredAt ?? this.occurredAt,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
    );
  }
}
