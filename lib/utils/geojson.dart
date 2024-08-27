import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:geojson/geojson.dart';


Future<List<GeoJsonPoint>> loadGeoJsonPoints() async {

  final String response = await rootBundle.loadString('assets/export.geojson');

 


  GeoJson geoJson = GeoJson();

  geoJson.processedPoints.listen((GeoJsonPoint point) {

    print('Processed point at ${point.geoPoint.latitude}, ${point.geoPoint.longitude}');

  });

  geoJson.endSignal.listen((_) => geoJson.dispose());


  await geoJson.parse(response);


  return geoJson.points;

}