import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraficoPizzaPage extends StatefulWidget {
  final Map<String, int> dados; // Recebendo os dados como Map<String, int>

  const GraficoPizzaPage({
    super.key,
    required this.dados,
  }); // Construtor correto

  @override
  _GraficoPizzaPageState createState() => _GraficoPizzaPageState();
}

class _GraficoPizzaPageState extends State<GraficoPizzaPage> {
  @override
  Widget build(BuildContext context) {
    final total = widget.dados.values.fold(
      0,
      (a, b) => a + b,
    ); // Total da contagem

    return Scaffold(
      appBar: AppBar(title: Text('Gráfico de Status')),
      body: Center(
        child: PieChart(
          PieChartData(
            sections:
                widget.dados.entries.map((entry) {
                  final percent = (entry.value / total) * 100;
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${entry.key} (${percent.toStringAsFixed(1)}%)',
                    color: _getColor(entry.key),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  // Função para definir a cor de cada status
  Color _getColor(String status) {
    switch (status) {
      case 'A':
        return Colors.deepPurple;
      case 'P':
        return Colors.blue;
      case 'R':
        return Colors.green;
      case 'C':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
