import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/healthcare_facility.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

/// Controls the presentation state of [FacilityDetailScreen] while a facility
/// record is being fetched by the app's future data layer.
enum FacilityDetailViewState { loading, content, error }

/// UI-only facility profile. The record is injected so this screen stays
/// independent from Firebase and can be driven by either mock or live data.
class FacilityDetailScreen extends StatelessWidget {
  final HealthcareFacility facility;
  final FacilityDetailViewState viewState;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const FacilityDetailScreen({
    super.key,
    required this.facility,
    this.viewState = FacilityDetailViewState.content,
    this.errorMessage,
    this.onRetry,
  });

  Future<void> _openUri(
    BuildContext context,
    Uri uri, {
    required String unavailableMessage,
  }) async {
    try {
      final canOpen = await canLaunchUrl(uri);
      if (!canOpen) {
        if (context.mounted) _showMessage(context, unavailableMessage);
        return;
      }

      final didOpen =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!didOpen && context.mounted) {
        _showMessage(context, unavailableMessage);
      }
    } catch (_) {
      if (context.mounted) _showMessage(context, unavailableMessage);
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _call(BuildContext context) {
    return _openUri(
      context,
      Uri(scheme: 'tel', path: facility.phoneNumber.replaceAll(' ', '')),
      unavailableMessage: 'A phone app is not available on this device.',
    );
  }

  Future<void> _directions(BuildContext context) {
    final coordinate = '${facility.latitude},${facility.longitude}';
    return _openUri(
      context,
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': coordinate,
      }),
      unavailableMessage: 'Maps could not be opened on this device.',
    );
  }

  Future<void> _email(BuildContext context) {
    return _openUri(
      context,
      Uri(
        scheme: 'mailto',
        path: facility.email,
        queryParameters: {'subject': 'Care enquiry'},
      ),
      unavailableMessage: 'An email app is not available on this device.',
    );
  }

  Future<void> _website(BuildContext context) {
    final rawWebsite = facility.website?.trim();
    if (rawWebsite == null || rawWebsite.isEmpty) {
      return Future<void>.value();
    }
    final uri = Uri.tryParse(rawWebsite);
    final website = uri != null && uri.hasScheme
        ? uri
        : Uri.https(rawWebsite.replaceFirst(RegExp(r'^//'), ''));
    return _openUri(
      context,
      website,
      unavailableMessage: 'The facility website could not be opened.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = facility.name;
    return Scaffold(
      appBar: AppBar(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: switch (viewState) {
        FacilityDetailViewState.loading => const _FacilityDetailLoading(),
        FacilityDetailViewState.error => _FacilityDetailError(
            message:
                errorMessage ?? 'We could not load this facility right now.',
            onRetry: onRetry,
          ),
        FacilityDetailViewState.content => _FacilityDetailContent(
            facility: facility,
            onCall: () => _call(context),
            onDirections: () => _directions(context),
            onEmail: facility.email == null ? null : () => _email(context),
            onWebsite:
                facility.website == null ? null : () => _website(context),
          ),
      },
    );
  }
}

class _FacilityDetailContent extends StatelessWidget {
  final HealthcareFacility facility;
  final VoidCallback onCall;
  final VoidCallback onDirections;
  final VoidCallback? onEmail;
  final VoidCallback? onWebsite;

  const _FacilityDetailContent({
    required this.facility,
    required this.onCall,
    required this.onDirections,
    this.onEmail,
    this.onWebsite,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 820;
        final details = <Widget>[
          _OverviewCard(facility: facility),
          const SizedBox(height: 14),
          _LocationMapCard(facility: facility, onDirections: onDirections),
          const SizedBox(height: 14),
          _AboutCard(description: facility.description),
          const SizedBox(height: 14),
          _ServicesCard(services: facility.services),
        ];

        final contact = _ContactPanel(
          facility: facility,
          onCall: onCall,
          onDirections: onDirections,
          onEmail: onEmail,
          onWebsite: onWebsite,
        );

        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FacilityHero(facility: facility),
                      const SizedBox(height: 16),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Column(children: details)),
                            const SizedBox(width: 18),
                            SizedBox(width: 312, child: contact),
                          ],
                        )
                      else ...[
                        ...details,
                        const SizedBox(height: 14),
                        contact,
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Facility information is currently provided as a preview. '
                        'Please confirm availability directly with the facility.',
                        textAlign: TextAlign.center,
                        style:
                            tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FacilityHero extends StatelessWidget {
  final HealthcareFacility facility;

  const _FacilityHero({required this.facility});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final statusColor = facility.isOpen ? const Color(0xFF2E9B62) : cs.error;

    return SectionCard(
      padding: const EdgeInsets.all(22),
      gradient: LinearGradient(
        colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.27)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final icon = _FacilityTypeIcon(type: facility.type);
          final status = _FacilityOpenStatus(
            isOpen: facility.isOpen,
            color: statusColor,
          );
          final details = _FacilityHeroDetails(
            facility: facility,
            titleStyle: tt.headlineSmall,
          );

          // On phones the original single row squeezed the care tags into a
          // sliver beside the icon and status. Stack the header content below
          // its controls so every label remains readable.
          if (constraints.maxWidth < 400) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [icon, const Spacer(), status]),
                const SizedBox(height: 16),
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 15),
              Expanded(child: details),
              const SizedBox(width: 10),
              status,
            ],
          );
        },
      ),
    );
  }
}

class _FacilityTypeIcon extends StatelessWidget {
  const _FacilityTypeIcon({required this.type});

  final FacilityType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(_typeIcon(type), color: Colors.white, size: 30),
    );
  }
}

class _FacilityOpenStatus extends StatelessWidget {
  const _FacilityOpenStatus({required this.isOpen, required this.color});

  final bool isOpen;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.circle : Icons.schedule,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'Open now' : 'Closed',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityHeroDetails extends StatelessWidget {
  const _FacilityHeroDetails({
    required this.facility,
    required this.titleStyle,
  });

  final HealthcareFacility facility;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeroPill(label: facility.type.label),
            if (facility.hasEmergencyCare)
              const _HeroPill(
                label: 'Emergency care',
                icon: Icons.emergency_outlined,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          facility.name,
          style: titleStyle?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${facility.city} · ${_distanceLabel(facility.distanceKm)} away',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
        ),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _HeroPill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final HealthcareFacility facility;

  const _OverviewCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('At a glance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _OverviewMetric(
                icon: Icons.near_me_outlined,
                label: _distanceLabel(facility.distanceKm),
                detail: 'from your area',
                color: cs.primary,
              ),
              _OverviewMetric(
                icon: Icons.medical_services_outlined,
                label: facility.hasEmergencyCare
                    ? 'Emergency care'
                    : 'Scheduled care',
                detail: facility.hasEmergencyCare
                    ? 'Available here'
                    : 'Call before visiting',
                color: facility.hasEmergencyCare
                    ? const Color(0xFFC83A4B)
                    : cs.secondary,
              ),
              _OverviewMetric(
                icon: Icons.verified_user_outlined,
                label:
                    '${facility.services.where((service) => service.isAvailable).length} services',
                detail: 'shown as available',
                color: const Color(0xFF2E9B62),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final Color color;

  const _OverviewMetric({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 148),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 1),
              Text(
                detail,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationMapCard extends StatelessWidget {
  final HealthcareFacility facility;
  final VoidCallback onDirections;

  const _LocationMapCard({required this.facility, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 156,
              width: double.infinity,
              child: _MapPreview(
                facilityName: facility.name,
                distance: _distanceLabel(facility.distanceKm),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on_outlined, color: cs.primary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Address',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 3),
                      Text(
                        '${facility.address}, ${facility.city}',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('Directions'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  final String facilityName;
  final String distance;

  const _MapPreview({required this.facilityName, required this.distance});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primary.withValues(alpha: 0.08),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapGridPainter(
                roadColor: cs.primary.withValues(alpha: 0.14),
                blockColor: cs.secondary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 38,
            top: 25,
            child: _MapRoadPill(label: 'Your area'),
          ),
          Positioned(
            right: 24,
            top: 42,
            child: _MapRoadPill(label: '$distance away'),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_hospital, color: Colors.white),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: Text(
                    facilityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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

class _MapRoadPill extends StatelessWidget {
  final String label;

  const _MapRoadPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final Color roadColor;
  final Color blockColor;

  const _MapGridPainter({required this.roadColor, required this.blockColor});

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = roadColor
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final block = Paint()..color = blockColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            size.width * .07, size.height * .54, size.width * .25, 38),
        const Radius.circular(8),
      ),
      block,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            size.width * .68, size.height * .20, size.width * .18, 35),
        const Radius.circular(8),
      ),
      block,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            size.width * .62, size.height * .72, size.width * .27, 31),
        const Radius.circular(8),
      ),
      block,
    );

    final route = Path()
      ..moveTo(0, size.height * .72)
      ..cubicTo(
        size.width * .20,
        size.height * .78,
        size.width * .25,
        size.height * .26,
        size.width * .49,
        size.height * .45,
      )
      ..cubicTo(
        size.width * .66,
        size.height * .58,
        size.width * .73,
        size.height * .23,
        size.width,
        size.height * .30,
      );
    canvas.drawPath(route, road);
    canvas.drawLine(
      Offset(size.width * .45, 0),
      Offset(size.width * .39, size.height),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.roadColor != roadColor ||
        oldDelegate.blockColor != blockColor;
  }
}

class _AboutCard extends StatelessWidget {
  final String description;

  const _AboutCard({required this.description});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About this facility',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ServicesCard extends StatelessWidget {
  final List<FacilityService> services;

  const _ServicesCard({required this.services});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available services',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(
            'Availability is a guide. Call ahead to confirm before your visit.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          if (services.isEmpty)
            const _InlineHint(
              icon: Icons.info_outline,
              message:
                  'Service information will appear here when it is available.',
            )
          else
            ...services.map((service) => _ServiceTile(service: service)),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final FacilityService service;

  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final availabilityColor =
        service.isAvailable ? const Color(0xFF2E9B62) : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: availabilityColor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              service.isAvailable
                  ? Icons.check_circle_outline
                  : Icons.remove_circle_outline,
              size: 19,
              color: availabilityColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  service.description,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            service.isAvailable ? 'Available' : 'Call first',
            style: TextStyle(
              color: availabilityColor,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactPanel extends StatelessWidget {
  final HealthcareFacility facility;
  final VoidCallback onCall;
  final VoidCallback onDirections;
  final VoidCallback? onEmail;
  final VoidCallback? onWebsite;

  const _ContactPanel({
    required this.facility,
    required this.onCall,
    required this.onDirections,
    this.onEmail,
    this.onWebsite,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Contact & hours',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 13),
          _ContactLine(
            icon: Icons.call_outlined,
            title: 'Phone',
            value: facility.phoneNumber,
            onTap: onCall,
          ),
          if (facility.email != null) ...[
            const SizedBox(height: 12),
            _ContactLine(
              icon: Icons.mail_outline,
              title: 'Email',
              value: facility.email!,
              onTap: onEmail,
            ),
          ],
          if (facility.website != null) ...[
            const SizedBox(height: 12),
            _ContactLine(
              icon: Icons.language_outlined,
              title: 'Website',
              value: facility.website!,
              onTap: onWebsite,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Text('Opening hours', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (facility.openingHours.isEmpty)
            const _InlineHint(
              icon: Icons.schedule_outlined,
              message:
                  'Hours have not been shared yet. Please call before visiting.',
            )
          else
            ...facility.openingHours.map(
              (hours) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child:
                    Text(hours, style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call facility'),
          ),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Get directions'),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _ContactLine({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 17, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InlineHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.onSurfaceVariant, size: 19),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(message, style: TextStyle(color: cs.onSurfaceVariant))),
        ],
      ),
    );
  }
}

class _FacilityDetailLoading extends StatelessWidget {
  const _FacilityDetailLoading();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: cs.primary),
          const SizedBox(height: 14),
          Text(
            'Loading facility details…',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _FacilityDetailError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _FacilityDetailError({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: EmptyState(
            icon: Icons.location_off_outlined,
            title: 'Facility details are unavailable',
            subtitle: message,
          ),
        ),
        if (onRetry != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ),
      ],
    );
  }
}

IconData _typeIcon(FacilityType type) {
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
