import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:phexchangestore/models/store.dart';
import 'package:phexchangestore/models/store_data.dart';

import 'i18n.dart';
import 'i18n_delegate.dart';

final _firestore = Firestore.instance;
Completer<GoogleMapController> _controller = Completer();

void main() {
  runApp(
    ExchangeShop(),
  );
}

class ExchangeShop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        const I18nDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale("en", "US"),
        const Locale("ja", "JP"),
      ],
      home: ExchangeShopApp(),
    );
  }
}

class ExchangeShopApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(I18n.of(context).title)),
      ),
      body: MapCebu(),
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
    Locale _locale = Localizations.localeOf(context);
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
          _createMarker(_locale),
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }

  Set<Marker> _createMarker(Locale locale) {
    Set<Marker> markers = {};

    storeData.getStores().asMap().forEach((i, store) {
      String _title;
      String _content;
      if (locale.toString() == 'ja_JP') {
        _title = store.title;
        _content = store.content;
      } else {
        _title = store.enTitle;
        _content = store.enContent;
      }

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
                  title: new Text(_title),
                  content: new Text(_content),
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
      storeData.addStore(
        Store(
          title: store.data['title'],
          content: store.data['content'],
          enTitle: store.data['en_title'],
          enContent: store.data['en_content'],
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
