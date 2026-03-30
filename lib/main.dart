import 'dart:convert';
import 'dart:io';
import 'package:edustat_frontend/widgets/formularios/form_chi_cuadrado.dart';
import 'package:edustat_frontend/widgets/formularios/form_comparacion.dart';
import 'package:edustat_frontend/widgets/formularios/form_correlacion.dart';
import 'package:edustat_frontend/widgets/formularios/form_curva_normal.dart';
import 'package:edustat_frontend/widgets/formularios/form_hipotesis.dart';
import 'package:edustat_frontend/widgets/formularios/form_intervalo.dart';
import 'package:edustat_frontend/widgets/formularios/form_poder.dart';
import 'package:edustat_frontend/widgets/ui/menu_lateral.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'services/websocket_service.dart';

import 'package:flutter/services.dart'; // ¡NUEVO: Para el Portapapeles!

// NUEVO: Importamos nuestro bloque de Lego
import 'widgets/ui/pizarra_inmortal.dart';
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
  // NUEVO: Controlador para la caja de texto de Nivel 1
  final TextEditingController _datosSinAgruparController = TextEditingController(text: "12, 15, 14, 10, 18");
  // NUEVO: El mapa de todas las opciones que nuestro sistema soporta
  String _medidaSeleccionada = 'media';
  // NUEVO: Añadimos Percentil a las opciones
  final Map<String, String> _opcionesMedida = {
    'media': 'Media (Promedio)',
    'mediana': 'Mediana (Centro)',
    'moda': 'Moda (Frecuente)',
    'varianza': 'Varianza (Dispersión)',
    'percentil': 'Percentiles (Posición)',
    'puntaje_z': 'Puntaje Z (Campana)', // <--- NUEVO
    'pearson': 'r de Pearson',
    'spearman': 'Rho de Spearman',
    'phi': 'Coeficiente Phi',
     'intervalo_confianza': 'Intervalos de Confianza (Media)',
    'prueba_hipotesis': 'Prueba de Hipótesis (Media)', // <--- NUEVA
    'chi2_bondad': 'Ji-Cuadrado (Bondad de Ajuste)',
    'chi2_independencia': 'Ji-Cuadrado (Independencia)',
    'poder_estadistico': 'Poder y Tamaño de Muestra',
    'ttest_indep': 'T de Student (Grupos Independientes)',
    'mann_whitney': 'U de Mann-Whitney (No Paramétrico)',
    'z_proporciones': 'Prueba Z (Dos Proporciones)',
  };
  
  double _kPercentil = 50; // <--- El valor por defecto (Mediana/P50)
  
  
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
    
    // NUEVO: Escuchamos el canal de emergencias en tiempo real
    wsService.serverError.addListener(() {
      final String? errorMsg = wsService.serverError.value;
      if (errorMsg != null) {
        // Usamos la misma función que ya teníamos, pero le ponemos un ícono de error
        _mostrarMensaje("❌ $errorMsg");
        
        // Limpiamos el buzón para que vuelva a avisar si ocurre el MISMO error de nuevo
        wsService.serverError.value = null; 
      }
    });
  }

  @override
  void dispose() {
    // 1. Apagamos el puente de conexión del WebSocket
    wsService.dispose();
    
    // 2. Limpiamos los Controladores de Estadística Descriptiva (Nivel 1 y 2)
    _datosSinAgruparController.dispose();
    for (var fila in _filasAgrupadas) {
      fila['inf']?.dispose();
      fila['sup']?.dispose();
      fila['f']?.dispose();
      
    }

        
  
        // Finalmente, dejamos que Flutter destruya la pantalla
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
// NUEVO 1: Botón para vaciar la tabla rápidamente
  void _limpiarTabla() {
    setState(() {
      for (var fila in _filasAgrupadas) {
        fila['inf']?.dispose();
        fila['sup']?.dispose();
        fila['f']?.dispose();
      }
      _filasAgrupadas.clear();
    });
  }

  // NUEVO 2: El Pegado Inteligente desde Excel/CSV
  Future<void> _pegarDesdePortapapeles() async {
    // 1. Leer el portapapeles
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) {
      _mostrarMensaje("El portapapeles está vacío.");
      return;
    }

    String textoCrudo = data.text!;
    List<Map<String, TextEditingController>> nuevasFilas =[];
    int filasIgnoradas = 0;

    // 2. Separar por saltos de línea (cada fila de Excel)
    List<String> lineas = textoCrudo.trim().split('\n');

    for (String linea in lineas) {
      // 3. Soportar separaciones de Excel (\t) o CSV (, o ;)
      List<String> celdas = linea.split(RegExp(r'[\t;,]'));
      
      // Limpiamos espacios en blanco de cada celda
      celdas = celdas.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      // 4. Si la fila tiene al menos 3 columnas, intentamos extraer los números
      if (celdas.length >= 3) {
        double? inf = double.tryParse(celdas[0].replaceAll(',', '.')); // Soporta decimales con coma
        double? sup = double.tryParse(celdas[1].replaceAll(',', '.'));
        double? f = double.tryParse(celdas[2].replaceAll(',', '.'));

        // 5. Filtrado Ninja: Solo si las 3 celdas son números válidos, las agregamos
        if (inf != null && sup != null && f != null) {
          nuevasFilas.add({
            'inf': TextEditingController(text: inf.toString().replaceAll('.0', '')),
            'sup': TextEditingController(text: sup.toString().replaceAll('.0', '')),
            'f': TextEditingController(text: f.toString().replaceAll('.0', '')),
          });
        } else {
          filasIgnoradas++; // Seguramente era una cabecera de texto
        }
      }
    }

    // 6. Actualizar la UI
    if (nuevasFilas.isNotEmpty) {
      _limpiarTabla(); // Borramos lo viejo
      setState(() {
        _filasAgrupadas.addAll(nuevasFilas);
      });
      _mostrarMensaje("¡Éxito! Se pegaron ${nuevasFilas.length} filas. (Ignoradas: $filasIgnoradas)");
    } else {
      _mostrarMensaje("Error: No se encontraron 3 columnas numéricas válidas en el portapapeles.");
    }
  }
// 1. EL FILTRO NINJA: Centraliza la lógica de limpieza
  List<double> _extraerNumeros(String rawText) {
    List<String> rawItems = rawText.split(RegExp(r'[\n\t;\s]+'));
    
 // HACK ANTI-GLITCH: Usamos el constructor nativo para evitar los corchetes
    final List<double> datosLimpios = List.empty(growable: true);

    for (String item in rawItems) {
      if (item.trim().isEmpty) continue;
      
      // Convertimos comas a puntos (ej: 12,5 -> 12.5)
      String sanitized = item.replaceAll(',', '.');
      double? val = double.tryParse(sanitized);
      
      if (val != null) {
        datosLimpios.add(val);
      }
    }
    return datosLimpios;
  }

  // 2. PEGADO INTELIGENTE: Pega, limpia y formatea la caja de texto al instante
  Future<void> _pegarDatosSinAgrupar() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      
      // Pasamos el texto crudo por el filtro ninja
      List<double> limpios = _extraerNumeros(data.text!);
      
      if (limpios.isNotEmpty) {
        setState(() {
          // Actualizamos la caja de texto con los números bonitos, separados por "; "
          _datosSinAgruparController.text = limpios.join('; ');
        });
        _mostrarMensaje("¡Éxito! Se limpiaron y extrajeron ${limpios.length} números.");
      } else {
        _mostrarMensaje("No se detectaron números en el portapapeles.");
      }
    }
  }
  
  
  
 
  // 3. ENVÍO AL BACKEND: Formatea la caja antes de enviar por si el usuario tipeó
  void _enviarDatosSinAgrupar() {
    // Volvemos a limpiar por si el usuario escribió algo a mano
    List<double> datosLimpios = _extraerNumeros(_datosSinAgruparController.text);

    if (datosLimpios.isEmpty) {
      _mostrarMensaje("Error: No se encontraron números válidos para calcular.");
      return;
    }

    // UX MÁGICA: Reemplazamos lo que el usuario escribió por la versión "limpia"
    setState(() {
      _datosSinAgruparController.text = datosLimpios.join('; ');
    });

    // Enviamos a Python
    String accionSinAgrupar = 'calcular_${_medidaSeleccionada}_sin_agrupar';
    wsService.pedirCalculo(accionSinAgrupar, datosLimpios, "Mis Datos", k: _kPercentil.toInt());
  }
  
  // Función auxiliar para mostrar notificaciones (SnackBar)
  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.teal.shade800,
        duration: const Duration(seconds: 3),
      )
    );
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
    String nombreMedida = _opcionesMedida[_medidaSeleccionada] ?? 'Medida Seleccionada';
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
        // EL NUEVO MENÚ LATERAL MODULAR
        // Le pasamos una función que actualiza nuestro estado _medidaSeleccionada
        drawer: MenuLateral(
          onMenuSeleccionado: (String nuevaMedida) {
            setState(() {
              _medidaSeleccionada = nuevaMedida;
            });
          },
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
                    
                    // CONTROL MAESTRO DE PERCENTILES (Sobreviviente de la limpieza)
                    // Solo aparecerá si el estudiante selecciona "Percentiles" en el Menú Lateral
                    if (_medidaSeleccionada == 'percentil')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.05), border: Border(bottom: BorderSide(color: Colors.teal.withValues(alpha: 0.2)))),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.05), 
                            borderRadius: BorderRadius.circular(12), 
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2)
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
                                      inactiveColor: Colors.amber.withValues(alpha: 0.3),
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
                      ),
                    
                    // LAS PESTAÑAS (TabBarView)
                    Expanded(
                      child: TabBarView(
                        children:[
                          // --- PESTAÑA 1 ---
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: SingleChildScrollView(
                            // 1. MÓDULO NORMAL (Puntaje Z)
                              child: _medidaSeleccionada == 'puntaje_z' 
                              ? const FormCurvaNormal() // <--- ¡MAGIA! UNA SOLA LÍNEA                                                    
                              
                              // 2. MÓDULO CORRELACIONES (Bivariado)
                              :['pearson', 'spearman', 'phi'].contains(_medidaSeleccionada)
                              ? FormCorrelacion(
                                  medidaSeleccionada: _medidaSeleccionada,
                                  titulo: nombreMedida, // Usamos la variable defensiva que ya tienes calculada arriba
                                )
                                // 3. INTERVALOS DE CONFIANZA
                              : _medidaSeleccionada == 'intervalo_confianza'
                              ? const FormIntervalo()
                                
                              // 4. PRUEBA DE HIPÓTESIS
                              : _medidaSeleccionada == 'prueba_hipotesis'
                              ? const FormHipotesis()
                               
                              // 5. MÓDULO JI-CUADRADO (Bondad e Independencia)
                              : ['chi2_bondad', 'chi2_independencia'].contains(_medidaSeleccionada)
                              ? FormChiCuadrado(medidaSeleccionada: _medidaSeleccionada)
                                
                              // 6. MÓDULO DE PODER ESTADÍSTICO
                              : _medidaSeleccionada == 'poder_estadistico'
                              ? const FormPoder()                               

                               // 7. MÓDULO COMPARACIÓN DE GRUPOS (¡NUEVO!)
                              :['ttest_indep', 'mann_whitney', 'z_proporciones'].contains(_medidaSeleccionada)
                              ? FormComparacion(
                                  medidaSeleccionada: _medidaSeleccionada,
                                  titulo: nombreMedida,
                                )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                const Text("1. Ingresa datos manualmente o pega desde Excel:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                
                                // CAJA DE TEXTO INTELIGENTE
                                TextField(
                                  controller: _datosSinAgruparController,
                                  maxLines: 4, // Da espacio para ver si pegan una columna
                                  decoration: InputDecoration(
                                    hintText: "Ejemplo: 12.5; 14; 15,2\nPuedes separar por espacios o pegar una columna de Excel.",
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.teal.shade300, width: 2)),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                
                                // BOTONERA DE CONTROL (NIVEL 1)
                                // Usamos Wrap en lugar de Row para que los botones salten de línea si la pantalla es muy pequeña
                                Wrap(
                                  spacing: 10, // Espacio horizontal entre botones
                                  runSpacing: 10, // Espacio vertical si saltan de línea
                                  alignment: WrapAlignment.end,
                                  children:[
                                    TextButton.icon(
                                      onPressed: _pegarDatosSinAgrupar,
                                      icon: const Icon(Icons.content_paste, color: Colors.blueAccent),
                                      label: const Text("Pegar", style: TextStyle(color: Colors.blueAccent)),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _datosSinAgruparController.clear(),
                                      icon: const Icon(Icons.clear, color: Colors.redAccent),
                                      label: const Text("Limpiar", style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 15),
                                
                                // EL GRAN BOTÓN DE EXPLICAR (Aislado y a todo lo ancho para evitar Overflows)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.school),
                                    label: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                      child: Text("Explicar $nombreMedida", style: const TextStyle(fontSize: 16)),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal, 
                                      foregroundColor: Colors.white, 
                                      elevation: 3
                                    ),
                                    onPressed: _enviarDatosSinAgrupar,
                                  ),
                                ),
                                const Divider(height: 40, thickness: 2),
                                
                                const Text("2. Análisis de Archivos Grandes (>300 datos)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const Divider(height: 40, thickness: 2),
                                
                                const SizedBox(height: 10),
                                OutlinedButton.icon(icon: const Icon(Icons.upload_file), label: const Text("Importar Excel"), onPressed: _seleccionarArchivo),
                                const SizedBox(height: 20),
                                ValueListenableBuilder<Map<String, dynamic>?>(
                                  valueListenable: wsService.fileData,
                                  builder: (context, data, child) {
                                    if (data == null) return const SizedBox.shrink();
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
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
                            )
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
                                const SizedBox(height: 15),
                                
                                // LA NUEVA BOTONERA DE HERRAMIENTAS
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children:[
                                      Row(
                                        children:[
                                          TextButton.icon(
                                            onPressed: _agregarFila, 
                                            icon: const Icon(Icons.add, color: Colors.teal), 
                                            label: const Text("Añadir Fila", style: TextStyle(color: Colors.teal))
                                          ),
                                          const SizedBox(width: 10),
                                          // EL BOTÓN MÁGICO DE PEGADO
                                          Tooltip(
                                            message: "Copia 3 columnas en Excel y pégalas aquí",
                                            child: TextButton.icon(
                                              onPressed: _pegarDesdePortapapeles, 
                                              icon: const Icon(Icons.content_paste, color: Colors.blueAccent), 
                                              label: const Text("Pegar Excel", style: TextStyle(color: Colors.blueAccent))
                                            ),
                                          ),
                                        ],
                                      ),
                                      // BOTÓN PARA LIMPIAR TODO
                                      IconButton(
                                        tooltip: "Vaciar Tabla",
                                        icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                                        onPressed: _limpiarTabla,
                                      )
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 15),
                                
                                // BOTÓN PRINCIPAL DE CÁLCULO
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.school),
                                    label: Padding(
                                      padding: const EdgeInsets.all(12.0), 
                                      child: Text("Explicar $nombreMedida", style: const TextStyle(fontSize: 16))
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple, 
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                    ),
                                    onPressed: _enviarDatosAgrupados,
                                  ),
                                ),
                                
                                const SizedBox(height: 10),
                                
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
            // PANEL DERECHO: La nueva Pizarra Refactorizada
            const PizarraInmortal(),
          ],
        ),
      ),
    );
  }
}