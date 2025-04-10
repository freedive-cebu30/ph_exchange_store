import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:package_info/package_info.dart';
import 'package:permission_handler/permission_handler.dart' as per_handler;
import 'package:phexchangestore/models/store.dart';
import 'package:phexchangestore/models/store_data.dart';

import 'constant.dart';
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

class ExchangeShopApp extends StatefulWidget {
  @override
  _ExchangeShopAppState createState() => _ExchangeShopAppState();
}

class _ExchangeShopAppState extends State<ExchangeShopApp> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );
  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            I18n.of(context).title,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: MapCebu(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                I18n.of(context).title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
            ListTile(
              title: Text(I18n.of(context).license),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: I18n.of(context).title,
                  applicationVersion: _packageInfo.version,
                );
              },
            ),
          ],
        ),
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
    setStores();

    FirebaseAdMob.instance.initialize(appId: kAppId);
//    FirebaseAdMob.instance.initialize(appId: FirebaseAdMob.testAppId);
    BannerAd _bannerAd = _createBannerAd();
    _bannerAd
      ..load()
      ..show(
        anchorOffset: 20.0,
      );

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
          top: 310.0,
          bottom: 90,
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

  void setStores() async {
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
      if (e.code == 'PERMISSION_DENIED')
        error = 'Permission denited';
      else if (e.code == 'PERMISSION_DENITED_NEVER_ASK')
        error =
            'Permission denited - please ask the user to enable it from the app settings';
      bool isShown =
          await per_handler.Permission.contacts.shouldShowRequestRationale;
      if (isShown == false) {
        per_handler.openAppSettings();
        sleep(new Duration(seconds: 2));
      }
      // 位置情報の権限がない場合は、アプリを使えない仕様にする
      exit(0);
    }

    setState(() {
      currentLocation = myLocation;
    });
  }

  BannerAd _createBannerAd() {
    return new BannerAd(
      adUnitId: kAdUnitId,
//      adUnitId: BannerAd.testAdUnitId,
      size: AdSize.banner,
      targetingInfo: _targetingInfo,
    );
  }

  MobileAdTargetingInfo _targetingInfo = new MobileAdTargetingInfo(
    keywords: <String>[
      'travel',
      'philippines',
    ],
  );
}
