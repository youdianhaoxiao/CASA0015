import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geojson/geojson.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:recycle_app/screen/home.dart';

class mapPage extends StatefulWidget {
  const mapPage({super.key});

  @override
  State<mapPage> createState() => _mapPageState();
}

class _mapPageState extends State<mapPage> {
  Location _locationController = Location();
  static const LatLng _pgoogle = LatLng( 51.5074, -0.1278);

  LatLng? _currentL = null;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    getLocation();
    _loadGeoJsonMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Page'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomePage()),);
          },
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _pgoogle,
          zoom: 13,
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          if (_currentL != null) {
            controller.animateCamera(CameraUpdate.newLatLng(_currentL!));
          }
        },
      ),
    );
  }

  Future<void> getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentL = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _markers.add(
            Marker(
              markerId: MarkerId('currentLocation'),
              position: _currentL!,
              infoWindow: InfoWindow(title: 'Your Location'),
            ),
          );
        });
      }
    });
  }

  Future<void> _loadGeoJsonMarkers() async {
    final String geoJsonData = await rootBundle.loadString('assets/export.geojson');
    GeoJson geoJson = GeoJson();

    await geoJson.parse(geoJsonData);

    Set<Marker> geoJsonMarkers = geoJson.points.map((point) {
      return Marker(
        markerId: MarkerId(point.geoPoint.toString()),
        position: LatLng(point.geoPoint.latitude, point.geoPoint.longitude),
        infoWindow: InfoWindow(
          title: "GeoJSON Point",
          snippet: "${point.geoPoint.latitude}, ${point.geoPoint.longitude}",
        ),
        onTap: () => _drawRoute(LatLng(point.geoPoint.latitude, point.geoPoint.longitude)),
      );
    }).toSet();

    setState(() {
      _markers.addAll(geoJsonMarkers);
    });

    geoJson.dispose();
  }

  void _drawRoute(LatLng destination) {
    if (_currentL == null) return;

    final Polyline route = Polyline(
      polylineId: PolylineId("route"),
      points: [_currentL!, destination],
      color: Colors.blue,
      width: 5,
    );

    setState(() {
      _polylines.clear(); // Clear any existing polylines
      _polylines.add(route); // Add the new route polyline
    });

    // Move the camera to show the route
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(
          _currentL!.latitude < destination.latitude ? _currentL!.latitude : destination.latitude,
          _currentL!.longitude < destination.longitude ? _currentL!.longitude : destination.longitude,
        ),
        northeast: LatLng(
          _currentL!.latitude > destination.latitude ? _currentL!.latitude : destination.latitude,
          _currentL!.longitude > destination.longitude ? _currentL!.longitude : destination.longitude,
        ),
      ),
      50.0,
    ));
  }
}
