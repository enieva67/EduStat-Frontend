import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/websocket_service.dart';

class FormComparacion extends StatefulWidget {
  final String medidaSeleccionada; 
  final String titulo;             

  const FormComparacion({super.key, required this.medidaSeleccionada, required this.titulo});

  @override
  State<FormComparacion> createState() => _FormComparacionState();
}

class _FormComparacionState extends State<FormComparacion> {
  final wsService = WebSocketService();

  // CONTROLADORES
  final TextEditingController _nombreACtrl = TextEditingController(text: "Tratamiento A");
  final TextEditingController _nombreBCtrl = TextEditingController(text: "Tratamiento B");
  
  // Para T-Test y Mann-Whitney
  final TextEditingController _datosACtrl = TextEditingController(text: "12; 15; 14; 10; 18");
  final TextEditingController _datosBCtrl = TextEditingController(text: "10; 9; 12; 8; 11; 10");
  
  // Para Prueba Z de Proporciones
  final TextEditingController _exitosACtrl = TextEditingController(text: "45");
  final TextEditingController _naCtrl = TextEditingController(text: "100");
  final TextEditingController _exitosBCtrl = TextEditingController(text: "30");
  final TextEditingController _nbCtrl = TextEditingController(text: "100");

  final TextEditingController _alfaCtrl = TextEditingController(text: "0.05");
  String _tipoPrueba = 'dos_colas';

  @override
  void dispose() {
    _nombreACtrl.dispose(); _nombreBCtrl.dispose();
    _datosACtrl.dispose(); _datosBCtrl.dispose();
    _exitosACtrl.dispose(); _naCtrl.dispose(); _exitosBCtrl.dispose(); _nbCtrl.dispose();
    _alfaCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, backgroundColor: Colors.indigo.shade800));
  }

  List<double> _extraerNumeros(String rawText) {
    List<String> rawItems = rawText.split(RegExp(r'[\n\t;\s]+'));
    final List<double> datosLimpios = List.empty(growable: true);
    for (String item in rawItems) {
      if (item.trim().isEmpty) continue;
      double? val = double.tryParse(item.replaceAll(',', '.'));
      if (val != null) datosLimpios.add(val);
    }
    return datosLimpios;
  }

  Future<void> _pegarDatosGrupos() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;

    final List<double> listA = List.empty(growable: true);
    final List<double> listB = List.empty(growable: true);
    List<String> lineas = data.text!.trim().split('\n');

    for (String linea in lineas) {
      List<String> celdas = linea.split(RegExp(r'[\t;]'));
      if (celdas.isNotEmpty) {
        double? valA = double.tryParse(celdas[0].replaceAll(',', '.').trim());
        if (valA != null) listA.add(valA);
        if (celdas.length > 1) {
          double? valB = double.tryParse(celdas[1].replaceAll(',', '.').trim());
          if (valB != null) listB.add(valB);
        }
      }
    }

    if (listA.isNotEmpty || listB.isNotEmpty) {
      setState(() {
        _datosACtrl.text = listA.join('; ');
        _datosBCtrl.text = listB.join('; ');
      });
      _mostrarMensaje("✨ ¡Éxito! Se pegaron ${listA.length} datos en A y ${listB.length} en B.");
    } else {
      _mostrarMensaje("❌ Error: No se detectaron columnas numéricas.");
    }
  }

  void _enviarPrueba() {
    double? alfa = double.tryParse(_alfaCtrl.text.replaceAll(',', '.'));
    if (alfa == null) { _mostrarMensaje("❌ Verifica el valor de Alfa."); return; }

    final baseParams = {
      "alfa": alfa, "tipo_prueba": _tipoPrueba,
      "ctx_a": _nombreACtrl.text, "ctx_b": _nombreBCtrl.text
    };

    if (widget.medidaSeleccionada == 'z_proporciones') {
      int? eA = int.tryParse(_exitosACtrl.text); int? nA = int.tryParse(_naCtrl.text);
      int? eB = int.tryParse(_exitosBCtrl.text); int? nB = int.tryParse(_nbCtrl.text);
      if (eA == null || nA == null || eB == null || nB == null) {
        _mostrarMensaje("❌ Ingresa números enteros válidos para las proporciones."); return;
      }
      baseParams.addAll({"exitos_a": eA, "n_a": nA, "exitos_b": eB, "n_b": nB});
    } else {
      List<double> listA = _extraerNumeros(_datosACtrl.text);
      List<double> listB = _extraerNumeros(_datosBCtrl.text);
      if (listA.length < 2 || listB.length < 2) {
        _mostrarMensaje("❌ Cada grupo debe tener al menos 2 datos."); return;
      }
      setState(() { _datosACtrl.text = listA.join('; '); _datosBCtrl.text = listB.join('; '); });
      baseParams.addAll({"datos_a": listA, "datos_b": listB});
    }

    wsService.sendJson({ "id": "calculo_01", "accion": "calcular_${widget.medidaSeleccionada}", "parametros": baseParams });
  }

  @override
  Widget build(BuildContext context) {
    bool esProporcion = widget.medidaSeleccionada == 'z_proporciones';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text("Comparación: ${widget.titulo}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        const SizedBox(height: 15),
        
        Row(
          children:[
            Expanded(child: TextField(controller: _nombreACtrl, decoration: const InputDecoration(labelText: "Nombre Grupo A", prefixIcon: Icon(Icons.people), border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _nombreBCtrl, decoration: const InputDecoration(labelText: "Nombre Grupo B", prefixIcon: Icon(Icons.people_outline), border: OutlineInputBorder(), isDense: true))),
          ],
        ),
        const SizedBox(height: 15),

        // UI CONDICIONAL
        if (esProporcion) ...[
          const Text("Ingresa los datos de las proporciones:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children:[
              Expanded(child: TextField(controller: _exitosACtrl, decoration: const InputDecoration(labelText: "Éxitos Grupo A", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _naCtrl, decoration: const InputDecoration(labelText: "Total (n) Grupo A", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children:[
              Expanded(child: TextField(controller: _exitosBCtrl, decoration: const InputDecoration(labelText: "Éxitos Grupo B", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _nbCtrl, decoration: const InputDecoration(labelText: "Total (n) Grupo B", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white))),
            ],
          ),
        ] else ...[
          TextField(controller: _datosACtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Datos del Grupo A", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
          const SizedBox(height: 10),
          TextField(controller: _datosBCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Datos del Grupo B", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, alignment: WrapAlignment.end,
            children:[
              Tooltip(message: "Copia 2 columnas en Excel", child: TextButton.icon(onPressed: _pegarDatosGrupos, icon: const Icon(Icons.content_paste, color: Colors.blueAccent), label: const Text("Pegar 2 Columnas"))),
              TextButton.icon(onPressed: () { _datosACtrl.clear(); _datosBCtrl.clear(); }, icon: const Icon(Icons.clear, color: Colors.redAccent), label: const Text("Limpiar")),
            ],
          ),
        ],

        const SizedBox(height: 15),
        Row(
          children:[
            Expanded(child: TextField(controller: _alfaCtrl, decoration: const InputDecoration(labelText: "Alfa (α)", prefixIcon: Icon(Icons.warning), border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true, value: _tipoPrueba,
                    icon: const Icon(Icons.alt_route, color: Colors.blueAccent),
                    items: const[
                      DropdownMenuItem(value: 'dos_colas', child: Text("Dos Colas (Dif: ≠)")),
                      DropdownMenuItem(value: 'cola_der', child: Text("Cola Derecha (A > B)")),
                      DropdownMenuItem(value: 'cola_izq', child: Text("Cola Izquierda (A < B)")),
                    ],
                    onChanged: (val) { if (val != null) setState(() => _tipoPrueba = val); },
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.compare_arrows),
            label: const Padding(padding: EdgeInsets.all(12.0), child: Text("Analizar Diferencias", style: TextStyle(fontSize: 16))),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.shade700, foregroundColor: Colors.white, elevation: 3),
            onPressed: _enviarPrueba,
          ),
        )
      ],
    );
  }
}