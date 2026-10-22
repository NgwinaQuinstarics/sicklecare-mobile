import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/healthcare_facility.dart';
import 'empty_state.dart';
import 'section_card.dart';

/// A privacy-safe, provider-neutral visual map for the facility directory.
///
/// It deliberately renders mock coordinates as an abstract map instead of
/// requesting device location, embedding a third-party map, or implying live
/// navigation. Selecting a pin returns its facility to the calling screen.
class FacilityMapPreviewSheet extends StatefulWidget {
  const FacilityMapPreviewSheet({
    super.key,
    required this.facilities,
    required this.locationLabel,
  });

  final List<HealthcareFacility> facilities;
  final String locationLabel;

  @override
  State<FacilityMapPreviewSheet> createState() =>
      _FacilityMapPreviewSheetState();
}

class _FacilityMapPreviewSheetState extends State<FacilityMapPreviewSheet> {
  HealthcareFacility? _selected;

  List<_MapPoint> get _points => _mapPoints(widget.facilities);

  @override
  void initState() {
    super.initState();
    final points = _points;
    _selected = points.isEmpty ? null : points.first.facility;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final points = _points;
    final selected = _selected;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          key: const Key('facility-map-preview-sheet'),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Facility map preview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${points.length} ${points.length == 1 ? 'place' : 'places'} from the current results',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close map preview',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _PreviewDisclosure(locationLabel: widget.locationLabel),
              const SizedBox(height: 14),
              if (points.isEmpty)
                const SectionCard(
                  child: EmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'Map pins are unavailable',
                    subtitle:
                        'These preview listings do not contain usable map coordinates yet.',
                  ),
                )
              else ...[
                _FacilityMapCanvas(
                  points: points,
                  selected: selected,
                  onSelected: (facility) =>
                      setState(() => _selected = facility),
                ),
                if (selected != null) ...[
                  const SizedBox(height: 14),
                  _SelectedFacilityCard(
                    facility: selected,
                    onOpen: () => Navigator.of(context).pop(selected),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewDisclosure extends StatelessWidget {
  const _PreviewDisclosure({required this.locationLabel});

  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: cs.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is an abstract preview for $locationLabel. It uses fixture coordinates only and does not show your live location or provide navigation.',
              style: TextStyle(color: cs.onPrimaryContainer, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityMapCanvas extends StatelessWidget {
  const _FacilityMapCanvas({
    required this.points,
    required this.selected,
    required this.onSelected,
  });

  final List<_MapPoint> points;
  final HealthcareFacility? selected;
  final ValueChanged<HealthcareFacility> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Abstract facility map with ${points.length} selectable pins',
      child: AspectRatio(
        aspectRatio: 1.42,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.075),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const markerSize = 44.0;
              final availableWidth =
                  math.max(0.0, constraints.maxWidth - markerSize).toDouble();
              final availableHeight =
                  math.max(0.0, constraints.maxHeight - markerSize).toDouble();
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FacilityMapPainter(
                        roadColor: cs.primary.withValues(alpha: 0.14),
                        blockColor: cs.secondary.withValues(alpha: 0.09),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _MapLabel(label: 'Preview area'),
                  ),
                  for (final point in points)
                    Positioned(
                      left: (point.horizontal * availableWidth)
                          .clamp(0.0, availableWidth)
                          .toDouble(),
                      top: ((1 - point.vertical) * availableHeight)
                          .clamp(0.0, availableHeight)
                          .toDouble(),
                      child: _FacilityPin(
                        facility: point.facility,
                        selected: selected?.id == point.facility.id,
                        onTap: () => onSelected(point.facility),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FacilityPin extends StatelessWidget {
  const _FacilityPin({
    required this.facility,
    required this.selected,
    required this.onTap,
  });

  final HealthcareFacility facility;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = facility.hasEmergencyCare ? cs.error : cs.primary;
    final label = '${facility.name}, ${facility.type.label}, '
        '${_distanceLabel(facility.distanceKm)} away${selected ? ', selected' : ''}';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: facility.name,
        child: Material(
          key: Key('facility-map-pin-${facility.id}'),
          color: selected ? color : cs.surface,
          elevation: selected ? 5 : 2,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                facility.hasEmergencyCare
                    ? Icons.emergency_outlined
                    : _facilityIcon(facility.type),
                color: selected ? cs.onPrimary : color,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelectedFacilityCard extends StatelessWidget {
  const _SelectedFacilityCard({required this.facility, required this.onOpen});

  final HealthcareFacility facility;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_facilityIcon(facility.type), color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${facility.type.label} · ${_distanceLabel(facility.distanceKm)} away',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${facility.address}, ${facility.city}',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('map-preview-open-details'),
              onPressed: onOpen,
              icon: const Icon(Icons.arrow_forward_outlined),
              label: const Text('View facility details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPoint {
  const _MapPoint({
    required this.facility,
    required this.horizontal,
    required this.vertical,
  });

  final HealthcareFacility facility;
  final double horizontal;
  final double vertical;
}

List<_MapPoint> _mapPoints(List<HealthcareFacility> facilities) {
  final mappable = facilities
      .where((facility) =>
          facility.latitude.isFinite && facility.longitude.isFinite)
      .toList(growable: false);
  if (mappable.isEmpty) return const [];

  final minLatitude =
      mappable.map((facility) => facility.latitude).reduce(math.min);
  final maxLatitude =
      mappable.map((facility) => facility.latitude).reduce(math.max);
  final minLongitude =
      mappable.map((facility) => facility.longitude).reduce(math.min);
  final maxLongitude =
      mappable.map((facility) => facility.longitude).reduce(math.max);
  final latitudeRange = maxLatitude - minLatitude;
  final longitudeRange = maxLongitude - minLongitude;

  return [
    for (var index = 0; index < mappable.length; index++)
      _MapPoint(
        facility: mappable[index],
        horizontal: _positionFraction(
          mappable[index].longitude,
          minLongitude,
          longitudeRange,
          index,
        ),
        vertical: _positionFraction(
          mappable[index].latitude,
          minLatitude,
          latitudeRange,
          index,
        ),
      ),
  ];
}

double _positionFraction(
  double value,
  double minimum,
  double range,
  int index,
) {
  if (range.abs() < 0.000001) {
    return (0.5 + ((index % 3) - 1) * 0.13).clamp(0.14, 0.86).toDouble();
  }
  return (0.14 + ((value - minimum) / range) * 0.72)
      .clamp(0.14, 0.86)
      .toDouble();
}

class _FacilityMapPainter extends CustomPainter {
  const _FacilityMapPainter({
    required this.roadColor,
    required this.blockColor,
  });

  final Color roadColor;
  final Color blockColor;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = roadColor
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final block = Paint()..color = blockColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .07,
          size.height * .62,
          size.width * .27,
          size.height * .17,
        ),
        const Radius.circular(9),
      ),
      block,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .66,
          size.height * .18,
          size.width * .2,
          size.height * .16,
        ),
        const Radius.circular(9),
      ),
      block,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .58,
          size.height * .7,
          size.width * .29,
          size.height * .14,
        ),
        const Radius.circular(9),
      ),
      block,
    );

    final route = Path()
      ..moveTo(-10, size.height * .72)
      ..cubicTo(
        size.width * .17,
        size.height * .8,
        size.width * .29,
        size.height * .22,
        size.width * .51,
        size.height * .45,
      )
      ..cubicTo(
        size.width * .69,
        size.height * .59,
        size.width * .77,
        size.height * .22,
        size.width + 10,
        size.height * .31,
      );
    canvas.drawPath(route, road);
    canvas.drawLine(
      Offset(size.width * .42, -10),
      Offset(size.width * .37, size.height + 10),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant _FacilityMapPainter oldDelegate) {
    return oldDelegate.roadColor != roadColor ||
        oldDelegate.blockColor != blockColor;
  }
}

IconData _facilityIcon(FacilityType type) {
  return switch (type) {
    FacilityType.hospital => Icons.local_hospital_outlined,
    FacilityType.clinic => Icons.health_and_safety_outlined,
    FacilityType.healthCenter => Icons.medical_information_outlined,
  };
}

String _distanceLabel(double distanceKm) {
  if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
  return '${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} km';
}
