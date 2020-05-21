import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:phexchangestore/models/store.dart';
import 'package:phexchangestore/models/store_data.dart';

final _firestore = Firestore.instance;
Completer<GoogleMapController> _controller = Completer();

void main() {
  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('フィリピンの両替所'),
          ),
        ),
        body: MapCebu(),
      ),
    );
  }
}

class MapCebu extends StatefulWidget {
  @override
  State<MapCebu> createState() => MapCebuState();
}

class MapCebuState extends State<MapCebu> {
  LocationData currentLocation;
  Location _locationService = Location();
  String error;
  BitmapDescriptor pinLocationIcon;
  StoreData storeData = StoreData();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    setCustomMapPin();
    getStores();

    _locationService.onLocationChanged.listen((LocationData result) async {
      setState(() {
        currentLocation = result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            currentLocation.latitude,
            currentLocation.longitude,
          ),
          bearing: 30,
          zoom: 13.4746,
        ),
        compassEnabled: false,
        myLocationEnabled: true,
        padding: EdgeInsets.only(
          top: 400.0,
        ),
        markers: Set.from(
          _createMarker(),
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }

  Set<Marker> _createMarker() {
    Set<Marker> markers = {};

    storeData.getStores().asMap().forEach((i, store) {
      markers.add(
        Marker(
          markerId: MarkerId('myMarker$i'),
          position: store.location,
          icon: (pinLocationIcon),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: new Text(store.title),
                  content: new Text(store.content),
                );
              },
            );
          },
        ),
      );
    });

    return markers;
  }

  void getStores() async {
    final stores = await _firestore.collection('stores').getDocuments();
    for (var store in stores.documents) {
      double latitude = store.data['location'].latitude;
      double longitude = store.data['location'].longitude;
      String title = store.data['title'];
      String content = store.data['content'];
      storeData.addStore(
        Store(
          title: title,
          content: content,
          location: LatLng(latitude, longitude),
        ),
      );
    }
  }

  void setCustomMapPin() async {
    pinLocationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 1), 'assets/money.png');
  }

  void initPlatformState() async {
    LocationData myLocation;
    try {
      myLocation = await _locationService.getLocation();
    } catch (e) {
      if (e.code == 'PERMISSION_DENITED')
        error = 'Permission denited';
      else if (e.code == 'PERMISSION_DENITED_NEVER_ASK')
        error =
            'Permission denited - please ask the user to enable it from the app settings';
      myLocation = null;
    }
    setState(() {
      currentLocation = myLocation;
    });
  }
}
