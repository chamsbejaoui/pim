import 'dart:async';

import '../models/alert_model.dart';

class AlertService {
  AlertService._();

  static final AlertService instance = AlertService._();

  final StreamController<AlertModel> _controller =
      StreamController<AlertModel>.broadcast();

  Stream<AlertModel> get stream => _controller.stream;

  void emit(AlertModel alert) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(alert);
  }

  void dispose() {
    _controller.close();
  }
}
