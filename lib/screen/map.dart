import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geojson/geojson.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_routes/google_maps_routes.dart'; 
import 'package:recycle_app/screen/home.dart';


class mapPage extends StatefulWidget {
  const mapPage({super.key});

  @override
  State<mapPage > createState() => _MapPageState();
}

class _MapPageState extends State<mapPage> {
  Location _locationController = Location();
  static const LatLng _pgoogle = LatLng(51.5074, -0.1278);

  LatLng? _currentL = null;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  late MapsRoutes route;
  final String googleApiKey = 'AIzaSyANkjGanrCgEMwuFCt1FJw_leNRoO_bd_M'; 

  @override
  void initState() {
    super.initState();
    route = MapsRoutes();
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
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pgoogle,
                zoom: 13,
              ),
              markers: _markers,
              polylines: route.routes,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _drawRoute(TravelModes.driving),
                  child: Text('Driving'),
                ),
                ElevatedButton(
                  onPressed: () => _drawRoute(TravelModes.bicycling),
                  child: Text('Bicycle'),
                ),
                ElevatedButton(
                  onPressed: () => _drawRoute(TravelModes.walking),
                  child: Text('Walking'),
                ),
              ],
            ),
          ),
        ],
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
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), 
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
          title: "Recycling Centre",
          snippet: "${point.geoPoint.latitude}, ${point.geoPoint.longitude}",
        ),
        onTap: () => _drawRoute(TravelModes.driving, LatLng(point.geoPoint.latitude, point.geoPoint.longitude)),
      );
    }).toSet();

    setState(() {
      _markers.addAll(geoJsonMarkers);
    });

    geoJson.dispose();
  }

  LatLng? _lastDestination;

  Future<void> _drawRoute(TravelModes travelMode, [LatLng? destination]) async {
    if (_currentL == null || (destination == null && _lastDestination == null)) return;

    _lastDestination = destination ?? _lastDestination;

    List<LatLng> points = [
      _currentL!,
      _lastDestination!,
    ];

    setState(() {
      route.routes.clear();

      route.drawRoute(
        points,
        "Route to Marker - $travelMode",  
       Color.fromRGBO(130, 78, 210, 1.0),  
        googleApiKey,
        travelMode: travelMode,
      ).then((_) {
        setState(() {
          route.routes = route.routes.map((polyline) {
            return polyline.copyWith(widthParam: 10);  
          }).toSet();
        });
      }).catchError((error) {
        print("Error drawing route: $error");
      });
    });
  }

}
