import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

/// Widget mostrando top 5 doctores por bases producidas
class TopDoctorsWidget extends StatelessWidget {
  const TopDoctorsWidget({super.key});

  Future<List<Map<String, dynamic>>> _getTopDoctors() async {
    // Obtener todas las bases
    final sheets = await DatabaseHelper.instance.getAllSheets();
    final Map<String, int> doctorCounts = {};

    for (final sheet in sheets) {
      final bases = await DatabaseHelper.instance.getDentalBasesBySheet(
        sheet.id,
        onlyPending: false,
      );

      for (final base in bases) {
        doctorCounts[base.doctorName] =
            (doctorCounts[base.doctorName] ?? 0) + 1;
      }
    }

    // Convertir a lista y ordenar
    final topDoctors =
        doctorCounts.entries
            .map((e) => {'name': e.key, 'count': e.value})
            .toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return topDoctors.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getTopDoctors(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final doctors = snapshot.data!;

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
                  'Top Doctores',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Por número de bases producidas',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                if (doctors.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No hay datos disponibles',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: doctors.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        final position = index + 1;
                        final medalColor = position == 1
                            ? Colors.amber
                            : position == 2
                            ? Colors.grey.shade400
                            : position == 3
                            ? Colors.brown.shade300
                            : Colors.grey.shade300;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: medalColor.withOpacity(0.2),
                            child: Text(
                              '$position',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: medalColor,
                              ),
                            ),
                          ),
                          title: Text(
                            doctor['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4DB6AC).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${doctor['count']} bases',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4DB6AC),
                              ),
                            ),
                          ),
                        );
                      },
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
