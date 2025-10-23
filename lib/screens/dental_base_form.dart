import 'package:flutter/material.dart';
import '../models/dental_base.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';

class DentalBaseForm extends StatefulWidget {
  final DentalBase? dentalBase;

  const DentalBaseForm({super.key, this.dentalBase});

  @override
  State<DentalBaseForm> createState() => _DentalBaseFormState();
}

class _DentalBaseFormState extends State<DentalBaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _baseType = 'Completa';
  String _status = 'Pendiente';
  DateTime _creationDate = DateTime.now();
  DateTime? _deliveryDate;
  
  final List<String> _baseTypes = ['Completa', 'Parcial', 'Provisional', 'Otra'];
  final List<String> _statusOptions = ['Pendiente', 'En proceso', 'Terminada', 'Entregada'];

  @override
  void initState() {
    super.initState();
    if (widget.dentalBase != null) {
      _patientNameController.text = widget.dentalBase!.patientName;
      _baseType = widget.dentalBase!.baseType;
      _creationDate = widget.dentalBase!.creationDate;
      _deliveryDate = widget.dentalBase!.deliveryDate;
      _status = widget.dentalBase!.status;
      _notesController.text = widget.dentalBase!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDeliveryDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDeliveryDate ? (_deliveryDate ?? DateTime.now()) : _creationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (isDeliveryDate) {
          _deliveryDate = picked;
        } else {
          _creationDate = picked;
        }
      });
    }
  }

  Future<void> _saveDentalBase() async {
    if (_formKey.currentState!.validate()) {
      final dentalBase = DentalBase(
        id: widget.dentalBase?.id,
        patientName: _patientNameController.text,
        baseType: _baseType,
        creationDate: _creationDate,
        deliveryDate: _deliveryDate,
        status: _status,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (widget.dentalBase == null) {
        await DatabaseHelper.instance.insertDentalBase(dentalBase);
      } else {
        await DatabaseHelper.instance.updateDentalBase(dentalBase);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dentalBase == null ? 'Nueva Base Dental' : 'Editar Base Dental'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Paciente',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del paciente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _baseType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Base',
                  border: OutlineInputBorder(),
                ),
                items: _baseTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _baseType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Fecha de Creación'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_creationDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Fecha de Entrega (Opcional)'),
                subtitle: _deliveryDate != null
                    ? Text(DateFormat('dd/MM/yyyy').format(_deliveryDate!))
                    : const Text('No establecida'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _status = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveDentalBase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.dentalBase == null ? 'Guardar' : 'Actualizar',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}