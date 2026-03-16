import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class GraficoMediaAritmetica extends StatelessWidget {
  final List<double> datos;
  final double media;
  final String contexto;

  const GraficoMediaAritmetica({
    super.key,
    required this.datos,
    required this.media,
    required this.contexto,
  });

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const SizedBox.shrink();

    // Calculamos los límites del gráfico para que se vea centrado
    final double minX = datos.reduce(min) - 2;
    final double maxX = datos.reduce(max) + 2;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
        boxShadow:[
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ]
      ),
      child: Column(
        children:[
          const Text(
            "Visualización: El Punto de Equilibrio",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 5),
          const Text(
            "Cada punto azul es un paciente. La línea roja (Media) equilibra el peso.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            // USAMOS LINECHART PARA PODER DIBUJAR LA LÍNEA VERTICAL ROJA
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: -1, // Damos espacio arriba y abajo
                maxY: 1,
                
                // LA MAGIA 1: Dibujamos la línea vertical de la media
                extraLinesData: ExtraLinesData(
                  verticalLines:[
                    VerticalLine(
                      x: media,
                      color: Colors.redAccent,
                      strokeWidth: 3,
                      dashArray: [5, 5], // Línea punteada
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(bottom: 20),
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                        labelResolver: (line) => "   Media: ${media.toStringAsFixed(2)}",
                      ),
                    )
                  ]
                ),

                // LA MAGIA 2: Engañamos al LineChart para que parezca un Dot Plot
                lineBarsData:[
                  LineChartBarData(
                    // Colocamos los puntos en Y=0 (sobre la línea base)
                    spots: datos.map((valor) => FlSpot(valor, 0)).toList(),
                    isCurved: false,
                    color: Colors.transparent, // ¡Línea invisible!
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 6,
                            color: Colors.blueAccent.withOpacity(0.7),
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                    ),
                  ),
                ],

                // Configuramos los títulos de los ejes
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(contexto, style: const TextStyle(fontWeight: FontWeight.bold)),
                    sideTitles: const SideTitles(showTitles: true, reservedSize: 30),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(bottom: BorderSide(color: Colors.black26, width: 2)),
                ),

                // Interactividad corregida: Mostrar el valor exacto al pasar el mouse
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Colors.blueGrey,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "Puntaje: ${spot.x.toStringAsFixed(1)}",
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              // Animación fluida al aparecer
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}