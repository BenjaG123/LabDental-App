import 'package:flutter/material.dart';
import '../models/dental_base.dart';
import 'package:intl/intl.dart';
import 'dental_base_form.dart';

class DentalBaseDetail extends StatelessWidget {
  final DentalBase dentalBase;

  const DentalBaseDetail({super.key, required this.dentalBase});

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
              'Detalle de Base Dental',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DentalBaseForm(dentalBase: dentalBase),
                    ),
                  ).then((_) => Navigator.pop(context));
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem('OA (ID)', dentalBase.oa.toString()),
                  const Divider(),
                  _buildDetailItem('Doctor', dentalBase.doctorName),
                  const Divider(),
                  _buildDetailItem('Paciente', dentalBase.patientName),
                  const Divider(),
                  _buildDetailItem('RUT Paciente', dentalBase.patientRUT),
                  const Divider(),
                  _buildDetailItem('Acción', dentalBase.action),
                  const Divider(),
                  _buildDetailItem(
                    'Fecha de Entrada',
                    DateFormat('dd/MM/yyyy').format(dentalBase.entryDate),
                  ),
                  const Divider(),
                  _buildDetailItem(
                    'Fecha de Salida',
                    DateFormat('dd/MM/yyyy').format(dentalBase.exitDate),
                  ),
                  const Divider(),
                  _buildDetailItem('Precio', '\$${dentalBase.price}'),
                  const Divider(),
                  _buildDetailItem('Observaciones', dentalBase.observations),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
