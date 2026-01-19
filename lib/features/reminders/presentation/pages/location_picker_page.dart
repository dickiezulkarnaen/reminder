import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class LocationSelection {
  const LocationSelection({required this.latitude, required this.longitude, this.label});

  final double latitude;
  final double longitude;
  final String? label;

  static const def = LocationSelection(
      latitude: -6.175392,
      longitude: 106.827153,
      label: 'Jakarta'
  );

  LocationSelection? copyWith({double? latitude, double? longitude, String? label}) {
    return LocationSelection(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
    );
  }
}

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initial});

  final LocationSelection? initial;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  Position? _selected;
  String? _label;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _label = initial?.label;
    if (initial != null) {
      _selected = Position(initial.longitude, initial.latitude);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selected;

    final initialCamera = CameraOptions(
      center: Point(
        coordinates: selected ?? Position(0, 0),
      ),
      zoom: selected == null ? 1 : 15,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          TextButton(
            onPressed: selected == null
                ? null
                : () {
                    Navigator.of(context).pop(
                      LocationSelection(
                        latitude: selected.lat.toDouble(),
                        longitude: selected.lng.toDouble(),
                        label: _label,
                      ),
                    );
                  },
            child: const Text('Done'),
          ),
        ],
      ),
      body: Stack(
        children: [
          MapWidget(
            cameraOptions: initialCamera,
            onTapListener: (ctx) {
              final p = ctx.point;
              final pos = p.coordinates;
              setState(() {
                _selected = pos;
              });
            },
            onCameraChangeListener: (data) {
              setState(() {
                _selected = data.cameraState.center.coordinates;
              });
            },
          ),
          const IgnorePointer(
            child: Center(
              child: Icon(
                Icons.place_rounded,
                size: 44,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            selected == null
                ? 'Tap on the map to choose a location.'
                : 'Selected: ${selected.lat.toStringAsFixed(5)}, ${selected.lng.toStringAsFixed(5)}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
