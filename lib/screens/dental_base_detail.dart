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
      appBar: AppBar(
        title: const Text('Detalle de Base Dental'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DentalBaseForm(dentalBase: dentalBase),
                ),
              ).then((_) => Navigator.pop(context));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Paciente', dentalBase.patientName),
                const Divider(),
                _buildDetailItem('Tipo de Base', dentalBase.baseType),
                const Divider(),
                _buildDetailItem('Estado', dentalBase.status),
                const Divider(),
                _buildDetailItem(
                  'Fecha de Creación',
                  DateFormat('dd/MM/yyyy').format(dentalBase.creationDate),
                ),
                const Divider(),
                _buildDetailItem(
                  'Fecha de Entrega',
                  dentalBase.deliveryDate != null
                      ? DateFormat('dd/MM/yyyy').format(dentalBase.deliveryDate!)
                      : 'No establecida',
                ),
                if (dentalBase.notes != null && dentalBase.notes!.isNotEmpty) ...[
                  const Divider(),
                  _buildDetailItem('Notas', dentalBase.notes!),
                ],
              ],
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}