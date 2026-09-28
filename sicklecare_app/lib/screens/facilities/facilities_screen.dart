import 'package:flutter/material.dart';

import '../../models/healthcare_facility.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import 'facility_detail_screen.dart';

/// Presentation states supported by [FacilitiesScreen]. The data layer can
/// switch these without the screen needing to know where facility data lives.
enum FacilitiesViewState { loading, content, error }

/// Searchable, filterable nearby-care screen.
///
/// Facility records are intentionally injected. This keeps the UI usable with
/// temporary mock data today and a repository/provider later, without coupling
/// the presentation layer to Firebase or location services.
class FacilitiesScreen extends StatefulWidget {
  final List<HealthcareFacility> facilities;
  final FacilitiesViewState viewState;
  final String? errorMessage;
  final String locationLabel;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onUseCurrentLocation;
  final ValueChanged<HealthcareFacility>? onFacilitySelected;

  const FacilitiesScreen({
    super.key,
    required this.facilities,
    this.viewState = FacilitiesViewState.content,
    this.errorMessage,
    this.locationLabel = 'Your selected area',
    this.onRetry,
    this.onRefresh,
    this.onUseCurrentLocation,
    this.onFacilitySelected,
  });

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  FacilityType? _type;
  String? _serviceId;
  bool _openNowOnly = false;
  bool _emergencyOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HealthcareFacility> get _visibleFacilities {
    final normalizedQuery = _query.trim().toLowerCase();
    final facilities = widget.facilities.where((facility) {
      final matchesType = _type == null || facility.type == _type;
      final matchesOpen = !_openNowOnly || facility.isOpen;
      final matchesEmergency = !_emergencyOnly || facility.hasEmergencyCare;
      final matchesService = _serviceId == null ||
          facility.services.any((service) => service.id == _serviceId);
      final searchableText = [
        facility.name,
        facility.type.label,
        facility.address,
        facility.city,
        ...facility.services.map((service) => service.name),
      ].join(' ').toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);
      return matchesType &&
          matchesOpen &&
          matchesEmergency &&
          matchesService &&
          matchesQuery;
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return facilities;
  }

  List<FacilityService> get _availableServices {
    final services = <String, FacilityService>{};
    for (final facility in widget.facilities) {
      for (final service in facility.services) {
        services.putIfAbsent(service.id, () => service);
      }
    }
    return services.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  int get _activeFilterCount {
    return [
      _type != null,
      _serviceId != null,
      _openNowOnly,
      _emergencyOnly,
    ].where((active) => active).length;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0 || _query.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
      _type = null;
      _serviceId = null;
      _openNowOnly = false;
      _emergencyOnly = false;
    });
  }

  Future<void> _refresh() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  void _showLocationMessage() {
    widget.onUseCurrentLocation?.call();
    if (widget.onUseCurrentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location access can be connected when a map and privacy flow are agreed.',
          ),
        ),
      );
    }
  }

  Future<void> _showFilters() async {
    final result = await showModalBottomSheet<_FacilityFilter>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _FacilitiesFilterSheet(
        current: _FacilityFilter(
          type: _type,
          serviceId: _serviceId,
          openNowOnly: _openNowOnly,
          emergencyOnly: _emergencyOnly,
        ),
        services: _availableServices,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _type = result.type;
      _serviceId = result.serviceId;
      _openNowOnly = result.openNowOnly;
      _emergencyOnly = result.emergencyOnly;
    });
  }

  void _openFacility(HealthcareFacility facility) {
    widget.onFacilitySelected?.call(facility);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FacilityDetailScreen(facility: facility),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find care'),
        actions: [
          IconButton(
            tooltip: 'Refresh facilities',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch (widget.viewState) {
        FacilitiesViewState.loading => const _FacilitiesLoading(),
        FacilitiesViewState.error => _FacilitiesError(
            message: widget.errorMessage ??
                'Nearby facilities could not be loaded right now.',
            onRetry: widget.onRetry,
          ),
        FacilitiesViewState.content => _FacilitiesContent(
            locationLabel: widget.locationLabel,
            searchController: _searchController,
            query: _query,
            visibleFacilities: _visibleFacilities,
            activeFilterCount: _activeFilterCount,
            selectedType: _type,
            openNowOnly: _openNowOnly,
            emergencyOnly: _emergencyOnly,
            hasActiveFilters: _hasActiveFilters,
            onSearchChanged: (value) => setState(() => _query = value),
            onClearSearch: _query.isEmpty
                ? null
                : () => setState(() {
                      _query = '';
                      _searchController.clear();
                    }),
            onShowFilters: _showFilters,
            onClearFilters: _clearFilters,
            onUseCurrentLocation: _showLocationMessage,
            onTypeChanged: (type) => setState(() => _type = type),
            onOpenNowChanged: (value) => setState(() => _openNowOnly = value),
            onEmergencyChanged: (value) =>
                setState(() => _emergencyOnly = value),
            onFacilityTap: _openFacility,
            onRefresh: _refresh,
          ),
      },
    );
  }
}

class _FacilitiesContent extends StatelessWidget {
  final String locationLabel;
  final TextEditingController searchController;
  final String query;
  final List<HealthcareFacility> visibleFacilities;
  final int activeFilterCount;
  final FacilityType? selectedType;
  final bool openNowOnly;
  final bool emergencyOnly;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onClearSearch;
  final VoidCallback onShowFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<FacilityType?> onTypeChanged;
  final ValueChanged<bool> onOpenNowChanged;
  final ValueChanged<bool> onEmergencyChanged;
  final ValueChanged<HealthcareFacility> onFacilityTap;
  final RefreshCallback onRefresh;

  const _FacilitiesContent({
    required this.locationLabel,
    required this.searchController,
    required this.query,
    required this.visibleFacilities,
    required this.activeFilterCount,
    required this.selectedType,
    required this.openNowOnly,
    required this.emergencyOnly,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onShowFilters,
    required this.onClearFilters,
    required this.onUseCurrentLocation,
    required this.onTypeChanged,
    required this.onOpenNowChanged,
    required this.onEmergencyChanged,
    required this.onFacilityTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnCount = constraints.maxWidth >= 1050
              ? 3
              : constraints.maxWidth >= 720
                  ? 2
                  : 1;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LocationCard(
                        locationLabel: locationLabel,
                        onUseCurrentLocation: onUseCurrentLocation,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search hospitals, clinics, or services',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: onClearSearch == null
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close),
                                  onPressed: onClearSearch,
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _QuickFilter(
                                    label: 'All care',
                                    selected: selectedType == null,
                                    onSelected: (_) => onTypeChanged(null),
                                  ),
                                  const SizedBox(width: 8),
                                  ...FacilityType.values.expand(
                                    (type) => [
                                      _QuickFilter(
                                        label: type.label,
                                        selected: selectedType == type,
                                        onSelected: (_) => onTypeChanged(type),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FilterButton(
                            count: activeFilterCount,
                            onPressed: onShowFilters,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Open now'),
                            selected: openNowOnly,
                            onSelected: onOpenNowChanged,
                            avatar: const Icon(Icons.schedule, size: 17),
                          ),
                          FilterChip(
                            label: const Text('Emergency care'),
                            selected: emergencyOnly,
                            onSelected: onEmergencyChanged,
                            avatar:
                                const Icon(Icons.emergency_outlined, size: 17),
                          ),
                          if (hasActiveFilters)
                            ActionChip(
                              label: const Text('Clear all'),
                              onPressed: onClearFilters,
                              avatar: const Icon(Icons.restart_alt, size: 17),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nearby facilities', style: tt.titleLarge),
                                const SizedBox(height: 2),
                                Text(
                                  visibleFacilities.isEmpty
                                      ? 'No results found'
                                      : '${visibleFacilities.length} ${visibleFacilities.length == 1 ? 'place' : 'places'} shown · sorted by distance',
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          if (visibleFacilities.isNotEmpty)
                            Icon(Icons.sort_by_alpha_outlined,
                                color: cs.onSurfaceVariant),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (visibleFacilities.isEmpty)
                        _FacilitiesEmpty(
                          hasActiveFilters: hasActiveFilters,
                          onClear: onClearFilters,
                        )
                      else if (columnCount == 1)
                        ...visibleFacilities.map(
                          (facility) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FacilityCard(
                              facility: facility,
                              onTap: () => onFacilityTap(facility),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columnCount,
                            // A card can wrap its service chips at tablet
                            // widths; leave enough vertical room rather than
                            // clipping the contact affordance.
                            mainAxisExtent: 292,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: visibleFacilities.length,
                          itemBuilder: (context, index) {
                            final facility = visibleFacilities[index];
                            return _FacilityCard(
                              facility: facility,
                              onTap: () => onFacilityTap(facility),
                            );
                          },
                        ),
                      const SizedBox(height: 6),
                      _FacilitiesPreviewNote(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String locationLabel;
  final VoidCallback onUseCurrentLocation;

  const _LocationCard({
    required this.locationLabel,
    required this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.location_on_outlined, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Showing care near',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUseCurrentLocation,
            child: const Text('Use my location'),
          ),
        ],
      ),
    );
  }
}

class _QuickFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _QuickFilter({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _FilterButton({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: count > 0 ? cs.primaryContainer : cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune,
                  color: count > 0 ? cs.onPrimaryContainer : cs.onSurface),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final HealthcareFacility facility;
  final VoidCallback onTap;

  const _FacilityCard({required this.facility, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final statusColor = facility.isOpen ? const Color(0xFF2E9B62) : cs.error;
    final displayedServices = facility.services.take(2).toList();
    final serviceCount = facility.services.length - displayedServices.length;

    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_facilityIcon(facility.type), color: cs.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${facility.type.label} · ${facility.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _distanceLabel(facility.distanceKm),
                style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            facility.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _StatusChip(
                label: facility.isOpen ? 'Open now' : 'Closed',
                color: statusColor,
                icon: facility.isOpen ? Icons.circle : Icons.schedule,
              ),
              if (facility.hasEmergencyCare)
                _StatusChip(
                  label: 'Emergency',
                  color: const Color(0xFFC83A4B),
                  icon: Icons.emergency_outlined,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (displayedServices.isEmpty)
            Text(
              'Service details coming soon',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...displayedServices.map(
                  (service) => _ServiceChip(
                    label: service.name,
                    available: service.isAvailable,
                  ),
                ),
                if (serviceCount > 0)
                  _ServiceChip(label: '+$serviceCount more'),
              ],
            ),
          const Spacer(),
          const Divider(height: 22),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  color: cs.onSurfaceVariant, size: 18),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'View care details and contact options',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ),
              Icon(Icons.chevron_right, color: cs.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: icon == Icons.circle ? 9 : 15),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final bool? available;

  const _ServiceChip({required this.label, this.available});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = available == false ? cs.onSurfaceVariant : cs.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FacilitiesEmpty extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onClear;

  const _FacilitiesEmpty(
      {required this.hasActiveFilters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      child: Column(
        children: [
          EmptyState(
            icon: Icons.search_off_outlined,
            title: hasActiveFilters
                ? 'No facilities match these filters'
                : 'No facilities nearby yet',
            subtitle: hasActiveFilters
                ? 'Try broadening the search or clearing a filter.'
                : 'Facility listings will appear here when they are available.',
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FacilitiesPreviewNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 17, color: cs.onSurfaceVariant),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Facility locations, distances, and availability are preview data until a verified directory and map provider are connected.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilitiesLoading extends StatelessWidget {
  const _FacilitiesLoading();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                const SizedBox(height: 30),
                CircularProgressIndicator(color: cs.primary),
                const SizedBox(height: 14),
                Text('Finding care near you…',
                    style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 30),
                ...List.generate(
                    3,
                    (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _FacilitySkeleton(),
                        )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FacilitySkeleton extends StatelessWidget {
  const _FacilitySkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.surfaceContainerHigh;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 46, height: 46, color: base, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 170, height: 14, color: base),
                    const SizedBox(height: 8),
                    _SkeletonBox(width: 105, height: 11, color: base),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SkeletonBox(width: double.infinity, height: 11, color: base),
          const SizedBox(height: 9),
          _SkeletonBox(width: 160, height: 11, color: base),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

class _FacilitiesError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _FacilitiesError({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Facilities are unavailable',
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

class _FacilitiesFilterSheet extends StatefulWidget {
  final _FacilityFilter current;
  final List<FacilityService> services;

  const _FacilitiesFilterSheet({required this.current, required this.services});

  @override
  State<_FacilitiesFilterSheet> createState() => _FacilitiesFilterSheetState();
}

class _FacilitiesFilterSheetState extends State<_FacilitiesFilterSheet> {
  late _FacilityFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.current;
  }

  void _reset() {
    setState(() => _filter = const _FacilityFilter());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                      child: Text('Filter facilities',
                          style: Theme.of(context).textTheme.titleLarge)),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
              const SizedBox(height: 18),
              Text('Facility type',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All care'),
                    selected: _filter.type == null,
                    onSelected: (_) => setState(
                        () => _filter = _filter.copyWith(clearType: true)),
                  ),
                  ...FacilityType.values.map(
                    (type) => ChoiceChip(
                      label: Text(type.label),
                      selected: _filter.type == type,
                      onSelected: (_) => setState(
                          () => _filter = _filter.copyWith(type: type)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Services', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 9),
              if (widget.services.isEmpty)
                Text(
                  'Service filters will be available when facilities share service details.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Any service'),
                      selected: _filter.serviceId == null,
                      onSelected: (_) => setState(
                          () => _filter = _filter.copyWith(clearService: true)),
                    ),
                    ...widget.services.map(
                      (service) => FilterChip(
                        label: Text(service.name),
                        selected: _filter.serviceId == service.id,
                        onSelected: (_) => setState(
                          () =>
                              _filter = _filter.copyWith(serviceId: service.id),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Text('Availability',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 9),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Open now'),
                subtitle: const Text('Show places marked as currently open'),
                value: _filter.openNowOnly,
                onChanged: (value) => setState(
                  () => _filter = _filter.copyWith(openNowOnly: value),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Emergency care'),
                subtitle:
                    const Text('Only show facilities with emergency support'),
                value: _filter.emergencyOnly,
                onChanged: (value) => setState(
                  () => _filter = _filter.copyWith(emergencyOnly: value),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context, _filter),
                child: const Text('Show facilities'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityFilter {
  final FacilityType? type;
  final String? serviceId;
  final bool openNowOnly;
  final bool emergencyOnly;

  const _FacilityFilter({
    this.type,
    this.serviceId,
    this.openNowOnly = false,
    this.emergencyOnly = false,
  });

  _FacilityFilter copyWith({
    FacilityType? type,
    String? serviceId,
    bool? openNowOnly,
    bool? emergencyOnly,
    bool clearType = false,
    bool clearService = false,
  }) {
    return _FacilityFilter(
      type: clearType ? null : (type ?? this.type),
      serviceId: clearService ? null : (serviceId ?? this.serviceId),
      openNowOnly: openNowOnly ?? this.openNowOnly,
      emergencyOnly: emergencyOnly ?? this.emergencyOnly,
    );
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
