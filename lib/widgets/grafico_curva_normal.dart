import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraficoCurvaNormal extends StatelessWidget {
  final List<dynamic> datosCurva;
  final List<dynamic> sombreado1;
  final List<dynamic> sombreado2;
  final double pacienteX;
  final double pacienteZ;
  final double percentil;
  final double? pacienteX2; // <--- NUEVO (Es opcional)
  final String tipoArea;    // <--- NUEVO

  const GraficoCurvaNormal({
    super.key,
    required this.datosCurva,
    required this.sombreado1,
    required this.sombreado2,
    required this.pacienteX,
    required this.pacienteZ,
    required this.percentil, this.pacienteX2, required this.tipoArea,
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

    final spotsPrincipal = _mapearPuntos(datosCurva);
    final spotsSombreado1 = _mapearPuntos(sombreado1);
    final spotsSombreado2 = _mapearPuntos(sombreado2);

    double maxY = 0;
    for (var spot in spotsPrincipal) {
      if (spot.y > maxY) maxY = spot.y;
    }

    final double minX = spotsPrincipal.first.x;
    final double maxX = spotsPrincipal.last.x;

    // Estilo del Sombreado de Lujo
    final Gradient gradienteSombreado = LinearGradient(
      colors:[Colors.amber.withOpacity(0.7), Colors.amber.withOpacity(0.1)],
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
    );

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
              const Icon(Icons.area_chart, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              const Text("Probabilidad y Área", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ],
          ),
          const SizedBox(height: 5),
          Text("Z = $pacienteZ  |  Área pintada: $percentil%", style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX, maxX: maxX, minY: 0, maxY: maxY + 0.05,
                
                // LA MAGIA VISUAL: Las líneas de los pacientes
                extraLinesData: ExtraLinesData(
                  verticalLines:[
                    // Línea del Paciente 1 (Oculta en 'dos_colas' para no confundir)
                    if (tipoArea != 'dos_colas')
                      VerticalLine(
                        x: pacienteX, color: Colors.amber, strokeWidth: 4, dashArray: [5, 5],
                        label: VerticalLineLabel(
                          show: true, alignment: Alignment.topRight, padding: const EdgeInsets.only(left: 8, bottom: 15),
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                          labelResolver: (line) => tipoArea == 'entre_dos_valores' ? "X1=$pacienteX" : "X=$pacienteX",
                        ),
                      ),
                    
                    // Línea del Paciente 2 (Si existe)
                    if (pacienteX2 != null && tipoArea == 'entre_dos_valores')
                      VerticalLine(
                        x: pacienteX2!, color: Colors.amber, strokeWidth: 4, dashArray: [5, 5],
                        label: VerticalLineLabel(
                          show: true, alignment: Alignment.topRight, padding: const EdgeInsets.only(left: 8, bottom: 35), // Lo subimos más para que no choquen si están cerca
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                          labelResolver: (line) => "X2=$pacienteX2",
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
                  
                  // 2. La capa del Sombreado 1 (Transparente con relleno dorado)
                  if (spotsSombreado1.isNotEmpty)
                    LineChartBarData(
                      spots: spotsSombreado1, isCurved: true, color: Colors.transparent, barWidth: 0,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, gradient: gradienteSombreado),
                    ),
                    
                  // 3. La capa del Sombreado 2 (Para las dos colas)
                  if (spotsSombreado2.isNotEmpty)
                    LineChartBarData(
                      spots: spotsSombreado2, isCurved: true, color: Colors.transparent, barWidth: 0,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, gradient: gradienteSombreado),
                    ),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    axisNameSize: 30,
                    axisNameWidget: const Padding(padding: EdgeInsets.only(top: 8.0), child: Text("Puntaje Crudo (X)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple))),
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.black54)),
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