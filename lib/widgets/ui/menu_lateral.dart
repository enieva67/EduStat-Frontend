import 'package:flutter/material.dart';

class MenuLateral extends StatelessWidget {
  // EXIGIMOS UNA FUNCIÓN: El menú no guarda estado, solo avisa qué se tocó
  final Function(String) onMenuSeleccionado;

  const MenuLateral({super.key, required this.onMenuSeleccionado});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children:[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Text(
              'Módulos de EduStat', 
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
            ),
          ),
          ExpansionTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('1. Estadística Descriptiva', style: TextStyle(fontWeight: FontWeight.bold)),
            children:[
              ListTile(title: const Text("Media"), onTap: () { onMenuSeleccionado('media'); Navigator.pop(context); }),
              ListTile(title: const Text("Mediana"), onTap: () { onMenuSeleccionado('mediana'); Navigator.pop(context); }),
              ListTile(title: const Text("Moda"), onTap: () { onMenuSeleccionado('moda'); Navigator.pop(context); }),
              ListTile(title: const Text("Varianza"), onTap: () { onMenuSeleccionado('varianza'); Navigator.pop(context); }),
              ListTile(title: const Text("Percentiles"), onTap: () { onMenuSeleccionado('percentil'); Navigator.pop(context); }),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.analytics),
            title: const Text('2. Curva Normal', style: TextStyle(fontWeight: FontWeight.bold)),
            children:[
              ListTile(title: const Text("Puntaje Z y Probabilidades"), onTap: () { onMenuSeleccionado('puntaje_z'); Navigator.pop(context); }),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.scatter_plot),
            title: const Text('3. Correlación (Bivariada)', style: TextStyle(fontWeight: FontWeight.bold)),
            children:[
              ListTile(title: const Text("r de Pearson (Paramétrica)"), onTap: () { onMenuSeleccionado('pearson'); Navigator.pop(context); }),
              ListTile(title: const Text("Rho de Spearman (No Paramétrica)"), onTap: () { onMenuSeleccionado('spearman'); Navigator.pop(context); }),
              ListTile(title: const Text("Coeficiente Phi (Dicotómicas)"), onTap: () { onMenuSeleccionado('phi'); Navigator.pop(context); }),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.psychology),
            title: const Text('4. Estadística Inferencial', style: TextStyle(fontWeight: FontWeight.bold)),
            children:[
              ListTile(title: const Text("Intervalos de Confianza"), onTap: () { onMenuSeleccionado('intervalo_confianza'); Navigator.pop(context); }),
              ListTile(title: const Text("Pruebas de Hipótesis"), onTap: () { onMenuSeleccionado('prueba_hipotesis'); Navigator.pop(context); }),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.category),
            title: const Text('5. Estadística Categórica', style: TextStyle(fontWeight: FontWeight.bold)),
            children:[
              ListTile(title: const Text("Ji-Cuadrado (Bondad de Ajuste)"), onTap: () { onMenuSeleccionado('chi2_bondad'); Navigator.pop(context); }),
              ListTile(title: const Text("Ji-Cuadrado (Independencia)"), onTap: () { onMenuSeleccionado('chi2_independencia'); Navigator.pop(context); }),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.battery_charging_full),
            title: const Text('6. Poder Estadístico', style: TextStyle(fontWeight: FontWeight.bold)),
            children:[
              ListTile(title: const Text("Poder y Tamaño de Muestra"), onTap: () { onMenuSeleccionado('poder_estadistico'); Navigator.pop(context); }),
            ],
          ),
           ExpansionTile(
            leading: const Icon(Icons.people_alt),
            title: const Text('7. Comparación de Grupos', style: TextStyle(fontWeight: FontWeight.bold)),
            children:[
              ListTile(title: const Text("T de Student (Independientes)"), onTap: () { onMenuSeleccionado('ttest_indep'); Navigator.pop(context); }),
              ListTile(title: const Text("U de Mann-Whitney (No Paramétrico)"), onTap: () { onMenuSeleccionado('mann_whitney'); Navigator.pop(context); }),
              ListTile(title: const Text("Prueba Z (Dos Proporciones)"), onTap: () { onMenuSeleccionado('z_proporciones'); Navigator.pop(context); }),
            ],
          ),
        ],
      ),
    );
  }
}
