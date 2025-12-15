import 'package:flutter/material.dart';
import '../models/dental_base.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';
import '../models/base_state.dart';
import '../utils/rut_formatter.dart';

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
  BaseState _selectedState = BaseState.cubeta;

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
      _selectedState = widget.dentalBase!.estado;
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
        estado: _selectedState,
      );

      try {
        final sheet = await DatabaseHelper.instance.getOrCreateSheetForDate(
          _exitDate,
        );

        if (widget.dentalBase == null) {
          // Crear nueva base
          await DatabaseHelper.instance.insertDentalBase(dentalBase);
          // Solo vincular cuando es nueva
          await DatabaseHelper.instance.linkDentalBaseToSheet(
            dentalBase.oa,
            sheet.id,
          );
        } else {
          // Solo actualizar, NO vincular de nuevo
          await DatabaseHelper.instance.updateDentalBase(dentalBase);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Base guardada en : ${sheet.getSheetName()}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _selectEntryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4DB6AC)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _entryDate) {
      setState(() => _entryDate = picked);
    }
  }

  Future<void> _selectExitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _exitDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4DB6AC)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _exitDate) {
      setState(() => _exitDate = picked);
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
                      widget.dentalBase == null ? 'Nueva Base' : 'Editar Base',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4DB6AC),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FORMULARIO
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // OA
                      TextFormField(
                        controller: _oaController,
                        decoration: InputDecoration(
                          labelText: 'OA',
                          prefixIcon: const Icon(
                            Icons.tag,
                            color: Color(0xFF4DB6AC),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4DB6AC),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        enabled: widget.dentalBase == null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo requerido';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Debe ser un número';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // DOCTOR
                      TextFormField(
                        controller: _doctorNameController,
                        decoration: InputDecoration(
                          labelText: 'Doctor',
                          prefixIcon: const Icon(
                            Icons.medical_services,
                            color: Color(0xFF4DB6AC),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4DB6AC),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Campo requerido'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // PACIENTE
                      TextFormField(
                        controller: _patientNameController,
                        decoration: InputDecoration(
                          labelText: 'Paciente',
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Color(0xFF4DB6AC),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4DB6AC),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Campo requerido'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // RUT
                      TextFormField(
                        controller: _patientRutController,
                        decoration: InputDecoration(
                          labelText: 'RUT Paciente',
                          hintText: '12.345.678-9',
                          prefixIcon: const Icon(
                            Icons.badge,
                            color: Color(0xFF4DB6AC),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4DB6AC),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        inputFormatters: [RutInputFormatter()],
                        keyboardType: TextInputType.text,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Campo requerido'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // ACCIÓN
                      TextFormField(
                        controller: _actionController,
                        decoration: InputDecoration(
                          labelText: 'Acción',
                          prefixIcon: const Icon(
                            Icons.construction,
                            color: Color(0xFF4DB6AC),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4DB6AC),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Campo requerido'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // OBSERVACIONES
                      TextFormField(
                        controller: _observationsController,
                        decoration: InputDecoration(
                          labelText: 'Observaciones',
                          prefixIcon: const Icon(
                            Icons.note,
                            color: Color(0xFF4DB6AC),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4DB6AC),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Campo requerido'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // PRECIO
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Precio',
                          prefixIcon: const Icon(
                            Icons.attach_money,
                            color: Color(0xFF4DB6AC),
                          ),
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4DB6AC),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo requerido';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Debe ser un número';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ESTADO
                      DropdownButtonFormField<BaseState>(
                        value: _selectedState,
                        decoration: InputDecoration(
                          labelText: 'Estado',
                          prefixIcon: const Icon(
                            Icons.build_circle,
                            color: Color(0xFF4DB6AC),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4DB6AC),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: BaseState.allStates.map((estado) {
                          return DropdownMenuItem(
                            value: estado,
                            child: Text(estado.name),
                          );
                        }).toList(),
                        onChanged: (BaseState? nuevoEstado) {
                          if (nuevoEstado != null) {
                            setState(() => _selectedState = nuevoEstado);
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Seleccione un estado' : null,
                      ),
                      const SizedBox(height: 24),

                      // FECHAS
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.login,
                                        size: 20,
                                        color: Color(0xFF4DB6AC),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Fecha Entrada',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _selectEntryDate,
                                    child: Text(
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_entryDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF37474F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.logout,
                                        size: 20,
                                        color: Color(0xFF4DB6AC),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Fecha Salida',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _selectExitDate,
                                    child: Text(
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_exitDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF37474F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // BOTÓN GUARDAR
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveDentalBase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4DB6AC),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Guardar Base',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
