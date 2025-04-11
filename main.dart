import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(GeoLocation());
}

class GeoLocation extends StatelessWidget {
  const GeoLocation({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyLocation());
  }
}

class MyLocation extends StatefulWidget {
  const MyLocation({super.key});

  @override
  State<MyLocation> createState() => _MyLocationState();
}

class _MyLocationState extends State<MyLocation> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  Set<Polyline> poly = {};
  List<LatLng> tap = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    gotoCurrentLocation();
  }

  void gotoLocation(LatLng position) {
    markers.clear();
    markers.add(
      Marker(
        markerId: MarkerId('$position'),
        position: position,
        infoWindow: InfoWindow(title: 'My Location'),
      ),
    );
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 12),
      ),
    );
    setState(() {});
  }

  void gotoCurrentLocation() async {
    if (!await checkLocationServicesPermission()) {
      return;
    }

    await Geolocator.getPositionStream().listen((geoPosition) {
      gotoLocation(LatLng(geoPosition.latitude, geoPosition.longitude));
    });
  }

  Future<bool> checkLocationServicesPermission() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location service disabled')));
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location service disabled')));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location service disabled')));
      return false;
    }
    return true;
  }

  void tapPolylines(LatLng position) {
    setState(() {
      if (tap.length == 2) {
        tap.clear();
        markers.clear();
        poly.clear();
      }
      tap.add(position);
      String label = tap.length == 1 ? 'Starting Point' : 'Ending Point';
      markers.add(
        Marker(
          markerId: MarkerId('$position'),
          position: position,
          infoWindow: InfoWindow(title: label),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            tap.length == 1
                ? BitmapDescriptor.hueBlue
                : BitmapDescriptor.hueGreen,
          ),
        ),
      );
      if (tap.length == 2) {
        poly.add(
          Polyline(
            polylineId: PolylineId('route'),
            points: tap,
            color: Colors.blue,
            width: 5,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: (controller) {
          mapController = controller;
        },
        polylines: poly,
        markers: markers,
        mapType: MapType.hybrid,
        mapToolbarEnabled: true,
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        zoomControlsEnabled: true,
        zoomGesturesEnabled: false,
        initialCameraPosition: CameraPosition(
          target: LatLng(15.987819233461288, 120.57323548269326),
          zoom: 10,
        ),
        onTap: tapPolylines,
      ),
    );
  }
}
