// Owner: Vishwa. The Map tab: one day of the open trip as numbered pins on
// OpenStreetMap, the road route through them from OSRM, and a card for
// the selected stop (REQ-4.1, REQ-4.2). If OSRM is slow or down the pins
// stay and the line goes. Design: design/screens/night-04-map-saved-offline.png.
// The Live/Saved map switch belongs to Offline (Sanjay, issue #26).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dev/app_config.dart';
import '../../models/itinerary_item.dart';
import '../../models/trip.dart';
import '../../services/routing_service.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import '../accounts/accounts_provider.dart';
import '../itinerary/day_switcher.dart';
import '../itinerary/itinerary_provider.dart';
import '../itinerary/trips_screen.dart';

// The night map is OpenStreetMap's tiles inverted, mostly desaturated and
// tinted warm — the same recipe as the pictures in design/screens/.
const _nightTiles = ColorFilter.matrix([
  -0.297, -0.300, -0.058, 0, 172, //
  -0.153, -0.445, -0.058, 0, 171, //
  -0.153, -0.300, -0.203, 0, 169, //
  0, 0, 0, 1, 0, //
]);

// Middle of India, for when there is nothing to centre on.
const _india = LatLng(20.59, 78.96);

String _routeSummary(RouteResult route) {
  final km = (route.distanceMeters / 1000).toStringAsFixed(1);
  final minutes = (route.durationSeconds / 60).round();
  final how = useFakeData ? 'straight line, demo data' : 'by road';
  return '$km km · $minutes min $how';
}

class MapsScreen extends StatefulWidget {
  /// Tests turn tiles off: they have no internet.
  final bool showTiles;

  const MapsScreen({super.key, this.showTiles = true});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final _map = MapController();
  bool _mapReady = false;

  int _day = 1;
  int _selected = 0; // index into the day's stops that have a place

  // The route belongs to one trip, day and set of stops; the key says which.
  String? _routeKey;
  RouteResult? _route;
  bool _routing = false;
  bool _routeFailed = false;

  @override
  void initState() {
    super.initState();
    _openNextTripIfNone();
  }

  // The Map shows whichever trip the Trips tab last opened; before that,
  // the next upcoming trip.
  Future<void> _openNextTripIfNone() async {
    final itinerary = context.read<ItineraryProvider>();
    final userId = context.read<AccountsProvider>().userId;
    if (itinerary.currentTrip != null || userId == null) return;
    try {
      if (itinerary.trips.isEmpty) await itinerary.loadTrips(userId);
      final next = nextTrip(itinerary.trips, today: DateTime.now()) ?? itinerary.trips.lastOrNull;
      if (next != null) await itinerary.openTrip(next);
    } on Exception {
      // No trips loaded: the card says there is no trip.
    }
  }

  Future<void> _loadRoute(String key, List<ItineraryItem> stops) async {
    if (stops.length < 2) {
      setState(() {
        _route = null;
        _routing = false;
        _routeFailed = false;
      });
      return;
    }
    setState(() {
      _routing = true;
      _routeFailed = false;
    });
    RouteResult? route;
    try {
      route = await getRouteThrough([for (final s in stops) RoutePoint(s.latitude!, s.longitude!)]);
    } on Exception {
      route = null;
    }
    // The user may have switched day while OSRM was answering.
    if (!mounted || key != _routeKey) return;
    setState(() {
      _routing = false;
      _route = route;
      _routeFailed = route == null;
    });
  }

  void _fitCamera(List<ItineraryItem> stops, Trip? trip) {
    if (!_mapReady) return;
    if (stops.isNotEmpty) {
      _map.fitCamera(CameraFit.coordinates(
        coordinates: [for (final s in stops) LatLng(s.latitude!, s.longitude!)],
        padding: const EdgeInsets.fromLTRB(48, 120, 48, 260),
        maxZoom: 15,
      ));
    } else if (trip?.latitude != null) {
      _map.move(LatLng(trip!.latitude!, trip.longitude!), 12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final night = Theme.of(context).brightness == Brightness.dark;
    final itinerary = context.watch<ItineraryProvider>();
    final trip = itinerary.currentTrip;

    if (trip != null && _day > trip.numberOfDays) _day = 1;
    final dayStops = trip == null ? <ItineraryItem>[] : itinerary.stopsForDay(_day);
    final placed = dayStops.where((s) => s.latitude != null && s.longitude != null).toList();
    if (_selected >= placed.length) _selected = 0;

    // When the trip, day or stops change, fetch a fresh route and refit.
    final key = '${trip?.id}|$_day|${placed.map((s) => '${s.latitude},${s.longitude}').join(';')}';
    if (key != _routeKey) {
      _routeKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitCamera(placed, trip);
        _loadRoute(key, placed);
      });
    }

    final center = trip?.latitude != null ? LatLng(trip!.latitude!, trip.longitude!) : _india;

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: center,
            initialZoom: trip == null ? 4 : 12,
            onMapReady: () {
              _mapReady = true;
              _fitCamera(placed, trip);
            },
          ),
          children: [
            if (widget.showTiles)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.meridian.smart_travel_assistant',
                tileBuilder: night ? (context, tile, _) => ColorFiltered(colorFilter: _nightTiles, child: tile) : null,
              ),
            if (_route != null)
              PolylineLayer(polylines: [
                Polyline(
                  points: [for (final p in _route!.points) LatLng(p.latitude, p.longitude)],
                  color: colors.amber,
                  strokeWidth: 4.5,
                  borderColor: colors.ground,
                  borderStrokeWidth: 2.25,
                ),
              ]),
            MarkerLayer(markers: [
              for (var i = 0; i < placed.length; i++)
                Marker(
                  point: LatLng(placed[i].latitude!, placed[i].longitude!),
                  width: 44,
                  height: 44,
                  child: _StopPin(
                    number: dayStops.indexOf(placed[i]) + 1,
                    selected: i == _selected,
                    onTap: () => setState(() => _selected = i),
                  ),
                ),
            ]),
          ],
        ),
        // Licence condition: OpenStreetMap credit always visible; tapping
        // it opens the licence page.
        Positioned(
          left: 16,
          bottom: 100 + 8,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: colors.ground.withValues(alpha: 0.7),
                child: Text('© OpenStreetMap contributors',
                    style: MeridianText.monoData.copyWith(fontSize: 10, color: colors.inkSoft)),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
            child: trip == null
                ? const SizedBox.shrink()
                : DaySwitcher(
                    days: trip.numberOfDays,
                    selected: _day,
                    labelOf: (day) => 'Day $day',
                    onSelect: (day) => setState(() {
                      _day = day;
                      _selected = 0;
                    }),
                  ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 100, // clear of the floating nav bar
          child: _StopCard(
            trip: trip,
            day: _day,
            dayStops: dayStops,
            placed: placed,
            selected: _selected,
            routeLine: _routing
                ? 'Finding the road…'
                : _routeFailed
                    ? 'No route right now. Showing stops only.'
                    : _route == null
                        ? null
                        : _routeSummary(_route!),
          ),
        ),
      ],
    );
  }
}

/// Numbered circle: the selected stop is amber with a glow, the rest outlined.
class _StopPin extends StatelessWidget {
  final int number;
  final bool selected;
  final VoidCallback onTap;

  const _StopPin({required this.number, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return Semantics(
      button: true,
      label: 'Stop $number',
      excludeSemantics: true, // read "Stop 3", not "Stop 3, 3"
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: selected ? 34 : 28,
            height: selected ? 34 : 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? colors.amber : colors.surface,
              border: Border.all(color: selected ? colors.amber : colors.ink, width: 2),
              boxShadow: selected ? [BoxShadow(color: colors.amber.withValues(alpha: 0.45), blurRadius: 14, spreadRadius: 4)] : null,
            ),
            child: Text('$number',
                style: MeridianText.monoData.copyWith(color: selected ? colors.onAmber : colors.ink, fontSize: 13)),
          ),
        ),
      ),
    );
  }
}

/// The card at the bottom: the selected stop, or why there is nothing to show.
class _StopCard extends StatelessWidget {
  final Trip? trip;
  final int day;
  final List<ItineraryItem> dayStops;
  final List<ItineraryItem> placed;
  final int selected;
  final String? routeLine;

  const _StopCard({
    required this.trip,
    required this.day,
    required this.dayStops,
    required this.placed,
    required this.selected,
    required this.routeLine,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final missing = dayStops.length - placed.length;

    final List<Widget> body;
    if (trip == null) {
      body = [
        Text('No trip yet', style: text.titleLarge),
        const SizedBox(height: 4),
        Text('Create one on the Trips tab and its stops show up here.', style: text.bodySmall),
      ];
    } else if (placed.isEmpty) {
      body = [
        Text('Nothing on the map for Day $day', style: text.titleLarge),
        const SizedBox(height: 4),
        Text('Give a stop a place on the Trips tab and it shows up here.', style: text.bodySmall),
      ];
    } else {
      final stop = placed[selected];
      final number = dayStops.indexOf(stop) + 1;
      body = [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STOP $number OF ${dayStops.length} · DAY $day',
                      style: MeridianText.monoData.copyWith(color: colors.amberText)),
                  const SizedBox(height: 4),
                  Text(stop.title, style: text.titleLarge),
                ],
              ),
            ),
            if (stop.startTime != null)
              // Stored as "HH:mm:ss"; shown as hours and minutes.
              Text(stop.startTime!.substring(0, 5), style: MeridianText.nowNumber.copyWith(fontSize: 36, color: colors.ink)),
          ],
        ),
        if (routeLine != null) ...[
          const SizedBox(height: 10),
          Text(routeLine!, style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
        ],
        if (missing > 0) ...[
          const SizedBox(height: 4),
          Text('$missing ${missing == 1 ? 'stop has' : 'stops have'} no place yet, so ${missing == 1 ? 'it is' : 'they are'} not on the map',
              style: text.bodySmall),
        ],
      ];
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: body),
    );
  }
}
