import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_provider.dart';

enum NetworkMode { online, degraded, offline }

final networkStatusControllerProvider =
    ChangeNotifierProvider<NetworkStatusController>((ref) {
      final controller = NetworkStatusController(
        connectivity: ref.watch(connectivityProvider),
        dio: ref.watch(dioProvider),
      );
      controller.start();
      return controller;
    });

class NetworkStatusController extends ChangeNotifier
    with WidgetsBindingObserver {
  NetworkStatusController({
    required Connectivity connectivity,
    required Dio dio,
  }) : _connectivity = connectivity,
       _dio = dio;

  final Connectivity _connectivity;
  final Dio _dio;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  NetworkMode mode = NetworkMode.degraded;
  int _generation = 0;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    _subscription = _connectivity.onConnectivityChanged.listen(check);
    await check(await _connectivity.checkConnectivity());
  }

  Future<void> check(List<ConnectivityResult> connectivity) async {
    final generation = ++_generation;
    if (connectivity.isEmpty ||
        connectivity.contains(ConnectivityResult.none)) {
      _setMode(NetworkMode.offline);
      return;
    }
    try {
      final response = await _dio.get<void>(
        '/student/offline/manifest',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (generation != _generation) return;
      final status = response.statusCode;
      _setMode(
        status != null && status >= 200 && status < 300
            ? NetworkMode.online
            : NetworkMode.degraded,
      );
    } catch (_) {
      if (generation == _generation) _setMode(NetworkMode.degraded);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _connectivity.checkConnectivity().then(check);
    }
  }

  void _setMode(NetworkMode value) {
    if (mode == value) return;
    mode = value;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }
}
