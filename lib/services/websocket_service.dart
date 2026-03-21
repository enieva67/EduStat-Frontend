import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  final String _wsUrl = 'ws://127.0.0.1:8000/ws';
  final ValueNotifier<String?> serverError = ValueNotifier(null);
  // ValueNotifiers para actualizar la UI sin usar pesados setState()
  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  final ValueNotifier<String> serverStatus = ValueNotifier("Esperando conexión...");
// NUEVO: Buzón para guardar la respuesta de la clase didáctica
  final ValueNotifier<Map<String, dynamic>?> mathResult = ValueNotifier(null);
  // Patrón Singleton para usar la misma conexión en toda la app
  static final WebSocketService _instance = WebSocketService._internal();
   final ValueNotifier<Map<String, dynamic>?> fileData = ValueNotifier(null);
  factory WebSocketService() => _instance;
  WebSocketService._internal();

   Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      // LA MAGIA: Esperamos a que la conexión física se establezca totalmente
      await _channel!.ready;

      // Ahora sí, es seguro enviar el apretón de manos
      _sendDiagnostic();

      // Y escuchamos el flujo de datos
      _channel!.stream.listen(
        (message) {
          isConnected.value = true;
          _handleMessage(message);
        },
        onDone: () => _triggerReconnect(),
        onError: (error) => _triggerReconnect(),
      );
    } catch (e) {
      // Si el canal falla al estar 'ready' (ej. servidor apagado), caemos aquí
      _triggerReconnect();
    }
  }

// Cambia la firma de tus dos funciones para aceptar 'k'
  void pedirCalculo(String accion, List<double> datos, String contexto, {int k = 50}) {
    final payload = {
      "id": "calculo_01",
      "accion": accion,
      "parametros": {
        "datos": datos,
        "contexto": contexto,
        "k": k // ENVIAMOS LA K
      }
    };
    sendJson(payload);
  }

  void pedirCalculoAgrupado(String accion, List<Map<String, dynamic>> clases, String contexto, {int k = 50}) {
    final payload = {
      "id": "calculo_01",
      "accion": accion,
      "parametros": {
        "clases": clases,
        "contexto": contexto,
        "k": k // ENVIAMOS LA K
      }
    };
    sendJson(payload);
  }
  // NUEVA FUNCIÓN: Enviar archivo Excel/CSV a Python
  void procesarArchivo(String base64File, String nombreArchivo) {
    final payload = {
      "id": "upload_01",
      "accion": "procesar_archivo",
      "parametros": {
        "base64": base64File,
        "nombre": nombreArchivo
      }
    };
    sendJson(payload);
  }
  void _sendDiagnostic() {
    final handshakePayload = {
      "id": "init_01",
      "accion": "diagnostico",
      "parametros": {}
    };
    sendJson(handshakePayload);
  }

  void sendJson(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _handleMessage(String message) {
    try {
      final decoded = jsonDecode(message);
      
      // Defensivo: Verificar si es la respuesta de nuestro Handshake
      if (decoded['id'] == 'init_01' && decoded['estado'] == 'exito') {
        serverStatus.value = decoded['datos']['mensaje'] ?? "Conectado al Backend";
      }
       if (decoded['id'] == 'calculo_01' && decoded['estado'] == 'exito') {
        mathResult.value = decoded['datos']; 
      }
      if (decoded['id'] == 'upload_01' && decoded['estado'] == 'exito') {
        fileData.value = decoded['datos'];
      }
      // Aquí en el futuro agregaremos la redirección a los módulos de IA o Estadística
      if (decoded['id'] == 'calculo_01') {
        if (decoded['estado'] == 'exito') {
          mathResult.value = decoded['datos']; 
        } else if (decoded['estado'] == 'error') {
          // Si Python se queja, guardamos el insulto en el buzón
          serverError.value = decoded['datos']['mensaje'] ?? "Error desconocido en el servidor";
        }
      }
      
      // Hagamos lo mismo para el procesador de archivos por si suben un Excel roto
      if (decoded['id'] == 'upload_01') {
        if (decoded['estado'] == 'exito') {
          fileData.value = decoded['datos'];
        } else if (decoded['estado'] == 'error') {
          serverError.value = decoded['datos']['mensaje'];
        }
      }
    } catch (e) {
      debugPrint("Error al decodificar JSON del servidor: $e");
    }
  }

  void _triggerReconnect() {
    isConnected.value = false;
    serverStatus.value = "Desconectado. Reconectando en 2s...";
    
    // Evitamos acumular Timers
    _reconnectTimer?.cancel();
    
    // REGLA: Reconexión automática sin bloquear la UI
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      connect();
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
  }
}
