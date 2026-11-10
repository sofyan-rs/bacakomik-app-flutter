import 'package:yoru/core/network/network_info.dart';

class FakeNetworkInfo implements NetworkInfo {
  FakeNetworkInfo({this.connected = true});

  bool connected;

  @override
  Future<bool> get isConnected async => connected;
}
