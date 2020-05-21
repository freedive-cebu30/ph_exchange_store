import 'package:google_maps_flutter/google_maps_flutter.dart';

class Store {
  String title;
  String content;
  String enTitle;
  String enContent;
  LatLng location;

  Store({
    this.title,
    this.content,
    this.enTitle,
    this.enContent,
    this.location,
  });
}
