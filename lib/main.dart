import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:file_picker/file_picker.dart';
import 'services/websocket_service.dart';
import 'widgets/grafico_media.dart';
import 'widgets/grafico_histograma.dart';

void main() {
  runApp(const EduStatApp());
}

class EduStatApp extends StatelessWidget {
  const EduStatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduStat',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final wsService = WebSocketService();
  
  // NUEVO: El mapa de todas las opciones que nuestro sistema soporta
  String _medidaSeleccionada = 'media';
  // NUEVO: Añadimos Percentil a las opciones
  final Map<String, String> _opcionesMedida = {
    'media': 'Media (Promedio)',
    'mediana': 'Mediana (Centro)',
    'moda': 'Moda (Frecuente)',
    'varianza': 'Varianza (Dispersión)',
    'percentil': 'Percentiles (Posición)'
  };

  // NUEVO: Variable para guardar qué percentil quiere el usuario (P1 a P99)
  double _kPercentil = 50; 
  final List<Map<String, TextEditingController>> _filasAgrupadas =[
    {'inf': TextEditingController(text: '70'), 'sup': TextEditingController(text: '84'), 'f': TextEditingController(text: '4')},
    {'inf': TextEditingController(text: '85'), 'sup': TextEditingController(text: '99'), 'f': TextEditingController(text: '14')},
    {'inf': TextEditingController(text: '100'), 'sup': TextEditingController(text: '114'), 'f': TextEditingController(text: '18')},
    {'inf': TextEditingController(text: '115'), 'sup': TextEditingController(text: '129'), 'f': TextEditingController(text: '6')},
  ];
  @override
  void initState() {
    super.initState();
    wsService.connect();
  }

  @override
  void dispose() {
    wsService.dispose();
    for (var fila in _filasAgrupadas) {
      fila['inf']?.dispose();
      fila['sup']?.dispose();
      fila['f']?.dispose();
    }
    super.dispose();
  }

  void _enviarDatosAgrupados() {
    List<Map<String, dynamic>> clases =[];
    for (var fila in _filasAgrupadas) {
      double? inf = double.tryParse(fila['inf']!.text);
      double? sup = double.tryParse(fila['sup']!.text);
      double? f = double.tryParse(fila['f']!.text);
      if (inf != null && sup != null && f != null) clases.add({'inf': inf, 'sup': sup, 'f': f});
    }
    
    // Generamos dinámicamente el nombre de la acción ('calcular_moda_agrupada', etc)
    String accion = 'calcular_${_medidaSeleccionada}_agrupada';
    wsService.pedirCalculoAgrupado(accion, clases, "Coeficiente Intelectual (WAIS)", k: _kPercentil.toInt());
  }

  void _agregarFila() {
    setState(() => _filasAgrupadas.add({'inf': TextEditingController(), 'sup': TextEditingController(), 'f': TextEditingController(text: '1')}));
  }

  void _eliminarFila(int index) {
    setState(() {
      _filasAgrupadas[index]['inf']?.dispose();
      _filasAgrupadas[index]['sup']?.dispose();
      _filasAgrupadas[index]['f']?.dispose();
      _filasAgrupadas.removeAt(index);
    });
  }

  Future<void> _seleccionarArchivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions:['csv', 'xls', 'xlsx']);
    if (result != null) {
      File file = File(result.files.single.path!);
      List<int> bytes = await file.readAsBytes();
      wsService.procesarArchivo(base64Encode(bytes), result.files.single.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos la acción para el nivel 1
    String accionSinAgrupar = 'calcular_${_medidaSeleccionada}_sin_agrupar';
    String nombreMedida = _opcionesMedida[_medidaSeleccionada]!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("EduStat - Motor Didáctico"),
          bottom: const TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            tabs:[
              Tab(icon: Icon(Icons.looks_one), text: "Nivel 1: Sin Agrupar"),
              Tab(icon: Icon(Icons.looks_two), text: "Nivel 2: Agrupados"),
            ],
          ),
          actions:[
            ValueListenableBuilder<bool>(
              valueListenable: wsService.isConnected,
              builder: (context, isConnected, child) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(Icons.circle, color: isConnected ? Colors.greenAccent : Colors.redAccent, size: 16),
              ),
            )
          ],
        ),
        body: Row(
          children:[
            // PANEL IZQUIERDO
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.white,
                child: Column(
                  children:[
                    // LA NUEVA BOTONERA INTELIGENTE (ChoiceChips)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(color: Colors.teal.withOpacity(0.05), border: Border(bottom: BorderSide(color: Colors.teal.withOpacity(0.2)))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          const Text("¿Qué deseas aprender hoy?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _opcionesMedida.entries.map((entry) {
                              return ChoiceChip(
                                label: Text(entry.value, style: TextStyle(color: _medidaSeleccionada == entry.key ? Colors.white : Colors.black87)),
                                selectedColor: Colors.teal,
                                selected: _medidaSeleccionada == entry.key,
                                onSelected: (bool selected) {
                                  if (selected) setState(() => _medidaSeleccionada = entry.key);
                                },
                              );
                            }).toList(),
                          ),
                          
                          // NUEVO: SI ELIGE PERCENTILES, MOSTRAMOS EL CONTROL MAESTRO
                          if (_medidaSeleccionada == 'percentil') ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.05), 
                                borderRadius: BorderRadius.circular(12), 
                                border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2)
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:[
                                  // Fila superior: Título y Valor actual
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children:[
                                      Row(
                                        children: const[
                                          Icon(Icons.straighten, color: Colors.amber, size: 24),
                                          SizedBox(width: 8),
                                          Text("Posición a buscar:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                                        child: Text("P${_kPercentil.toInt()}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  
                                  // Fila central: El Slider con botones de precisión
                                  Row(
                                    children:[
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.amber),
                                        tooltip: "Restar 1",
                                        onPressed: _kPercentil > 1 ? () => setState(() => _kPercentil--) : null,
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: _kPercentil,
                                          min: 1, 
                                          max: 99, 
                                          activeColor: Colors.amber,
                                          inactiveColor: Colors.amber.withOpacity(0.3),
                                          label: "P${_kPercentil.toInt()}",
                                          onChanged: (val) => setState(() => _kPercentil = val.roundToDouble()),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
                                        tooltip: "Sumar 1",
                                        onPressed: _kPercentil < 99 ? () => setState(() => _kPercentil++) : null,
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 10),
                                  
                                  // Fila inferior: Botones didácticos de atajo
                                  const Text("Atajos comunes (Cuartiles):", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:[
                                      ActionChip(
                                        label: const Text("Q1 (P25)"), 
                                        backgroundColor: Colors.white,
                                        side: BorderSide(color: _kPercentil == 25 ? Colors.amber : Colors.grey.shade300),
                                        onPressed: () => setState(() => _kPercentil = 25),
                                      ),
                                      ActionChip(
                                        label: const Text("Mediana (P50)"), 
                                        backgroundColor: Colors.white,
                                        side: BorderSide(color: _kPercentil == 50 ? Colors.amber : Colors.grey.shade300),
                                        onPressed: () => setState(() => _kPercentil = 50),
                                      ),
                                      ActionChip(
                                        label: const Text("Q3 (P75)"), 
                                        backgroundColor: Colors.white,
                                        side: BorderSide(color: _kPercentil == 75 ? Colors.amber : Colors.grey.shade300),
                                        onPressed: () => setState(() => _kPercentil = 75),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                    
                    // LAS PESTAÑAS (TabBarView)
                    Expanded(
                      child: TabBarView(
                        children:[
                          // --- PESTAÑA 1 ---
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                const Text("1. Usar Caso de Ejemplo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                const Chip(label: Text("Ansiedad: 12, 15, 14, 10, 18"), backgroundColor: Colors.tealAccent),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.school),
                                  label: Text("Explicar $nombreMedida"),
                                  onPressed: () => wsService.pedirCalculo(accionSinAgrupar,[12, 15, 14, 10, 18], "Puntajes de Ansiedad",k: _kPercentil.toInt()),
                                ),
                                const Divider(height: 40, thickness: 2),
                                const Text("2. Mis propios datos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(icon: const Icon(Icons.upload_file), label: const Text("Importar Excel"), onPressed: _seleccionarArchivo),
                                const SizedBox(height: 20),
                                ValueListenableBuilder<Map<String, dynamic>?>(
                                  valueListenable: wsService.fileData,
                                  builder: (context, data, child) {
                                    if (data == null) return const SizedBox.shrink();
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children:[
                                          Text("✅ ${data['mensaje']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8.0, runSpacing: 8.0,
                                            children: List<String>.from(data['columnas_disponibles']).map((col) {
                                              return ActionChip(
                                                backgroundColor: Colors.blueAccent, labelStyle: const TextStyle(color: Colors.white), label: Text(col),
                                                onPressed: () {
                                                  List<double> doubleData = (data['datos_por_columna'][col] as List).map((e) => (e as num).toDouble()).toList();
                                                  wsService.pedirCalculo(accionSinAgrupar, doubleData, col,k: _kPercentil.toInt());
                                                },
                                              );
                                            }).toList(),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                          ),

                          // --- PESTAÑA 2 ---
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                const Text("Caso Clínico: Inteligencia", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 15),
                                Row(
                                  children: const[
                                    Expanded(child: Text("L. Inferior", style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(child: Text("L. Superior", style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(child: Text("Frecuencia (f)", style: TextStyle(fontWeight: FontWeight.bold))),
                                    SizedBox(width: 48)
                                  ],
                                ),
                                const Divider(),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _filasAgrupadas.length,
                                    itemBuilder: (context, index) {
                                      final fila = _filasAgrupadas[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          children:[
                                            Expanded(child: TextField(controller: fila['inf'], decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
                                            const SizedBox(width: 8),
                                            Expanded(child: TextField(controller: fila['sup'], decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
                                            const SizedBox(width: 8),
                                            Expanded(child: TextField(controller: fila['f'], decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
                                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _eliminarFila(index)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                TextButton.icon(onPressed: _agregarFila, icon: const Icon(Icons.add), label: const Text("Añadir Fila")),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.school),
                                    label: Padding(padding: const EdgeInsets.all(12.0), child: Text("Explicar $nombreMedida")),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                                    onPressed: _enviarDatosAgrupados,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // PANEL DERECHO: Pizarra Inmortal (Sin cambios)
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: wsService.mathResult,
                builder: (context, result, child) {
                  if (result == null) return const Center(child: Text("Selecciona un nivel o sube un archivo para ver la magia.", style: TextStyle(fontSize: 18, color: Colors.grey)));
                  List<dynamic> pasos = result['pasos'] ??[];
                  return ListView(
                    padding: const EdgeInsets.all(24.0),
                    children:[
                      Text(result['tema'] ?? "", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal)),
                      const SizedBox(height: 20),
                      ...pasos.map((paso) => Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:[
                                  Row(
                                    children:[
                                      CircleAvatar(backgroundColor: Colors.teal, foregroundColor: Colors.white, child: Text("${paso['paso_num'] ?? '?'}")),
                                      const SizedBox(width: 15),
                                      Expanded(child: Text(paso['titulo'] ?? "", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Text(paso['explicacion'] ?? "", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                  const SizedBox(height: 20),
                                  Container(
                                    width: double.infinity, padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.teal.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.withOpacity(0.3))),
                                    child: Center(child: Math.tex(paso['formula_latex'] ?? "", textStyle: const TextStyle(fontSize: 24, color: Colors.black))),
                                  )
                                ],
                              ),
                            ),
                          )).toList(),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber)),
                        child: Text("💡 Conclusión: ${result['interpretacion']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 30),
                      if (result['datos_originales'] != null)
                        GraficoMediaAritmetica(
                          datos: List<double>.from(result['datos_originales'].map((e) => (e as num).toDouble())),
                          media: (result['resultado_final'] as num).toDouble(),
                          contexto: result['contexto'] ?? "Valores",
                        ),
                      if (result['datos_histograma'] != null)
                        GraficoHistograma(datosHistograma: result['datos_histograma'], contexto: result['contexto'] ?? "Valores",),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}