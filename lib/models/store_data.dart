import 'package:phexchangestore/models/store.dart';

class StoreData {
  List<Store> _stores = [];

  void addStore(Store store) {
    _stores.add(store);
  }

  List<Store> getStores() {
    return _stores;
  }
}
