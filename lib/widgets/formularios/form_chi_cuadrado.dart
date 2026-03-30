import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/websocket_service.dart';

class FormChiCuadrado extends StatefulWidget {
  final String medidaSeleccionada; // Puede ser 'chi2_bondad' o 'chi2_independencia'

  const FormChiCuadrado({super.key, required this.medidaSeleccionada});

  @override
  State<FormChiCuadrado> createState() => _FormChiCuadradoState();
}

class _FormChiCuadradoState extends State<FormChiCuadrado> {
  final wsService = WebSocketService();

  // CONTROLADORES AISLADOS
  final TextEditingController _chi2BondadObsCtrl = TextEditingController(text: "30; 10; 20");
  final TextEditingController _chi2BondadEspCtrl = TextEditingController(); 
  
  bool _tengoTablaChi2 = true; 
  List<List<TextEditingController>> _matrizChi2 = [[TextEditingController(text: "15"), TextEditingController(text: "25")],[TextEditingController(text: "10"), TextEditingController(text: "30")],
  ];
  final TextEditingController _chi2IndepRawXCtrl = TextEditingController();
  final TextEditingController _chi2IndepRawYCtrl = TextEditingController();
  final TextEditingController _chi2AlfaCtrl = TextEditingController(text: "0.05");
  final ScrollController _scrollHorizontalCtrl = ScrollController();

  @override
  void dispose() {
    _chi2BondadObsCtrl.dispose();
    _chi2BondadEspCtrl.dispose();
    _chi2IndepRawXCtrl.dispose();
    _chi2IndepRawYCtrl.dispose();
    _chi2AlfaCtrl.dispose();
    _scrollHorizontalCtrl.dispose();
    for (var fila in _matrizChi2) {
      for (var ctrl in fila) { ctrl.dispose(); }
    }
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, backgroundColor: Colors.orange.shade800));
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

  void _addFilaChi2() => setState(() => _matrizChi2.add(List.generate(_matrizChi2[0].length, (index) => TextEditingController(text: "0"))));
  void _addColumnaChi2() => setState(() { for (var fila in _matrizChi2) { fila.add(TextEditingController(text: "0")); } });
  
  void _eliminarFilaChi2(int index) {
    if (_matrizChi2.length <= 2) { _mostrarMensaje("⚠️ Mínimo 2 filas."); return; }
    setState(() { for (var ctrl in _matrizChi2[index]) { ctrl.dispose(); } _matrizChi2.removeAt(index); });
  }

  void _eliminarColumnaChi2(int index) {
    if (_matrizChi2[0].length <= 2) { _mostrarMensaje("⚠️ Mínimo 2 columnas."); return; }
    setState(() { for (var fila in _matrizChi2) { fila[index].dispose(); fila.removeAt(index); } });
  }

  void _limpiarMatrizChi2() => setState(() { for (var fila in _matrizChi2) { for (var ctrl in fila) { ctrl.text = ""; } } });

  Future<void> _pegarMatrizExcelChi2() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) return;

    List<String> lineas = data.text!.trim().split('\n');
    List<List<double>> matrizParseada =[];

    for (String linea in lineas) {
      if (linea.trim().isEmpty) continue;
      List<String> celdas = linea.split(RegExp(r'[\t;]')); 
      List<double> filaNumeros =[];
      for (String celda in celdas) {
        double? val = double.tryParse(celda.replaceAll(',', '.').trim());
        if (val != null) filaNumeros.add(val);
      }
      if (filaNumeros.isNotEmpty) matrizParseada.add(filaNumeros);
    }

    if (matrizParseada.length >= 2 && matrizParseada[0].length >= 2) {
      int cols = matrizParseada[0].length;
      if (!matrizParseada.every((fila) => fila.length == cols)) { _mostrarMensaje("❌ Error: Matriz irregular."); return; }
      for (var fila in _matrizChi2) { for (var ctrl in fila) { ctrl.dispose(); } }
      setState(() { _matrizChi2 = matrizParseada.map((fila) => fila.map((val) => TextEditingController(text: val.toString().replaceAll('.0', ''))).toList()).toList(); });
      _mostrarMensaje("✨ ¡Excel Pegado! Matriz ${matrizParseada.length}x$cols lista.");
    } else {
      _mostrarMensaje("❌ Error: Copia al menos 2 filas y 2 columnas con números.");
    }
  }

  void _enviarChi2Bondad() {
    List<double> obs = _extraerNumeros(_chi2BondadObsCtrl.text);
    if (obs.length < 2) { _mostrarMensaje("❌ Error: Al menos 2 frecuencias observadas."); return; }
    List<double> esp = _extraerNumeros(_chi2BondadEspCtrl.text);
    double? alfa = double.tryParse(_chi2AlfaCtrl.text.replaceAll(',', '.'));
    wsService.sendJson({"id": "calculo_01", "accion": "calcular_chi2_bondad", "parametros": {"datos": obs, "esperadas": esp.isNotEmpty ? esp : null, "tipo_ingreso": "frecuencias", "alfa": alfa ?? 0.05}});
  }

  void _enviarChi2Independencia() {
    double? alfa = double.tryParse(_chi2AlfaCtrl.text.replaceAll(',', '.'));
    if (_tengoTablaChi2) {
      final List<List<double>> matrizFinal = List.empty(growable: true);
      for (int i = 0; i < _matrizChi2.length; i++) {
        final List<double> filaNumeros = List.empty(growable: true);
        for (int j = 0; j < _matrizChi2[i].length; j++) {
          String t = _matrizChi2[i][j].text.trim();
          if (t.isEmpty) { _mostrarMensaje("❌ Celda vacía (Fila ${i+1}, Col ${j+1})."); return; }
          double? val = double.tryParse(t.replaceAll(',', '.'));
          if (val == null) { _mostrarMensaje("❌ Valor inválido (Fila ${i+1}, Col ${j+1})."); return; }
          filaNumeros.add(val);
        }
        matrizFinal.add(filaNumeros);
      }
      wsService.sendJson({"id": "calculo_01", "accion": "calcular_chi2_independencia", "parametros": { "matriz": matrizFinal, "tipo_ingreso": "tabla", "alfa": alfa ?? 0.05 }});
    } else {
      List<String> rawX = _chi2IndepRawXCtrl.text.split(RegExp(r'[\n;,]')).map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
      List<String> rawY = _chi2IndepRawYCtrl.text.split(RegExp(r'[\n;,]')).map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
      if (rawX.isEmpty || rawX.length != rawY.length || rawX.length < 4) { _mostrarMensaje("❌ Error con los datos sueltos. Verifica la cantidad."); return; }
      wsService.sendJson({"id": "calculo_01", "accion": "calcular_chi2_independencia", "parametros": { "raw_x": rawX, "raw_y": rawY, "tipo_ingreso": "datos_sueltos", "alfa": alfa ?? 0.05 }});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.medidaSeleccionada == 'chi2_bondad') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          const Text("Ji-Cuadrado: Bondad de Ajuste (1 Variable)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 15),
          TextField(controller: _chi2AlfaCtrl, decoration: const InputDecoration(labelText: "Nivel de Significancia (Alfa)", prefixIcon: Icon(Icons.warning), border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 15),
          const Text("Ingresa las frecuencias separadas por punto y coma (;):", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextField(controller: _chi2BondadObsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Frecuencias Observadas (O) - Obligatorio", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
          const SizedBox(height: 10),
          TextField(controller: _chi2BondadEspCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Frecuencias Esperadas (E) - Opcional (Vacío = Equiprobable)", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.casino), label: const Padding(padding: EdgeInsets.all(12.0), child: Text("Evaluar Bondad de Ajuste", style: TextStyle(fontSize: 16))), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white), onPressed: _enviarChi2Bondad))
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          const Text("Ji-Cuadrado: Independencia (2 Variables)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 15),
          TextField(controller: _chi2AlfaCtrl, decoration: const InputDecoration(labelText: "Nivel de Significancia (Alfa)", prefixIcon: Icon(Icons.warning), border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 15),
          Row(
            children:[
              const Text("¿Qué dato tienes?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(width: 10),
              Switch(value: _tengoTablaChi2, activeThumbColor: Colors.teal, onChanged: (val) => setState(() => _tengoTablaChi2 = val)),
              Text(_tengoTablaChi2 ? "Tabla Resumida" : "Datos Sueltos", style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          
          if (_tengoTablaChi2) ...[
            const Text("Tabla de Frecuencias (Observadas):", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 10),
            Scrollbar(
              controller: _scrollHorizontalCtrl, thumbVisibility: true, trackVisibility: true, thickness: 8, radius: const Radius.circular(10),
              child: SingleChildScrollView(
                controller: _scrollHorizontalCtrl, scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Row(
                      children:[
                        ...List.generate(_matrizChi2[0].length, (cIndex) => Container(width: 80, margin: const EdgeInsets.only(right: 8, bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("Col ${cIndex + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), if (_matrizChi2[0].length > 2) InkWell(onTap: () => _eliminarColumnaChi2(cIndex), child: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 16))]))),
                        const SizedBox(width: 40),
                      ],
                    ),
                    ...List.generate(_matrizChi2.length, (rIndex) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(children:[...List.generate(_matrizChi2[rIndex].length, (cIndex) => Container(width: 80, margin: const EdgeInsets.only(right: 8), child: TextField(controller: _matrizChi2[rIndex][cIndex], textAlign: TextAlign.center, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8), filled: true, fillColor: Colors.white)))), if (_matrizChi2.length > 2) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _eliminarFilaChi2(rIndex)) else const SizedBox(width: 48)]))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: Wrap(
                spacing: 10, runSpacing: 10, alignment: WrapAlignment.spaceBetween,
                children:[
                  Row(mainAxisSize: MainAxisSize.min, children:[TextButton.icon(onPressed: _addFilaChi2, icon: const Icon(Icons.add, color: Colors.teal), label: const Text("Fila", style: TextStyle(color: Colors.teal))), TextButton.icon(onPressed: _addColumnaChi2, icon: const Icon(Icons.add, color: Colors.deepPurple), label: const Text("Columna", style: TextStyle(color: Colors.deepPurple)))]),
                  Row(mainAxisSize: MainAxisSize.min, children:[Tooltip(message: "Pegar Excel", child: TextButton.icon(onPressed: _pegarMatrizExcelChi2, icon: const Icon(Icons.content_paste, color: Colors.blueAccent), label: const Text("Pegar", style: TextStyle(color: Colors.blueAccent)))), IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: _limpiarMatrizChi2)]),
                ],
              ),
            ),
          ] else ...[
            const Text("Ingresa los datos paciente por paciente:", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 5),
            TextField(controller: _chi2IndepRawXCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Columna Variable X", hintText: "Ej: Mujer, Hombre, Mujer...", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
            const SizedBox(height: 10),
            TextField(controller: _chi2IndepRawYCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Columna Variable Y", hintText: "Ej: Fuma, No, No...", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
          ],

          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.grid_on), label: const Padding(padding: EdgeInsets.all(12.0), child: Text("Analizar Independencia", style: TextStyle(fontSize: 16))), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white), onPressed: _enviarChi2Independencia))
        ],
      );
    }
  }
}
