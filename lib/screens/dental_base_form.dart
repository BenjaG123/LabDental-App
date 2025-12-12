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

  final _oaController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _patientRutController = TextEditingController();
  final _actionController = TextEditingController();
  final _observationsController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime _entryDate = DateTime.now();
  DateTime _exitDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.dentalBase != null) {
      _oaController.text = widget.dentalBase!.oa.toString();
      _doctorNameController.text = widget.dentalBase!.doctorName;
      _patientNameController.text = widget.dentalBase!.patientName;
      _patientRutController.text = widget.dentalBase!.patientRUT;
      _actionController.text = widget.dentalBase!.action;
      _observationsController.text = widget.dentalBase!.observations;
      _priceController.text = widget.dentalBase!.price.toString();
      _entryDate = widget.dentalBase!.entryDate;
      _exitDate = widget.dentalBase!.exitDate;
    }
  }

  @override
  void dispose() {
    _oaController.dispose();
    _doctorNameController.dispose();
    _patientNameController.dispose();
    _patientRutController.dispose();
    _actionController.dispose();
    _observationsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isExitDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isExitDate ? _exitDate : _entryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isExitDate) {
          _exitDate = picked;
        } else {
          _entryDate = picked;
        }
      });
    }
  }

  Future<void> _saveDentalBase() async {
    if (_formKey.currentState!.validate()) {
      final dentalBase = DentalBase(
        oa: int.parse(_oaController.text),
        doctorName: _doctorNameController.text,
        patientName: _patientNameController.text,
        patientRUT: _patientRutController.text,
        action: _actionController.text,
        observations: _observationsController.text,
        entryDate: _entryDate,
        exitDate: _exitDate,
        price: int.parse(_priceController.text),
      );

      if (widget.dentalBase == null) {
        // Insert (OA must be unique, handled by DB constraint if duplicate)
        try {
          await DatabaseHelper.instance.insertDentalBase(dentalBase);
          if (mounted) Navigator.pop(context);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
          }
        }
      } else {
        // Update
        await DatabaseHelper.instance.updateDentalBase(dentalBase);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If editing, disable OA field? Usually PK shouldn't change.
    // However, if it's a manual tracking number, user might want to correct it.
    // But updating PK in DB is tricky. Let's assume for now it's editable but warned.
    // Or better, read-only if editing.
    bool isEditing = widget.dentalBase != null;

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
            title: Text(
              isEditing ? 'Editar Base Dental' : 'Nueva Base Dental',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // OA Field
              TextFormField(
                controller: _oaController,
                decoration: const InputDecoration(
                  labelText: 'OA',
                  border: OutlineInputBorder(),
                  helperText: 'Número de Orden de Atención',
                ),
                keyboardType: TextInputType.number,
                readOnly:
                    isEditing, // Make read-only when editing to prevent PK issues
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el OA';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Debe ser un número entero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Doctor Field
              TextFormField(
                controller: _doctorNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Doctor',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese nombre del doctor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Patient Name
              TextFormField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Paciente',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese nombre del paciente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Patient RUT
              TextFormField(
                controller: _patientRutController,
                decoration: const InputDecoration(
                  labelText: 'RUT del Paciente',
                  border: OutlineInputBorder(),
                  helperText: 'Formato: 12345678-9',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese RUT del paciente';
                  }
                  // Validar formato RUT: 8-9 dígitos, guión, dígito verificador (0-9 o K)
                  final rutRegex = RegExp(r'^\d{7,8}-[\dkK]$');
                  if (!rutRegex.hasMatch(value)) {
                    return 'Formato inválido. Ej: 12345678-9';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Action
              TextFormField(
                controller: _actionController,
                decoration: const InputDecoration(
                  labelText: 'Acción',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la acción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el precio';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Debe ser un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dates Row
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Fecha Entrada'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(_entryDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListTile(
                      title: const Text('Fecha Salida'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(_exitDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Observations
              TextFormField(
                controller: _observationsController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese observaciones';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveDentalBase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isEditing ? 'Actualizar' : 'Guardar',
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
