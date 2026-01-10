import 'package:flutter/material.dart';
import '../../models/dental_base.dart';
import '../../models/base_state.dart';
import '../../database/database_helper.dart';
import '../../utils/rut_formatter.dart';
import '../../utils/string_utils.dart';
import '../../utils/input_formatters.dart';
import 'package:intl/intl.dart';

/// Dialog optimizado para agregar/editar bases rápidamente en desktop
class DentalBaseFormDialog extends StatefulWidget {
  final DentalBase? dentalBase; // null = nueva, != null = editar

  const DentalBaseFormDialog({super.key, this.dentalBase});

  @override
  State<DentalBaseFormDialog> createState() => _DentalBaseFormDialogState();
}

class _DentalBaseFormDialogState extends State<DentalBaseFormDialog> {
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
  bool _isSaving = false;

  // FocusNodes para capitalización automática
  final _patientNameFocus = FocusNode();
  final _doctorNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Setup auto-capitalization listeners
    _patientNameFocus.addListener(() {
      if (!_patientNameFocus.hasFocus) {
        final capitalized = NameCapitalizationFormatter.capitalize(
          _patientNameController.text,
        );
        if (capitalized != _patientNameController.text) {
          _patientNameController.value = _patientNameController.value.copyWith(
            text: capitalized,
            selection: TextSelection.collapsed(offset: capitalized.length),
          );
        }
      }
    });

    _doctorNameFocus.addListener(() {
      if (!_doctorNameFocus.hasFocus) {
        final capitalized = NameCapitalizationFormatter.capitalize(
          _doctorNameController.text,
        );
        if (capitalized != _doctorNameController.text) {
          _doctorNameController.value = _doctorNameController.value.copyWith(
            text: capitalized,
            selection: TextSelection.collapsed(offset: capitalized.length),
          );
        }
      }
    });

    if (widget.dentalBase != null) {
      _oaController.text = widget.dentalBase!.oa.toString();
      _doctorNameController.text = widget.dentalBase!.doctorName;
      _patientNameController.text = widget.dentalBase!.patientName;
      _patientRutController.text = widget.dentalBase!.patientRUT;
      _actionController.text = widget.dentalBase!.action;
      _observationsController.text = widget.dentalBase!.observations;
      _priceController.text = PriceInputFormatter.formatPrice(
        widget.dentalBase!.price,
      );
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
    _patientNameFocus.dispose();
    _doctorNameFocus.dispose();
    super.dispose();
  }

  Future<void> _saveDentalBase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dentalBase = DentalBase(
        oa: int.parse(_oaController.text),
        doctorName: capitalizeWords(_doctorNameController.text.trim()),
        patientName: capitalizeWords(_patientNameController.text.trim()),
        patientRUT: _patientRutController.text,
        action: _actionController.text,
        observations: _observationsController.text,
        entryDate: _entryDate,
        exitDate: _exitDate,
        price: PriceInputFormatter.getRawValue(_priceController.text) ?? 0,
        estado: _selectedState,
      );

      final sheet = await DatabaseHelper.instance.getOrCreateSheetForDate(
        _exitDate,
      );

      if (widget.dentalBase == null) {
        // Nueva base
        await DatabaseHelper.instance.insertDentalBase(dentalBase);
        await DatabaseHelper.instance.linkDentalBaseToSheet(
          dentalBase.oa,
          sheet.id,
        );
      } else {
        // Actualizar base existente
        await DatabaseHelper.instance.updateDentalBase(dentalBase);
      }

      if (mounted) {
        Navigator.pop(context, true); // true = guardado exitoso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.dentalBase != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4DB6AC),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    isEditing
                        ? 'Editar Base #${widget.dentalBase!.oa}'
                        : 'Nueva Base Dental',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Fila 1: OA (completo)
                      TextFormField(
                        controller: _oaController,
                        decoration: const InputDecoration(
                          labelText: 'OA *',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !isEditing,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Fila 2: Paciente y RUT
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _patientNameController,
                              focusNode: _patientNameFocus,
                              decoration: const InputDecoration(
                                labelText: 'Paciente *',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _patientRutController,
                              decoration: const InputDecoration(
                                labelText: 'RUT Paciente *',
                                hintText: '12.345.678-9',
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder(),
                              ),
                              inputFormatters: [RutInputFormatter()],
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Fila 3: Doctor y Estado
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _doctorNameController,
                              focusNode: _doctorNameFocus,
                              decoration: const InputDecoration(
                                labelText: 'Doctor *',
                                prefixIcon: Icon(Icons.medical_services),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<BaseState>(
                              value: _selectedState,
                              decoration: const InputDecoration(
                                labelText: 'Estado *',
                                prefixIcon: Icon(Icons.build_circle),
                                border: OutlineInputBorder(),
                              ),
                              items: BaseState.allStates.map((estado) {
                                return DropdownMenuItem(
                                  value: estado,
                                  child: Text(estado.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedState = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Fila 4: Precio (completo)
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Precio *',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [PriceInputFormatter()],
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Fila 5: Acción (completo)
                      TextFormField(
                        controller: _actionController,
                        decoration: const InputDecoration(
                          labelText: 'Acción *',
                          prefixIcon: Icon(Icons.construction),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Fila 6: Observaciones (completo)
                      TextFormField(
                        controller: _observationsController,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones *',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Fila 7: Fechas
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _entryDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null)
                                  setState(() => _entryDate = date);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha Entrada',
                                  prefixIcon: Icon(Icons.login),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(_entryDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _exitDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null)
                                  setState(() => _exitDate = date);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha Salida',
                                  prefixIcon: Icon(Icons.logout),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(_exitDate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer con botones
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveDentalBase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DB6AC),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      _isSaving ? 'Guardando...' : 'Guardar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
