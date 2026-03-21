import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:file_picker/file_picker.dart';
import 'services/websocket_service.dart';
import 'widgets/grafico_media.dart';
import 'widgets/grafico_histograma.dart';
import 'package:flutter/services.dart'; // ¡NUEVO: Para el Portapapeles!
import 'widgets/grafico_curva_normal.dart'; // <--- IMPORTANTE
import 'widgets/grafico_dispersion.dart';
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
    'intervalo_confianza': 'Intervalos de Confianza (Media)', // <--- NUEVA
  };

  // NUEVO: Controladores para el formulario de Puntaje Z
  final TextEditingController _zMediaCtrl = TextEditingController(text: "100");
  final TextEditingController _zDesviacionCtrl = TextEditingController(text: "15");
  String _tipoAreaZ = 'menor'; // Por defecto pinta a la izquierda
  final TextEditingController _zPacienteCtrl = TextEditingController(text: "118");
  final TextEditingController _zPaciente2Ctrl = TextEditingController(text: "130"); // <--- NUEVO
  bool _tengoPuntajeX = true; // Interruptor: True = Normal, False = Proceso Inverso
  final TextEditingController _zArea1Ctrl = TextEditingController(text: "95");
  final TextEditingController _zArea2Ctrl = TextEditingController(text: "99");
// Controladores para Bivariada (Correlación)
  final TextEditingController _bivNombreXCtrl = TextEditingController(text: "Horas Estudio");
  final TextEditingController _bivNombreYCtrl = TextEditingController(text: "Calificación");

  final TextEditingController _bivDatosXCtrl = TextEditingController(text: "2; 4; 5; 8; 10");
  final TextEditingController _bivDatosYCtrl = TextEditingController(text: "40; 60; 65; 85; 95");
  // CONTROLADORES DE INFERENCIA
  final TextEditingController _icMediaCtrl = TextEditingController(text: "105.5");
  final TextEditingController _icDesvCtrl = TextEditingController(text: "15.0");

  final TextEditingController _icNCtrl = TextEditingController(text: "25");
  String _icConfianza = '95.0'; // Selector de Confianza
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
    wsService.dispose();
    _datosSinAgruparController.dispose(); // <--- AÑADE ESTO
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
Future<void> _pegarDatosBivariados() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;

    final List<double> listX = List.empty(growable: true);
    final List<double> listY = List.empty(growable: true);
    
    // Dividimos por filas de Excel
    List<String> lineas = data.text!.trim().split('\n');

    for (String linea in lineas) {
      // Separamos por Tabulación (Excel) o Punto y Coma (CSV)
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
      _mostrarMensaje("¡Éxito! Se pegaron ${listX.length} pares de datos.");
    } else {
      _mostrarMensaje("Error: No se detectaron 2 columnas numéricas juntas.");
    }
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
void _enviarCorrelacion() {
    List<double> xList = _extraerNumeros(_bivDatosXCtrl.text);
    List<double> yList = _extraerNumeros(_bivDatosYCtrl.text);

    if (xList.length != yList.length || xList.length < 2) {
      _mostrarMensaje("Error: X e Y deben tener la misma cantidad de números (Mínimo 2).");
      return;
    }

    setState(() {
      _bivDatosXCtrl.text = xList.join('; ');
      _bivDatosYCtrl.text = yList.join('; ');
    });

    final payload = {
      "id": "calculo_01",
      "accion": "calcular_${_medidaSeleccionada}", // Ej: calcular_pearson
      "parametros": {
        "x": xList, "y": yList,
        "ctx_x": _bivNombreXCtrl.text, "ctx_y": _bivNombreYCtrl.text
      }
    };
    wsService.sendJson(payload);
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
  void _enviarPuntajeZ() {
    double? media = double.tryParse(_zMediaCtrl.text.replaceAll(',', '.'));
    double? desviacion = double.tryParse(_zDesviacionCtrl.text.replaceAll(',', '.'));
    if (media == null || desviacion == null) return;

    if (_tengoPuntajeX) {
      // RUTA NORMAL: Tengo X y quiero el Área
      double? xVal = double.tryParse(_zPacienteCtrl.text.replaceAll(',', '.'));
      double? x2Val = _tipoAreaZ == 'entre_dos_valores' ? double.tryParse(_zPaciente2Ctrl.text.replaceAll(',', '.')) : null;

      if (xVal == null) { _mostrarMensaje("Ingresa un Puntaje X válido."); return; }

      wsService.sendJson({
        "id": "calculo_01", "accion": "calcular_puntaje_z",
        "parametros": { "media": media, "desviacion": desviacion, "x": xVal, "tipo_area": _tipoAreaZ, "x2": x2Val }
      });
    } else {
      // RUTA INVERSA: Tengo el Área y quiero la X
      double? area1 = double.tryParse(_zArea1Ctrl.text.replaceAll(',', '.'));
      double? area2 = _tipoAreaZ == 'entre_dos_valores' ? double.tryParse(_zArea2Ctrl.text.replaceAll(',', '.')) : null;

      if (area1 == null) { _mostrarMensaje("Ingresa un Área válida (Ej: 95)."); return; }

      wsService.sendJson({
        "id": "calculo_01", "accion": "calcular_x_desde_area",
        "parametros": { "media": media, "desviacion": desviacion, "area1": area1, "tipo_area": _tipoAreaZ, "area2": area2 }
      });
    }
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
        "media": media,
        "desviacion": desviacion,
        "n": n,
        "confianza": double.parse(_icConfianza)
      }
    };
    wsService.sendJson(payload);
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
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children:[
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.teal),
                child: Text('Módulos de EduStat', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              ExpansionTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('1. Estadística Descriptiva', style: TextStyle(fontWeight: FontWeight.bold)),
                children:[
                  ListTile(title: const Text("Media"), onTap: () { setState(() => _medidaSeleccionada = 'media'); Navigator.pop(context); }),
                  ListTile(title: const Text("Mediana"), onTap: () { setState(() => _medidaSeleccionada = 'mediana'); Navigator.pop(context); }),
                  ListTile(title: const Text("Moda"), onTap: () { setState(() => _medidaSeleccionada = 'moda'); Navigator.pop(context); }),
                  ListTile(title: const Text("Varianza"), onTap: () { setState(() => _medidaSeleccionada = 'varianza'); Navigator.pop(context); }),
                  ListTile(title: const Text("Percentiles"), onTap: () { setState(() => _medidaSeleccionada = 'percentil'); Navigator.pop(context); }),
                ],
              ),
              ExpansionTile(
                leading: const Icon(Icons.analytics),
                title: const Text('2. Curva Normal', style: TextStyle(fontWeight: FontWeight.bold)),
                children:[
                  ListTile(title: const Text("Puntaje Z y Probabilidades"), onTap: () { setState(() => _medidaSeleccionada = 'puntaje_z'); Navigator.pop(context); }),
                ],
              ),
              ExpansionTile(
                leading: const Icon(Icons.psychology),
                title: const Text('3. Estadística Inferencial', style: TextStyle(fontWeight: FontWeight.bold)),
                children:[
                  ListTile(title: const Text("Intervalos de Confianza (Media)"), onTap: () { setState(() => _medidaSeleccionada = 'intervalo_confianza'); Navigator.pop(context); }),
                ],
              ),
              ExpansionTile(
                leading: const Icon(Icons.scatter_plot),
                title: const Text('4. Correlación (Bivariada)', style: TextStyle(fontWeight: FontWeight.bold)),
                children:[
                  ListTile(title: const Text("r de Pearson (Paramétrica)"), onTap: () { setState(() => _medidaSeleccionada = 'pearson'); Navigator.pop(context); }),
                  ListTile(title: const Text("Rho de Spearman (No Paramétrica)"), onTap: () { setState(() => _medidaSeleccionada = 'spearman'); Navigator.pop(context); }),
                  ListTile(title: const Text("Coeficiente Phi (Dicotómicas)"), onTap: () { setState(() => _medidaSeleccionada = 'phi'); Navigator.pop(context); }),
                ],
              ),
            ],
          ),
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
                        decoration: BoxDecoration(color: Colors.teal.withOpacity(0.05), border: Border(bottom: BorderSide(color: Colors.teal.withOpacity(0.2)))),
                        child: Container(
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
                      ),
                    
                    // LAS PESTAÑAS (TabBarView)
                    Expanded(
                      child: TabBarView(
                        children:[
                          // --- PESTAÑA 1 ---
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: SingleChildScrollView(
                            child: _medidaSeleccionada == 'puntaje_z' 
                            
                            // ------------------------------------------------
                            // UI EXCLUSIVA PARA PUNTAJE Z (EL FORMULARIO)
                            // ------------------------------------------------
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:[
                                  const Text("Datos de la Población y el Paciente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 15),
                                  
                                  // EL INTERRUPTOR: ¿Qué dato tienes?
                                  Row(
                                    children:[
                                      const Text("¿Qué dato tienes?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                                      const SizedBox(width: 15),
                                      Switch(
                                        value: _tengoPuntajeX,
                                        activeColor: Colors.teal,
                                        inactiveThumbColor: Colors.amber,
                                        inactiveTrackColor: Colors.amber.withOpacity(0.3),
                                        onChanged: (val) => setState(() => _tengoPuntajeX = val),
                                      ),
                                      Text(_tengoPuntajeX ? "Tengo el Puntaje (X)" : "Tengo el Área (%)", style: TextStyle(color: _tengoPuntajeX ? Colors.teal : Colors.amber.shade800, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  
                                  // DATOS POBLACIONALES FIJOS
                                  TextField(controller: _zMediaCtrl, decoration: const InputDecoration(labelText: "Media Poblacional (μ)", prefixIcon: Icon(Icons.balance), border: OutlineInputBorder(), isDense: true)),
                                  const SizedBox(height: 10),
                                  TextField(controller: _zDesviacionCtrl, decoration: const InputDecoration(labelText: "Desviación Estándar (σ)", prefixIcon: Icon(Icons.compare_arrows), border: OutlineInputBorder(), isDense: true)),
                                  const SizedBox(height: 15),

                                  // EL SELECTOR DINÁMICO (Camaleónico)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true, 
                                        value: _tipoAreaZ,
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                                        // MAGIA UX: Cambiamos los textos según el interruptor
                                        items: _tengoPuntajeX 
                                          ? const[
                                              DropdownMenuItem(value: 'menor', child: Text("Buscar Puntaje (X): Que deja el Área a la Izquierda")),
                                              DropdownMenuItem(value: 'mayor', child: Text("Buscar Puntaje (X): Que deja el Área a la Derecha")),
                                              DropdownMenuItem(value: 'entre_media', child: Text("Buscar Puntaje (X): Con un Área desde el Centro")),
                                              DropdownMenuItem(value: 'dos_colas', child: Text("Buscar Puntajes (±X): Que delimitan las Colas")),
                                              DropdownMenuItem(value: 'entre_dos_valores', child: Text("Buscar Puntajes (X₁ y X₂): Dados dos percentiles")),
                                            ]
                                          : const[
                                              DropdownMenuItem(value: 'menor', child: Text("Calcular: Área a la Izquierda de X")),
                                              DropdownMenuItem(value: 'mayor', child: Text("Calcular: Área a la Derecha de X")),
                                              DropdownMenuItem(value: 'entre_media', child: Text("Calcular: Área entre la Media y X")),
                                              DropdownMenuItem(value: 'dos_colas', child: Text("Calcular: Área en los Extremos (±X)")),
                                              DropdownMenuItem(value: 'entre_dos_valores', child: Text("Calcular: Área entre X₁ y X₂")),
                                            ],
                                        onChanged: (val) { if (val != null) setState(() => _tipoAreaZ = val); },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // INPUTS DINÁMICOS CAMALEÓNICOS
                                  if (_tengoPuntajeX) ...[
                                    TextField(controller: _zPacienteCtrl, decoration: const InputDecoration(labelText: "Puntaje (X1)", prefixIcon: Icon(Icons.person), border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.tealAccent)),
                                    if (_tipoAreaZ == 'entre_dos_valores') ...[
                                      const SizedBox(height: 10),
                                      TextField(controller: _zPaciente2Ctrl, decoration: const InputDecoration(labelText: "Segundo Puntaje (X2)", prefixIcon: Icon(Icons.person_add), border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.tealAccent)),
                                    ]
                                  ] else ...[
                                    TextField(controller: _zArea1Ctrl, decoration: const InputDecoration(labelText: "Área o Probabilidad (Ej: 95 o 0.95)", prefixIcon: Icon(Icons.pie_chart), border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.amberAccent)),
                                    if (_tipoAreaZ == 'entre_dos_valores') ...[
                                      const SizedBox(height: 10),
                                      TextField(controller: _zArea2Ctrl, decoration: const InputDecoration(labelText: "Segunda Área (Ej: 99)", prefixIcon: Icon(Icons.pie_chart_outline), border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.amberAccent)),
                                    ]
                                  ],

                                  const SizedBox(height: 20),
                                  
                                  // BOTÓN DE ACCIÓN FINAL
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.auto_graph),
                                      label: const Padding(padding: EdgeInsets.all(12.0), child: Text("Dibujar Campana de Gauss", style: TextStyle(fontSize: 16))),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, elevation: 3),
                                      onPressed: _enviarPuntajeZ,
                                    ),
                                  )
                                ],
                              )
                              // 2. MÓDULO CORRELACIONES (Bivariado)
                              : ['pearson', 'spearman', 'phi'].contains(_medidaSeleccionada)
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:[
                                    Text("Correlación: ${_opcionesMedida[_medidaSeleccionada] ?? 'Bivariada'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 15),
                                    
                                    Row(
                                      children:[
                                        Expanded(child: TextField(controller: _bivNombreXCtrl, decoration: const InputDecoration(labelText: "Nombre Variable X", isDense: true, border: OutlineInputBorder()))),
                                        const SizedBox(width: 10),
                                        Expanded(child: TextField(controller: _bivNombreYCtrl, decoration: const InputDecoration(labelText: "Nombre Variable Y", isDense: true, border: OutlineInputBorder()))),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    
                                    TextField(controller: _bivDatosXCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Datos de X (Separados por ; o pegados)", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
                                    const SizedBox(height: 10),
                                    TextField(controller: _bivDatosYCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Datos de Y (Separados por ; o pegados)", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
                                    const SizedBox(height: 10),
                                    
                                    Wrap(
                                      spacing: 10, alignment: WrapAlignment.end,
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
                                        label: const Padding(padding: EdgeInsets.all(12.0), child: Text("Analizar Correlación")),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                                        onPressed: _enviarCorrelacion,
                                      ),
                                    )
                                  ],
                                )
                                // 3. MÓDULO INFERENCIAL (¡NUEVO!)
                              : _medidaSeleccionada == 'intervalo_confianza'
                              ? Column(
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
            // PANEL DERECHO: Pizarra Inmortal (Sin cambios)
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: wsService.mathResult,
                builder: (context, result, child) {
                  if (result == null) return const Center(child: Text("Selecciona un nivel o sube un archivo para ver la magia.", style: TextStyle(fontSize: 18, color: Colors.grey)));
                  List<dynamic> pasos = result['pasos'] ??[];

                  // -----------------------------------------------------------------
                  // LÓGICA DE ESTADO ESTRICTA: Leemos qué calculó Python realmente
                  // -----------------------------------------------------------------
                  String simboloRespuesta = result['simbolo_estadistico'] ?? '';
                  bool mostrarGraficoPuntos = simboloRespuesta.contains('\\bar{x}') || 
                                              simboloRespuesta.contains('Me') || 
                                              simboloRespuesta.contains('P_');

                  String tituloGrafico = "Visualización";
                  String subtituloGrafico = "";
                  String etiquetaGrafico = "Valor";

                  if (simboloRespuesta.contains('\\bar{x}')) {
                    tituloGrafico = "El Punto de Equilibrio (Media)";
                    subtituloGrafico = "La línea roja (Media) equilibra el peso de todos los pacientes.";
                    etiquetaGrafico = "Media";
                  } else if (simboloRespuesta.contains('Me')) {
                    tituloGrafico = "El Centro Exacto (Mediana)";
                    subtituloGrafico = "La línea roja divide a los pacientes exactamente en dos mitades (50% y 50%).";
                    etiquetaGrafico = "Mediana";
                  } else if (simboloRespuesta.contains('P_')) {
                    tituloGrafico = "Línea de Corte (Percentil)";
                    subtituloGrafico = "La línea roja separa a la población según el porcentaje buscado.";
                    etiquetaGrafico = "Corte";
                  }

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
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Container(
                                        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.4),
                                        alignment: Alignment.center,
                                        child: Math.tex(paso['formula_latex'] ?? "", textStyle: const TextStyle(fontSize: 24, color: Colors.black)),
                                      ),
                                    ),
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
                      
                      // -----------------------------------------------------------------
                      // RENDERIZADO DEL GRÁFICO DE PUNTOS (Depende 100% de la respuesta)
                      // -----------------------------------------------------------------
                      if (result['datos_originales'] != null && 
                          result['resultado_final'] is num && 
                          mostrarGraficoPuntos) 
                        
                        GraficoMediaAritmetica(
                          datos: List<double>.from(result['datos_originales'].map((e) => (e as num).toDouble())),
                          media: (result['resultado_final'] as num).toDouble(),
                          contexto: result['contexto'] ?? "Valores",
                          titulo: tituloGrafico,
                          subtitulo: subtituloGrafico,
                          etiquetaLinea: etiquetaGrafico,
                        ),

                      if (result['datos_histograma'] != null)
                        GraficoHistograma(datosHistograma: result['datos_histograma'], contexto: result['contexto'] ?? "Valores",),
                      const SizedBox(height: 40),
                      // 3. Si es Curva Normal O Intervalo de Confianza
                      if (result['datos_curva'] != null)
                        GraficoCurvaNormal(
                          datosCurva: result['datos_curva'],
                          sombreado1: result['sombreado_1'] ?? List.empty(),
                          sombreado2: result['sombreado_2'] ?? List.empty(),
                          pacienteX: (result['paciente_x'] as num).toDouble(),
                          pacienteZ: (result['paciente_z'] as num).toDouble(),
                          percentil: result['percentil'] != null ? (result['percentil'] as num).toDouble() : 0.0, 
                          pacienteX2: result['paciente_x2'] != null ? (result['paciente_x2'] as num).toDouble() : null,
                          tipoArea: result['tipo_area'] ?? 'menor',
                          
                          // MAGIA UX: Textos dinámicos si la respuesta es de Intervalo de Confianza (IC)
                          titulo: simboloRespuesta.contains('IC') ? "Distribución Muestral (${result['percentil']}%)" : "La Campana de Gauss",
                          subtitulo: simboloRespuesta.contains('IC') ? "La zona dorada marca dónde podría estar la Media Poblacional (μ)." : "El paciente (línea dorada) obtuvo un Z =",
                          etiquetaX1: simboloRespuesta.contains('IC') ? "L. Inf" : "X1",
                          etiquetaX2: simboloRespuesta.contains('IC') ? "L. Sup" : "X2",
                        ),
                        // 4. Si es Correlación (Bivariada)
                      if (result['datos_x'] != null && result['datos_y'] != null && ['r', '\\rho', '\\phi'].any((s) => simboloRespuesta.contains(s)))
                        GraficoDispersion(
                          datosX: List<double>.from(result['datos_x'].map((e) => (e as num).toDouble())),
                          datosY: List<double>.from(result['datos_y'].map((e) => (e as num).toDouble())),
                          titulo: "Gráfico de Dispersión",
                          labelX: result['contexto']?.split(' vs ')[0] ?? "X",
                          labelY: result['contexto']?.split(' vs ')[1] ?? "Y",
                        ),
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