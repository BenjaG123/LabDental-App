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
      appBar: AppBar(
        title: const Text('Bases Dentales'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<DentalBase>>(
        future: _dentalBasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay bases dentales registradas'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final dentalBase = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    title: Text(dentalBase.patientName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tipo: ${dentalBase.baseType}'),
                        Text('Estado: ${dentalBase.status}'),
                        Text('Creación: ${DateFormat('dd/MM/yyyy').format(dentalBase.creationDate)}'),
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
                                builder: (context) => DentalBaseForm(dentalBase: dentalBase),
                              ),
                            );
                            _refreshDentalBases();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmar eliminación'),
                                content: const Text('¿Está seguro de eliminar esta base dental?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await DatabaseHelper.instance.deleteDentalBase(dentalBase.id!);
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
                          builder: (context) => DentalBaseDetail(dentalBase: dentalBase),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DentalBaseForm(),
            ),
          );
          _refreshDentalBases();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}