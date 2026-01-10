import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dental_base.dart';
import '../../database/database_helper.dart';
import 'dental_base_form.dart';

class DentalBaseDetail extends StatelessWidget {
  final DentalBase dentalBase;

  const DentalBaseDetail({super.key, required this.dentalBase});

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CL',
    );
    return formatter.format(amount);
  }

  Future<void> _deleteBase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar la base OA ${dentalBase.oa}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await DatabaseHelper.instance.deleteDentalBase(dentalBase.oa);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Base eliminada'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: const Color(0xFF4DB6AC),
                    iconSize: 28,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OA ${dentalBase.oa}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4DB6AC),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    color: const Color(0xFF4DB6AC),
                    iconSize: 28,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DentalBaseForm(dentalBase: dentalBase),
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // CONTENIDO
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // CARD PRINCIPAL
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(
                            'OA',
                            dentalBase.oa.toString(),
                            Icons.tag,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            'Doctor',
                            dentalBase.doctorName,
                            Icons.medical_services,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            'Estado',
                            dentalBase.estado.name,
                            Icons.build_circle,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            'Paciente',
                            dentalBase.patientName,
                            Icons.person,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            'RUT Paciente',
                            dentalBase.patientRUT,
                            Icons.badge,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            'Acción',
                            dentalBase.action,
                            Icons.construction,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            'Observaciones',
                            dentalBase.observations,
                            Icons.note,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            'Fecha de Entrada',
                            DateFormat(
                              'dd/MM/yyyy',
                            ).format(dentalBase.entryDate),
                            Icons.login,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            'Fecha de Salida',
                            DateFormat(
                              'dd/MM/yyyy',
                            ).format(dentalBase.exitDate),
                            Icons.logout,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            'Precio',
                            _formatCurrency(dentalBase.price),
                            Icons.attach_money,
                            highlighted: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // BOTÓN ELIMINAR
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteBase(context),
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text(
                          'Eliminar Base',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon, {
    bool highlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: highlighted
                ? Colors.green.shade50
                : const Color(0xFF4DB6AC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: highlighted
                ? Colors.green.shade700
                : const Color(0xFF4DB6AC),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: highlighted ? FontWeight.bold : FontWeight.w600,
                  color: highlighted
                      ? Colors.green.shade700
                      : const Color(0xFF37474F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
