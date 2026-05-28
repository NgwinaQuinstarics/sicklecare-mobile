import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {

  static final Connectivity _connectivity = Connectivity();

  /// CHECK INTERNET
  static Future<bool> hasInternet() async {

    final result = await _connectivity.checkConnectivity();

    return !result.contains(ConnectivityResult.none);
  }

  /// INTERNET STREAM
  static Stream<List<ConnectivityResult>> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }
}