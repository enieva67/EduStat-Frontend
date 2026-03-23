import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraficoCurvaNormal extends StatelessWidget {
  final List<dynamic> sombreado3;
  final List<dynamic> datosCurva;
  final List<dynamic> sombreado1;
  final List<dynamic> sombreado2;
  final double pacienteX;
  final double pacienteZ;
  final double percentil;
  final double? pacienteX2;
  final String tipoArea;
  
  // NUEVAS VARIABLES DINÁMICAS
  final String titulo;
  final String subtitulo;
  final String etiquetaX1;
  final String etiquetaX2;
  final bool esPruebaHipotesis; // <--- NUEVA VARIABLE MÁGICA
  

  const GraficoCurvaNormal({
    super.key,
    required this.datosCurva,
    required this.sombreado1,
    required this.sombreado2,
    this.sombreado3 = const[], // <--- NUEVO (Lo ponemos opcional y vacío por defecto)
    required this.pacienteX,
    required this.pacienteZ,
    required this.percentil,
    this.pacienteX2,
    required this.tipoArea,
    this.titulo = "La Campana de Gauss",
    this.subtitulo = "El paciente (línea dorada) obtuvo un Z =",
    this.etiquetaX1 = "X1",
    this.etiquetaX2 = "X2",
    this.esPruebaHipotesis = false, // <--- Por defecto es falso (Mantiene el dorado de Dubái)
  });

  // Función auxiliar para mapear JSON a FlSpots
  List<FlSpot> _mapearPuntos(List<dynamic> jsonList) {
    final List<FlSpot> spots = List.empty(growable: true);
    for (var p in jsonList) {
      spots.add(FlSpot((p['x'] as num).toDouble(), (p['y'] as num).toDouble()));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    if (datosCurva.isEmpty) return const SizedBox.shrink();
    final spotsSombreado3 = _mapearPuntos(sombreado3);

    final spotsPrincipal = _mapearPuntos(datosCurva);
    final spotsSombreado1 = _mapearPuntos(sombreado1);
    final spotsSombreado2 = _mapearPuntos(sombreado2);

    double maxY = 0;
    for (var spot in spotsPrincipal) {
      if (spot.y > maxY) maxY = spot.y;
    }

    final double minX = spotsPrincipal.first.x;
    final double maxX = spotsPrincipal.last.x;

    double intervaloIdeal = (maxX - minX) / 6;
    if (intervaloIdeal <= 0) intervaloIdeal = 1.0; // Seguro por si acaso
// MAGIA UX: Colores Dinámicos según el tema
    final Gradient gradienteSombreado1 = esPruebaHipotesis
        ? LinearGradient(colors:[Colors.teal.withOpacity(0.3), Colors.teal.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        : LinearGradient(colors: [Colors.amber.withOpacity(0.7), Colors.amber.withOpacity(0.1)], begin: Alignment.topCenter, end: Alignment.bottomCenter);

    final Gradient gradienteSombreado2 = esPruebaHipotesis
        ? LinearGradient(colors:[Colors.redAccent.withOpacity(0.7), Colors.redAccent.withOpacity(0.2)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        : LinearGradient(colors:[Colors.amber.withOpacity(0.7), Colors.amber.withOpacity(0.1)], begin: Alignment.topCenter, end: Alignment.bottomCenter);

    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 2),
        boxShadow:[BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 15, spreadRadius: 5)]
      ),
      child: Column(
        children:[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              const Icon(Icons.analytics, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              // MAGIA UX: Usamos el título dinámico
              Text(
                titulo == "La Campana de Gauss" ? "$titulo (Percentil $percentil)" : titulo,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // MAGIA UX: Usamos el subtítulo dinámico
          Text(
            subtitulo == "El paciente (línea dorada) obtuvo un Z =" ? "$subtitulo $pacienteZ" : subtitulo, 
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 30),
          
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX, maxX: maxX, minY: 0, maxY: maxY + 0.05,
              // LA MAGIA VISUAL: Las líneas de los pacientes / Muestras
                extraLinesData: ExtraLinesData(
                  verticalLines:[
                    // CORRECCIÓN: Si es Prueba de Hipótesis, SIEMPRE dibujamos la línea de la muestra.
                    // Si no lo es, mantenemos la regla de ocultarla en 'dos_colas' para Puntaje Z.
                    if (esPruebaHipotesis || tipoArea != 'dos_colas')
                      VerticalLine(
                        x: pacienteX, 
                        color: Colors.amber, 
                        strokeWidth: 4, 
                        dashArray: [5, 5],
                        label: VerticalLineLabel(
                          show: true, 
                          alignment: Alignment.topRight, 
                          padding: const EdgeInsets.only(left: 12, bottom: 15),
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                          // Usamos la etiqueta dinámica (Dirá "Muestra=" o "X1=")
                          labelResolver: (line) => "$etiquetaX1=$pacienteX",
                        ),
                      ),
                      
                    // La segunda línea (Solo se usa en Intervalos o Z entre dos valores)
                    if (pacienteX2 != null && (tipoArea == 'entre_dos_valores' || etiquetaX2 == 'L. Sup'))
                      VerticalLine(
                        x: pacienteX2!, 
                        color: Colors.amber, 
                        strokeWidth: 4, 
                        dashArray: [5, 5],
                        label: VerticalLineLabel(
                          show: true, 
                          alignment: Alignment.topRight, 
                          padding: const EdgeInsets.only(left: 12, bottom: 35),
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                          labelResolver: (line) => "$etiquetaX2=$pacienteX2",
                        ),
                      )
                  ]
                ),
                lineBarsData:[
                  // 1. El contorno de la Campana (Púrpura, sin relleno)
                  LineChartBarData(
                    spots: spotsPrincipal, isCurved: true, color: Colors.deepPurple, barWidth: 3,
                    isStrokeCapRound: true, dotData: const FlDotData(show: false),
                  ),
                  // 2. La capa del Sombreado 1 (Centro / Zona Segura)
                  if (spotsSombreado1.isNotEmpty)
                    LineChartBarData(
                      spots: spotsSombreado1, isCurved: true, color: Colors.transparent, barWidth: 0,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, gradient: gradienteSombreado1), // <--- USA EL 1
                    ),
                    
                  // 3. La capa del Sombreado 2 (Colas / Zona de Rechazo)
                  if (spotsSombreado2.isNotEmpty)
                    LineChartBarData(
                      spots: spotsSombreado2, isCurved: true, color: Colors.transparent, barWidth: 0,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, gradient: gradienteSombreado2), // <--- USA EL 2
                    ),
                    if (spotsSombreado3.isNotEmpty)
                    LineChartBarData(
                      spots: spotsSombreado3, isCurved: true, color: Colors.transparent, barWidth: 0,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, gradient: gradienteSombreado2), // Usa el MISMO gradiente rojo
                    ),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    axisNameSize: 30,
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(top: 8.0), 
                      child: Text("Puntaje Crudo (X)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple))
                    ),
                    sideTitles: SideTitles(
                      showTitles: true, 
                      reservedSize: 30,
                      interval: intervaloIdeal, // <--- Aplicamos el espaciado perfecto
                      getTitlesWidget: (value, meta) {
                        // MAGIA UX 2: SMART FORMATTER
                        // Formateamos a 2 decimales, pero quitamos los ceros inútiles
                        String texto = value.toStringAsFixed(2);
                        
                        if (texto.endsWith('0')) {
                          texto = texto.substring(0, texto.length - 1); // Quita el último cero (Ej: 10.50 -> 10.5)
                        }
                        if (texto.endsWith('.0')) {
                          texto = texto.substring(0, texto.length - 2); // Quita el entero (Ej: 10.0 -> 10)
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(texto, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: true, border: const Border(bottom: BorderSide(color: Colors.black26, width: 2))),
                lineTouchData: LineTouchData(enabled: false), // Desactivamos el tooltip para que el área sea la estrella
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}