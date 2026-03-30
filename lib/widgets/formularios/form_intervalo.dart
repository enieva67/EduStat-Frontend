import 'package:flutter/material.dart';
import '../../services/websocket_service.dart';

class FormIntervalo extends StatefulWidget {
  const FormIntervalo({super.key});

  @override
  State<FormIntervalo> createState() => _FormIntervaloState();
}

class _FormIntervaloState extends State<FormIntervalo> {
  final wsService = WebSocketService();

  // CONTROLADORES AISLADOS
  final TextEditingController _icMediaCtrl = TextEditingController(text: "105.5");
  final TextEditingController _icDesvCtrl = TextEditingController(text: "15.0");
  final TextEditingController _icNCtrl = TextEditingController(text: "25");
  String _icConfianza = '95.0';

  @override
  void dispose() {
    _icMediaCtrl.dispose();
    _icDesvCtrl.dispose();
    _icNCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, backgroundColor: Colors.teal.shade800)
    );
  }

  void _enviarIntervaloConfianza() {
    double? media = double.tryParse(_icMediaCtrl.text.replaceAll(',', '.'));
    double? desviacion = double.tryParse(_icDesvCtrl.text.replaceAll(',', '.'));
    int? n = int.tryParse(_icNCtrl.text);

    if (media == null || desviacion == null || n == null) {
      _mostrarMensaje("❌ Error: Ingresa números válidos en todos los campos.");
      return;
    }

    final payload = {
      "id": "calculo_01",
      "accion": "calcular_intervalo_confianza",
      "parametros": {
        "media": media, "desviacion": desviacion, "n": n, "confianza": double.parse(_icConfianza)
      }
    };
    wsService.sendJson(payload);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text("Intervalo de Confianza (Media)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 15),
        
        TextField(controller: _icMediaCtrl, decoration: const InputDecoration(labelText: "Media Muestral (x̄)", prefixIcon: Icon(Icons.balance), border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 10),
        TextField(controller: _icDesvCtrl, decoration: const InputDecoration(labelText: "Desviación Estándar (s o σ)", prefixIcon: Icon(Icons.compare_arrows), border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 10),
        TextField(controller: _icNCtrl, decoration: const InputDecoration(labelText: "Tamaño de Muestra (n)", prefixIcon: Icon(Icons.group), border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 15),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true, value: _icConfianza,
              icon: const Icon(Icons.security, color: Colors.teal),
              items: const[
                DropdownMenuItem(value: '90.0', child: Text("Nivel de Confianza: 90%")),
                DropdownMenuItem(value: '95.0', child: Text("Nivel de Confianza: 95% (Estándar)")),
                DropdownMenuItem(value: '99.0', child: Text("Nivel de Confianza: 99% (Estricto)")),
              ],
              onChanged: (val) { if (val != null) setState(() => _icConfianza = val); },
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.psychology),
            label: const Padding(padding: EdgeInsets.all(12.0), child: Text("Calcular Intervalo de Confianza", style: TextStyle(fontSize: 16))),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 3),
            onPressed: _enviarIntervaloConfianza,
          ),
        )
      ],
    );
  }
}
