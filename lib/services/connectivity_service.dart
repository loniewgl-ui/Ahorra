// lib/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamController<ConnectivityResult>? _streamController;
  static ConnectivityResult _currentConnection = ConnectivityResult.none;
  static bool _isInitialized = false;

  static Stream<ConnectivityResult> get connectivityStream {
    if (!_isInitialized) {
      _initializeConnectivity();
    }
    return _streamController!.stream;
  }

  static ConnectivityResult get currentConnection => _currentConnection;

  static Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static void _initializeConnectivity() {
    if (_isInitialized) return;
    
    _streamController = StreamController<ConnectivityResult>.broadcast();
    _isInitialized = true;

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _currentConnection = result;
      if (_streamController != null && !_streamController!.isClosed) {
        _streamController!.add(result);
      }
    });

    // Check initial connectivity
    _connectivity.checkConnectivity().then((ConnectivityResult result) {
      _currentConnection = result;
      if (_streamController != null && !_streamController!.isClosed) {
        _streamController!.add(result);
      }
    });
  }

  static void dispose() {
    if (_streamController != null) {
      _streamController!.close();
      _streamController = null;
    }
    _isInitialized = false;
  }
}
