import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Network connectivity checker
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectionChange;
}

class NetworkInfoImpl implements NetworkInfo {

  NetworkInfoImpl(this._connectionChecker);
  final InternetConnectionChecker _connectionChecker;

  @override
  Future<bool> get isConnected => _connectionChecker.hasConnection;

  @override
  Stream<bool> get onConnectionChange => _connectionChecker.onStatusChange.map(
    (status) => status == InternetConnectionStatus.connected,
  );
}

class WebNetworkInfoImpl implements NetworkInfo {
  const WebNetworkInfoImpl();

  @override
  Future<bool> get isConnected => Future.value(true);

  @override
  Stream<bool> get onConnectionChange => Stream.value(true);
}