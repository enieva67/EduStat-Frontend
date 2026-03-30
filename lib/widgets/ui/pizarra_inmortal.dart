import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../services/websocket_service.dart';

// Importamos los gráficos (Suben un nivel de carpeta '..' porque están en /widgets)
import '../grafico_media.dart';
import '../grafico_histograma.dart';
import '../grafico_curva_normal.dart';
import '../grafico_dispersion.dart';

class PizarraInmortal extends StatelessWidget {
  const PizarraInmortal({super.key});

  @override
  Widget build(BuildContext context) {
    // Instanciamos nuestro Singleton (Mantiene la misma conexión viva)
    final wsService = WebSocketService();

    return Expanded(
      flex: 2,
      child: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: wsService.mathResult,
        builder: (context, result, child) {
          if (result == null) {
            return const Center(
              child: Text(
                "Selecciona un nivel o sube un archivo para ver la magia.", 
                style: TextStyle(fontSize: 18, color: Colors.grey)
              )
            );
          }
          
          List<dynamic> pasos = result['pasos'] ??[];
          String simboloRespuesta = result['simbolo_estadistico'] ?? '';
          bool mostrarGraficoPuntos = simboloRespuesta.contains('\\bar{x}') || 
                                      simboloRespuesta.contains('Me') || 
                                      simboloRespuesta.contains('P_');

          // -----------------------------------------------------------------
          // 1. LÓGICA DE UX PARA LA CURVA NORMAL Y TEXTOS DINÁMICOS
          // -----------------------------------------------------------------
          bool esPoderEstadistico = result['tema'] != null && result['tema'].toString().contains('Poder');
          bool esPruebaHipotesis = simboloRespuesta.contains('P_val') || simboloRespuesta.contains('\\chi^2');

          String tituloCurva = "La Campana de Gauss";
          String subtituloCurva = "El paciente (línea dorada) obtuvo un Z =";
          String etiquetaX1Curva = "X1";

          if (esPoderEstadistico) {
            tituloCurva = "Zonas: Alfa (Rojo), Beta (Gris) y Poder (Verde)";
            subtituloCurva = "Línea Dorada = Valor Crítico de Alfa. Desplazamiento H₁ = ${result['paciente_z']}";
            etiquetaX1Curva = "Corte α";
          } else if (simboloRespuesta.contains('IC')) {
            tituloCurva = "Distribución Muestral (${result['percentil']}%)";
            subtituloCurva = "La zona dorada marca dónde podría estar la Media Poblacional (μ).";
            etiquetaX1Curva = "L. Inf";
          } else if (simboloRespuesta.contains('\\chi^2')) {
            tituloCurva = "Distribución Ji-Cuadrado (χ²)";
            subtituloCurva = "Tu estadístico (línea dorada) cayó en: ${(result['interpretacion'] ?? '').contains('NO RECHAZAMOS') ? 'Zona Segura' : 'ZONA DE PELIGRO (Rechazo)'}";
            etiquetaX1Curva = "Estadístico";
          } else if (simboloRespuesta.contains('P_val')) {
            tituloCurva = "Zonas de Rechazo (Alfa: ${result['percentil'] / 100})";
            subtituloCurva = "Tu muestra (línea dorada) cayó en: ${(result['interpretacion'] ?? '').contains('NO RECHAZAMOS') ? 'Zona Segura' : 'ZONA DE PELIGRO'}";
            etiquetaX1Curva = "Muestra";
          }

          // Textos para el gráfico de puntos
          String tituloPuntos = "Visualización";
          String subtituloPuntos = "";
          String etiquetaPuntos = "Valor";

          if (simboloRespuesta.contains('\\bar{x}')) {
            tituloPuntos = "El Punto de Equilibrio (Media)";
            subtituloPuntos = "La línea roja (Media) equilibra el peso de todos los pacientes.";
            etiquetaPuntos = "Media";
          } else if (simboloRespuesta.contains('Me')) {
            tituloPuntos = "El Centro Exacto (Mediana)";
            subtituloPuntos = "La línea roja divide a los pacientes exactamente en dos mitades (50% y 50%).";
            etiquetaPuntos = "Mediana";
          } else if (simboloRespuesta.contains('P_')) {
            tituloPuntos = "Línea de Corte (Percentil)";
            subtituloPuntos = "La línea roja separa a la población según el porcentaje buscado.";
            etiquetaPuntos = "Corte";
          }

          // -----------------------------------------------------------------
          // 2. RENDERIZADO VISUAL
          // -----------------------------------------------------------------
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
                            decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.withValues(alpha: 0.3))),
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
                padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber)),
                child: Text("💡 Conclusión: ${result['interpretacion']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
              
              // -----------------------------------------------------------------
              // 3. RENDERIZADO DINÁMICO DE GRÁFICOS
              // -----------------------------------------------------------------
              
              // A. Gráfico de Puntos
              if (result['datos_originales'] != null && result['resultado_final'] is num && mostrarGraficoPuntos) 
                GraficoMediaAritmetica(
                  datos: List<double>.from(result['datos_originales'].map((e) => (e as num).toDouble())),
                  media: (result['resultado_final'] as num).toDouble(),
                  contexto: result['contexto'] ?? "Valores",
                  titulo: tituloPuntos,
                  subtitulo: subtituloPuntos,
                  etiquetaLinea: etiquetaPuntos,
                ),

              // B. Histograma
              if (result['datos_histograma'] != null)
                GraficoHistograma(datosHistograma: result['datos_histograma'], contexto: result['contexto'] ?? "Valores"),
              
              // C. Curva Normal, IC, Hipótesis, Ji-Cuadrado y Poder
              if (result['datos_curva'] != null)
                GraficoCurvaNormal(
                  datosCurva: result['datos_curva'],
                  sombreado1: result['sombreado_1'] ?? List.empty(),
                  sombreado2: result['sombreado_2'] ?? List.empty(),
                  sombreado3: result['sombreado_3'] ?? List.empty(), 
                  pacienteX: (result['paciente_x'] as num).toDouble(),
                  pacienteZ: (result['paciente_z'] as num).toDouble(),
                  percentil: result['percentil'] != null ? (result['percentil'] as num).toDouble() : 0.0, 
                  pacienteX2: result['paciente_x2'] != null ? (result['paciente_x2'] as num).toDouble() : null,
                  tipoArea: result['tipo_area'] ?? 'menor',
                  esPruebaHipotesis: esPruebaHipotesis,
                  esPoderEstadistico: esPoderEstadistico, 
                  datosCurva2: result['datos_curva2'], 
                  titulo: tituloCurva,
                  subtitulo: subtituloCurva,
                  etiquetaX1: etiquetaX1Curva,
                  etiquetaX2: simboloRespuesta.contains('IC') ? "L. Sup" : "X2",
                ),
                
              // D. Gráfico de Dispersión (Bivariada)
              if (result['datos_x'] != null && result['datos_y'] != null &&['r', '\\rho', '\\phi'].any((s) => simboloRespuesta.contains(s)))
                GraficoDispersion(
                  datosX: List<double>.from(result['datos_x'].map((e) => (e as num).toDouble())),
                  datosY: List<double>.from(result['datos_y'].map((e) => (e as num).toDouble())),
                  titulo: "Gráfico de Dispersión",
                  labelX: result['contexto']?.split(' vs ')[0] ?? "X",
                  labelY: result['contexto']?.split(' vs ')[1] ?? "Y",
                ),
                
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
