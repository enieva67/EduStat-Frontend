import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraficoHistograma extends StatelessWidget {
  final List<dynamic> datosHistograma;
  final String contexto;

  const GraficoHistograma({
    super.key,
    required this.datosHistograma,
    required this.contexto,
  });

  @override
  Widget build(BuildContext context) {
    if (datosHistograma.isEmpty) return const SizedBox.shrink();

    // Calculamos la altura máxima (frecuencia mayor) para que el gráfico respire
    double maxY = 0;
    for (var item in datosHistograma) {
      final f = (item['f'] as num).toDouble();
      if (f > maxY) maxY = f;
    }
    maxY += 2; // Margen superior

    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
        boxShadow:[
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ]
      ),
      child: Column(
        children:[
          const Text(
            "Visualización: El Histograma de Frecuencias",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 5),
          const Text(
            "Nota Didáctica: A diferencia de un gráfico de barras común, aquí las barras SE TOCAN porque representan una variable numérica continua.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 25),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center, // Centra las barras
                maxY: maxY,
                // LA MAGIA: groupsSpace en 0 hace que las barras se peguen (Límites Reales)
                groupsSpace: 0, 
                
                // INTERACTIVIDAD: El Tooltip educativo
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.deepPurpleAccent,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = datosHistograma[group.x];
                      return BarTooltipItem(
                        "Intervalo: ${data['intervalo']}\n",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        children: <TextSpan>[
                          TextSpan(
                            text: "Marca de Clase (xᵢ): ${data['xi']}\n",
                            style: const TextStyle(color: Colors.yellowAccent, fontSize: 12),
                          ),
                          TextSpan(
                            text: "Frecuencia (f): ${data['f']}",
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  // Eje Y: Las Frecuencias
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text("Frecuencia (f)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    sideTitles: SideTitles(
                      showTitles: true, 
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) { // Solo mostrar números enteros
                          return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.black54));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  // Eje X: Las Marcas de Clase
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(top: 3.0),
                      child: Text("Marcas de Clase (xᵢ)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < datosHistograma.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 3.0),
                            child: Text(
                              datosHistograma[index]['xi'].toString(),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2, // Líneas guía horizontales
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Colors.black45, width: 2),
                    left: BorderSide(color: Colors.black45, width: 2),
                  ),
                ),
                
                // Dibujamos las barras
                barGroups: datosHistograma.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final freq = (data['f'] as num).toDouble();
                  
                  return BarChartGroupData(
                    x: index,
                    barRods:[
                      BarChartRodData(
                        toY: freq,
                        color: Colors.deepPurple.withValues(alpha: 0.3),
                        width: 60, // Ancho generoso para que se toquen
                        borderRadius: BorderRadius.zero, // TOPE PLANO, típico de Histograma
                        borderSide: const BorderSide(color: Colors.white, width: 1), // Línea divisoria blanca para distinguir los bloques
                      )
                    ],
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}
