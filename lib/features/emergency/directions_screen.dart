// Owner: Sanjay. Directions to a hospital or police station (REQ-5.2):
// the road route from routing_service.dart drawn on OpenStreetMap. If
// OSRM fails or is slow, the two pins stay and the straight-line distance
// is shown instead of a line.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dev/app_config.dart';
import '../../services/overpass_service.dart';
import '../../services/routing_service.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import 'emergency_provider.dart';

// routing_service's getRoute, swappable so tests can play "OSRM is down".
typedef FindRoute = Future<RouteResult> Function({
  required double originLat,
  required double originLng,
  required double destLat,
  required double destLng,
});

class DirectionsScreen extends StatefulWidget {
  final RoutePoint from;
  final OverpassPlace place;
  final bool fromSavedPosition; // the start is the last known location

  /// Tests turn tiles off: they have no internet.
  final bool showTiles;
  final FindRoute findRoute;

  const DirectionsScreen({
    super.key,
    required this.from,
    required this.place,
    this.fromSavedPosition = false,
    this.showTiles = true,
    this.findRoute = getRoute,
  });

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  RouteResult? _route;
  bool _routing = true;

  @override
  void initState() {
    super.initState();
    _findRoute();
  }

  Future<void> _findRoute() async {
    RouteResult? route;
    try {
      route = await widget.findRoute(
        originLat: widget.from.latitude,
        originLng: widget.from.longitude,
        destLat: widget.place.latitude,
        destLng: widget.place.longitude,
      );
    } catch (_) {
      route = null; // no signal, OSRM down or no road: distance only
    }
    if (!mounted) return;
    setState(() {
      _route = route;
      _routing = false;
    });
  }

  String _summary() {
    if (_routing) return 'Finding the road…';
    final route = _route;
    if (route == null) {
      final meters = distanceBetween(
          widget.from.latitude, widget.from.longitude, widget.place.latitude, widget.place.longitude);
      return '${formatDistance(meters)} in a straight line · no route right now';
    }
    final minutes = (route.durationSeconds / 60).round();
    // Fake data mode draws a straight line, so don't call it a road.
    final how = useFakeData ? 'demo line' : 'by road';
    return '${formatDistance(route.distanceMeters)} · $minutes min $how';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final start = LatLng(widget.from.latitude, widget.from.longitude);
    final end = LatLng(widget.place.latitude, widget.place.longitude);
    final title = placeTitle(widget.place);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.coordinates(
                  coordinates: [start, end],
                  padding: const EdgeInsets.all(48),
                ),
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                if (widget.showTiles)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.meridian.smart_travel_assistant',
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
                  Marker(
                    point: start,
                    child: Semantics(
                      label: widget.fromSavedPosition ? 'Your last known location' : 'You',
                      child: Icon(Icons.my_location, color: colors.key),
                    ),
                  ),
                  Marker(
                    point: end,
                    width: 44,
                    height: 44,
                    child: Semantics(
                      label: title,
                      child: Icon(
                        widget.place.amenityType == 'police' ? Icons.local_police : Icons.local_hospital,
                        color: colors.coral,
                        size: 32,
                      ),
                    ),
                  ),
                ]),
                // Licence condition: OpenStreetMap credit always visible.
                Align(
                  alignment: Alignment.bottomLeft,
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
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_summary(), style: MeridianText.monoData.copyWith(color: colors.amberText, fontSize: 13)),
                  if (widget.fromSavedPosition) ...[
                    const SizedBox(height: 6),
                    Text('Starts from your last known location, which may be out of date.', style: text.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
