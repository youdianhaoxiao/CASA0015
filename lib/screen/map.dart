import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geojson/geojson.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_routes/google_maps_routes.dart'; // 导入包
import 'package:recycle_app/screen/home.dart';

class mapPage extends StatefulWidget {
const mapPage({super.key});

@override
State<mapPage> createState() => _MapPageState();
}

class _MapPageState extends State<mapPage> {
Location _locationController = Location();
static const LatLng _pgoogle = LatLng(51.5074, -0.1278);

LatLng? _currentL = null;
Set<Marker> _markers = {};
GoogleMapController? _mapController;
late MapsRoutes route; // 实例化 MapsRoutes
final String googleApiKey = 'AIzaSyANkjGanrCgEMwuFCt1FJw_leNRoO_bd_M';

@override
void initState() {
super.initState();
route = MapsRoutes(); // 初始化 MapsRoutes
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
body: GoogleMap(
initialCameraPosition: CameraPosition(
target: _pgoogle,
zoom: 13,
),
markers: _markers,
polylines: route.routes, // 使用 route.routes 显示路线
onMapCreated: (GoogleMapController controller) {
_mapController = controller;
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
title: "Recycling Point",
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

Future<void> _drawRoute(LatLng destination) async {
if (_currentL == null) return;

List<LatLng> points = [
_currentL!,
destination,
];

await route.drawRoute(
points,
"Route to Marker", // 路线名称
Color.fromRGBO(84, 201, 105, 1), // 路线颜色
googleApiKey,
travelMode: TravelModes.driving, // 可以选择其他模式，如 walking, bicycling, transit
);

setState(() {});
}
}