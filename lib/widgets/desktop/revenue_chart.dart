import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../database/database_helper.dart';
import 'package:intl/intl.dart';

/// Gráfico de línea mostrando ingresos mensuales
class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key});

  Future<List<Map<String, dynamic>>> _getMonthlyRevenue() async {
    final sheets = await DatabaseHelper.instance.getAllSheets();
    final now = DateTime.now();
    final last6Months = <Map<String, dynamic>>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final sheet = sheets
          .where((s) => s.month == month.month && s.year == month.year)
          .firstOrNull;

      if (sheet != null) {
        final revenue = await DatabaseHelper.instance.getTotalPriceInSheet(
          sheet.id,
          onlyPending: false,
        );
        last6Months.add({
          'month': DateFormat('MMM').format(month),
          'revenue': revenue,
        });
      } else {
        last6Months.add({
          'month': DateFormat('MMM').format(month),
          'revenue': 0,
        });
      }
    }

    return last6Months;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getMonthlyRevenue(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        // Manejar caso sin datos
        if (data.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No hay datos de ingresos disponibles',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }

        final maxRevenue = data
            .map((d) => d['revenue'] as int)
            .reduce((a, b) => a > b ? a : b);
        final maxY = (maxRevenue > 0 ? maxRevenue * 1.1 : 100).toDouble();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingresos Mensuales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY > 0 ? maxY : 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(data.length, (index) {
                            return FlSpot(
                              index.toDouble(),
                              data[index]['revenue'].toDouble(),
                            );
                          }),
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green.withOpacity(0.1),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              // Format with Chilean thousand separators
                              final intValue = value.toInt();
                              if (intValue == 0) {
                                return const Text(
                                  '\$0',
                                  style: TextStyle(fontSize: 10),
                                );
                              }

                              // Use the price formatter to format with dots
                              String formatted = '';
                              final numStr = intValue.toString();
                              final reversed = numStr
                                  .split('')
                                  .reversed
                                  .join('');

                              for (int i = 0; i < reversed.length; i++) {
                                if (i > 0 && i % 3 == 0) {
                                  formatted += '.';
                                }
                                formatted += reversed[i];
                              }

                              final result = formatted
                                  .split('')
                                  .reversed
                                  .join('');
                              return Text(
                                '\$$result',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    data[value.toInt()]['month'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
