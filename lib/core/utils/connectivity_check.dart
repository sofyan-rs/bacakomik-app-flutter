import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityCheck {
  Future<bool> checkStatus() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    // print(connectivityResult);

    return !connectivityResult.contains(ConnectivityResult.none);
  }
}
