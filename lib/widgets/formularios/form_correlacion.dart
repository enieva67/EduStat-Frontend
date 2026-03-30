import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/websocket_service.dart';

class FormCorrelacion extends StatefulWidget {
  final String medidaSeleccionada; // Ej: 'pearson', 'spearman'
  final String titulo;             // Ej: 'r de Pearson (Paramétrica)'

  const FormCorrelacion({
    super.key, 
    required this.medidaSeleccionada,
    required this.titulo,
  });

  @override
  State<FormCorrelacion> createState() => _FormCorrelacionState();
}

class _FormCorrelacionState extends State<FormCorrelacion> {
  final wsService = WebSocketService();

  // 1. CONTROLADORES AISLADOS
  final TextEditingController _bivNombreXCtrl = TextEditingController(text: "Horas Estudio");
  final TextEditingController _bivNombreYCtrl = TextEditingController(text: "Calificación");
  final TextEditingController _bivDatosXCtrl = TextEditingController(text: "2; 4; 5; 8; 10");
  final TextEditingController _bivDatosYCtrl = TextEditingController(text: "40; 60; 65; 85; 95");

  @override
  void dispose() {
    _bivNombreXCtrl.dispose();
    _bivNombreYCtrl.dispose();
    _bivDatosXCtrl.dispose();
    _bivDatosYCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, backgroundColor: Colors.indigo.shade800)
    );
  }

  // 2. EL FILTRO NINJA (Propio de este formulario)
  List<double> _extraerNumeros(String rawText) {
    List<String> rawItems = rawText.split(RegExp(r'[\n\t;\s]+'));
    final List<double> datosLimpios = List.empty(growable: true);

    for (String item in rawItems) {
      if (item.trim().isEmpty) continue;
      String sanitized = item.replaceAll(',', '.');
      double? val = double.tryParse(sanitized);
      if (val != null) datosLimpios.add(val);
    }
    return datosLimpios;
  }

  // 3. PEGADO INTELIGENTE BIVARIADO
  Future<void> _pegarDatosBivariados() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;

    final List<double> listX = List.empty(growable: true);
    final List<double> listY = List.empty(growable: true);
    
    List<String> lineas = data.text!.trim().split('\n');

    for (String linea in lineas) {
      List<String> celdas = linea.split(RegExp(r'[\t;]'));
      if (celdas.length >= 2) {
        double? x = double.tryParse(celdas[0].replaceAll(',', '.').trim());
        double? y = double.tryParse(celdas[1].replaceAll(',', '.').trim());
        if (x != null && y != null) {
          listX.add(x);
          listY.add(y);
        }
      }
    }

    if (listX.isNotEmpty) {
      setState(() {
        _bivDatosXCtrl.text = listX.join('; ');
        _bivDatosYCtrl.text = listY.join('; ');
      });
      _mostrarMensaje("✨ ¡Éxito! Se pegaron ${listX.length} pares de datos.");
    } else {
      _mostrarMensaje("❌ Error: No se detectaron 2 columnas numéricas juntas.");
    }
  }

  // 4. FUNCIÓN DE ENVÍO
  void _enviarCorrelacion() {
    List<double> xList = _extraerNumeros(_bivDatosXCtrl.text);
    List<double> yList = _extraerNumeros(_bivDatosYCtrl.text);

    if (xList.length != yList.length || xList.length < 2) {
      _mostrarMensaje("❌ Error: X e Y deben tener la misma cantidad de números (Mínimo 2).");
      return;
    }

    setState(() {
      _bivDatosXCtrl.text = xList.join('; ');
      _bivDatosYCtrl.text = yList.join('; ');
    });

    final payload = {
      "id": "calculo_01",
      "accion": "calcular_${widget.medidaSeleccionada}", // USAMOS LA VARIABLE DEL PADRE
      "parametros": {
        "x": xList, "y": yList,
        "ctx_x": _bivNombreXCtrl.text, "ctx_y": _bivNombreYCtrl.text
      }
    };
    wsService.sendJson(payload);
  }

  // 5. INTERFAZ GRÁFICA AISLADA
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text("Correlación: ${widget.titulo}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
        const SizedBox(height: 15),
        
        Row(
          children:[
            Expanded(child: TextField(controller: _bivNombreXCtrl, decoration: const InputDecoration(labelText: "Nombre Variable X", prefixIcon: Icon(Icons.label), border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _bivNombreYCtrl, decoration: const InputDecoration(labelText: "Nombre Variable Y", prefixIcon: Icon(Icons.label), border: OutlineInputBorder(), isDense: true))),
          ],
        ),
        const SizedBox(height: 15),
        
        TextField(controller: _bivDatosXCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Datos de X (Separados por ; o pegados)", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
        const SizedBox(height: 10),
        TextField(controller: _bivDatosYCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Datos de Y (Separados por ; o pegados)", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
        const SizedBox(height: 10),
        
        Wrap(
          spacing: 10, runSpacing: 10, alignment: WrapAlignment.end,
          children:[
            Tooltip(message: "Copia 2 columnas de Excel y pégalas", child: TextButton.icon(onPressed: _pegarDatosBivariados, icon: const Icon(Icons.content_paste, color: Colors.blueAccent), label: const Text("Pegar 2 Columnas de Excel"))),
            TextButton.icon(onPressed: () { _bivDatosXCtrl.clear(); _bivDatosYCtrl.clear(); }, icon: const Icon(Icons.clear, color: Colors.redAccent), label: const Text("Limpiar")),
          ],
        ),
        const SizedBox(height: 15),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.scatter_plot),
            label: const Padding(padding: EdgeInsets.all(12.0), child: Text("Analizar Correlación", style: TextStyle(fontSize: 16))),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, elevation: 3),
            onPressed: _enviarCorrelacion,
          ),
        )
      ],
    );
  }
}
