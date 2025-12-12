import 'package:flutter/material.dart';
import '../models/dental_base.dart';
import '../database/database_helper.dart';
import 'dental_base_form.dart';
import 'dental_base_detail.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<DentalBase>> _dentalBasesFuture;

  @override
  void initState() {
    super.initState();
    _refreshDentalBases();
  }

  Future<void> _refreshDentalBases() async {
    setState(() {
      _dentalBasesFuture = DatabaseHelper.instance.getAllDentalBases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade400],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            title: const Text(
              'Bases Dentales',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
      body: FutureBuilder<List<DentalBase>>(
        future: _dentalBasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay bases dentales registradas'),
            );
          } else {
            // Calcular estadísticas
            final totalBases = snapshot.data!.length;
            final totalGanancias = snapshot.data!.fold<int>(
              0,
              (sum, base) => sum + base.price,
            );

            return Column(
              children: [
                // Cards de estadísticas
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Card de Total de Bases
                      Expanded(
                        child: Card(
                          elevation: 4,
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.medical_services,
                                  size: 32,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$totalBases',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const Text(
                                  'Bases Realizadas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Card de Total de Ganancias
                      Expanded(
                        child: Card(
                          elevation: 4,
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  size: 32,
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${totalGanancias.toString()}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const Text(
                                  'Total Ganancias',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de bases
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final dentalBase = snapshot.data![index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 2,
                        child: ListTile(
                          title: Text('${dentalBase.patientName}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Doctor: ${dentalBase.doctorName}'),
                              Text('Acción: ${dentalBase.action}'),
                              Text(
                                'Entrada: ${DateFormat('dd/MM/yyyy').format(dentalBase.entryDate)}',
                              ),
                              Text(
                                'Salida: ${DateFormat('dd/MM/yyyy').format(dentalBase.exitDate)}',
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DentalBaseForm(
                                        dentalBase: dentalBase,
                                      ),
                                    ),
                                  );
                                  _refreshDentalBases();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: const Color.fromARGB(255, 143, 44, 37),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                        'Confirmar eliminación',
                                      ),
                                      content: Text(
                                        '¿Está seguro de eliminar la base OA ${dentalBase.oa}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await DatabaseHelper.instance
                                                .deleteDentalBase(
                                                  dentalBase.oa,
                                                );
                                            Navigator.pop(context);
                                            _refreshDentalBases();
                                          },
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DentalBaseDetail(dentalBase: dentalBase),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DentalBaseForm()),
          );
          _refreshDentalBases();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
