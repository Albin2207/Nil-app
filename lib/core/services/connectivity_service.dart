import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  
  bool get isOnline => _isOnline;

  ConnectivityService() {
    _init();
  }

  void _init() {
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final wasOnline = _isOnline;
      _isOnline = results.isNotEmpty && 
                  results.any((result) => 
                    result != ConnectivityResult.none);
      
      // Only notify if state changed
      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    });

    // Check initial connectivity
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = results.isNotEmpty && 
                  results.any((result) => 
                    result != ConnectivityResult.none);
      notifyListeners();
    } catch (e) {
      print('Error checking connectivity: $e');
      _isOnline = true; // Assume online if check fails
    }
  }

  // Manual refresh method
  Future<void> refresh() async {
    await _checkConnectivity();
  }
}

