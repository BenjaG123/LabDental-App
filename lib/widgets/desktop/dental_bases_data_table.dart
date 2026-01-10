import 'package:flutter/material.dart';
import '../../models/dental_base.dart';
import '../../models/base_state.dart';
import 'package:intl/intl.dart';

/// Tabla de datos para bases dentales (desktop)
class DentalBasesDataTable extends StatelessWidget {
  final List<DentalBase> bases;
  final Function(DentalBase) onEdit;
  final Function(DentalBase) onDelete;

  const DentalBasesDataTable({
    super.key,
    required this.bases,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (bases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay bases en esta hoja',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              const Color(0xFF4DB6AC).withOpacity(0.1),
            ),
            headingRowHeight: 56,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            columns: const [
              DataColumn(
                label: Text(
                  'OA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Doctor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Paciente',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'RUT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Acción',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Estado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Precio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'F. Salida',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Acciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: bases.map((base) => _buildDataRow(context, base)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, DentalBase base) {
    return DataRow(
      cells: [
        DataCell(Text('#${base.oa}')),
        DataCell(Text(base.doctorName)),
        DataCell(Text(base.patientName)),
        DataCell(Text(base.patientRUT)),
        DataCell(
          Text(base.action, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        DataCell(_buildStatusChip(base.estado)),
        DataCell(Text(_formatCurrency(base.price))),
        DataCell(Text(DateFormat('dd/MM/yy').format(base.exitDate))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: const Color(0xFF4DB6AC),
                tooltip: 'Editar',
                onPressed: () => onEdit(base),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                tooltip: 'Eliminar',
                onPressed: () => onDelete(base),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BaseState estado) {
    Color color = estado.id == 5 ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        estado.name,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,##0', 'es_CL');
    return '\$ ${formatter.format(amount)}';
  }
}
