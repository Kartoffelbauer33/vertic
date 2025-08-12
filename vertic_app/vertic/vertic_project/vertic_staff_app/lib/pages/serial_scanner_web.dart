// Web-Stub: Auf Web gibt es keinen direkten Zugriff auf serielle Ports
// Diese Implementierung liefert leere Daten und verhindert Build-Fehler

class SerialScanner {
  final Function(String) onDataReceived;
  SerialScanner({required this.onDataReceived});

  List<String> getAvailablePorts() => const [];
  bool connect(String portName, {int baudRate = 9600}) => false;
  Future<bool> autoConnectWithBaudRateDetection(String portName) async => false;
  void disconnect() {}

  bool get isConnected => false;
  String get currentPort => '';
}



