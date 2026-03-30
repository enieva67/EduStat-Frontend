import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class GraficoDispersion extends StatelessWidget {
  final List<double> datosX;
  final List<double> datosY;
  final String titulo;
  final String labelX;
  final String labelY;

  const GraficoDispersion({
    super.key,
    required this.datosX,
    required this.datosY,
    required this.titulo,
    required this.labelX,
    required this.labelY,
  });

  @override
  Widget build(BuildContext context) {
    if (datosX.isEmpty || datosY.isEmpty || datosX.length != datosY.length) return const SizedBox.shrink();

    final List<FlSpot> spots = List.empty(growable: true);
    double minX = datosX.reduce(min), maxX = datosX.reduce(max);
    double minY = datosY.reduce(min), maxY = datosY.reduce(max);

    // Damos margen para que los puntos no toquen los bordes
    double margenX = (maxX - minX) * 0.1;
    double margenY = (maxY - minY) * 0.1;
    if (margenX == 0) margenX = 1;
    if (margenY == 0) margenY = 1;

    for (int i = 0; i < datosX.length; i++) {
      spots.add(FlSpot(datosX[i], datosY[i]));
    }

    // Calcular la línea de tendencia (Regresión Lineal Simple para dibujar la recta)
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = datosX.length;
    for (int i = 0; i < n; i++) {
      sumX += datosX[i]; sumY += datosY[i];
      sumXY += datosX[i] * datosY[i]; sumX2 += datosX[i] * datosX[i];
    }
    double pendiente = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double interseccion = (sumY - pendiente * sumX) / n;

    // Puntos de inicio y fin de la línea de tendencia
    FlSpot puntoInicio = FlSpot(minX, pendiente * minX + interseccion);
    FlSpot puntoFin = FlSpot(maxX, pendiente * maxX + interseccion);

    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 2),
        boxShadow:[BoxShadow(color: Colors.blue.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)]
      ),
      child: Column(
        children:[
          Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 5),
          const Text("La línea azul representa la tendencia general de los datos.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX - margenX, maxX: maxX + margenX,
                minY: minY - margenY, maxY: maxY + margenY,
                lineBarsData:[
                  // 1. La línea de tendencia (continua y suave)
                  LineChartBarData(
                    spots:[puntoInicio, puntoFin],
                    isCurved: false, color: Colors.blueAccent.withValues(alpha: 0.5),
                    barWidth: 2, dotData: const FlDotData(show: false),
                  ),
                  // 2. Los puntos (Engañamos al LineChart poniéndole línea transparente)
                  LineChartBarData(
                    spots: spots,
                    isCurved: false, color: Colors.transparent,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: Colors.indigo, strokeWidth: 1, strokeColor: Colors.white)),
                  ),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(labelX, style: const TextStyle(fontWeight: FontWeight.bold))),
                    sideTitles: const SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(labelY, style: const TextStyle(fontWeight: FontWeight.bold))),
                    sideTitles: const SideTitles(showTitles: true, reservedSize: 40),
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.withValues(alpha: 0.3), strokeWidth: 1), getDrawingVerticalLine: (val) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1)),
                borderData: FlBorderData(show: true, border: const Border(bottom: BorderSide(color: Colors.black45), left: BorderSide(color: Colors.black45))),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Colors.indigo,
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem("X: ${spot.x.toStringAsFixed(1)}\nY: ${spot.y.toStringAsFixed(1)}", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList(),
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 800),
            ),
          ),
        ],
      ),
    );
  }
}
