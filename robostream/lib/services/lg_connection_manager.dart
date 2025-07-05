import 'package:dartssh2/dartssh2.dart';
import 'kml_builder.dart';
import 'kml_sender.dart';
import 'slave_calculator.dart';

/// Manages SSH connections and authentication for Liquid Galaxy
class LGConnectionManager {
  final String _host;
  final String _username;
  final String _password;
  final int _totalScreens;
  
  SSHClient? _client;
  KMLBuilder? _kmlBuilder;
  KMLSender? _kmlSender;
  SlaveCalculator? _slaveCalculator;

  LGConnectionManager({
    required String host,
    required String username,
    required String password,
    required int totalScreens,
  })  : _host = host,
        _username = username,
        _password = password,
        _totalScreens = totalScreens;

  // Essential getters only
  String get host => _host;
  SSHClient? get client => _client;
  KMLBuilder? get kmlBuilder => _kmlBuilder;
  KMLSender? get kmlSender => _kmlSender;
  bool get isConnected => _client != null;

  /// Establishes SSH connection and initializes services
  Future<bool> connect() async {
    try {
      final socket = await SSHSocket.connect(_host, 22);
      _client = SSHClient(
        socket,
        username: _username,
        onPasswordRequest: () => _password,
      );
      
      if (_client == null) return false;
      
      await _client!.run('echo "Connection successful"');
      
      _slaveCalculator = SlaveCalculator(totalScreens: _totalScreens);
      _kmlBuilder = KMLBuilder(lgHost: _host);
      _kmlSender = KMLSender(client: _client!, slaveCalculator: _slaveCalculator!);
      
      return true;
    } catch (e) {
      _client?.close();
      _client = null;
      _kmlBuilder = null;
      _kmlSender = null;
      return false;
    }
  }

  /// Disconnects from SSH and cleans up resources
  void disconnect() {
    _client?.close();
    _client = null;
    _kmlBuilder = null;
    _kmlSender = null;
  }
}
