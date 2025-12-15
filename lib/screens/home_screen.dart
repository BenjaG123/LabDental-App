import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dental_base.dart';
import '../models/base_state.dart';
import '../models/sheet.dart';
import '../database/database_helper.dart';
import 'dental_base_form.dart';
import 'dental_base_detail.dart';
import 'sheets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Sheet> _todasLasHojas = [];
  Sheet? _hojaActual;
  List<DentalBase> _basesDeHojaActual = [];
  List<DentalBase> _basesFiltradas = [];
  int _totalPrecio = 0;
  bool _isLoading = true;

  // Filtros y búsqueda
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filtroDoctor;
  int? _filtroEstadoId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    final hojas = await DatabaseHelper.instance.getAllSheets();

    Sheet? hojaSeleccionada;
    if (hojas.isNotEmpty) {
      hojaSeleccionada = hojas.first;
    } else {
      final ahora = DateTime.now();
      final nuevaHoja = await DatabaseHelper.instance.getOrCreateSheetForDate(
        ahora,
      );
      hojas.add(nuevaHoja);
      hojaSeleccionada = nuevaHoja;
    }

    List<DentalBase> bases = [];
    int total = 0;
    if (hojaSeleccionada != null) {
      bases = await DatabaseHelper.instance.getDentalBasesBySheet(
        hojaSeleccionada.id,
      );
      total = await DatabaseHelper.instance.getTotalPriceInSheet(
        hojaSeleccionada.id,
      );
    }

    setState(() {
      _todasLasHojas = hojas;
      _hojaActual = hojaSeleccionada;
      _basesDeHojaActual = bases;
      _totalPrecio = total;
      _isLoading = false;
    });

    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    setState(() {
      _basesFiltradas = _basesDeHojaActual.where((base) {
        // Filtro de búsqueda
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchOA = base.oa.toString().contains(query);
          final matchPaciente = base.patientName.toLowerCase().contains(query);
          final matchDoctor = base.doctorName.toLowerCase().contains(query);
          if (!matchOA && !matchPaciente && !matchDoctor) return false;
        }

        // Filtro por doctor
        if (_filtroDoctor != null && base.doctorName != _filtroDoctor) {
          return false;
        }

        // Filtro por estado
        if (_filtroEstadoId != null && base.estado.id != _filtroEstadoId) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _cambiarHoja(Sheet? nuevaHoja) async {
    if (nuevaHoja == null) return;

    setState(() => _isLoading = true);

    final bases = await DatabaseHelper.instance.getDentalBasesBySheet(
      nuevaHoja.id,
    );
    final total = await DatabaseHelper.instance.getTotalPriceInSheet(
      nuevaHoja.id,
    );

    setState(() {
      _hojaActual = nuevaHoja;
      _basesDeHojaActual = bases;
      _totalPrecio = total;
      _isLoading = false;
    });

    _aplicarFiltros();
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,##0', 'es_CL');
    return '\$ ${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER CON TÍTULO Y BOTÓN DE GESTIÓN
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bases Dentales',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4DB6AC),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.folder_open),
                          color: const Color(0xFF4DB6AC),
                          iconSize: 28,
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SheetsScreen(),
                              ),
                            );
                            _cargarDatos();
                          },
                        ),
                      ],
                    ),
                  ),

                  // CARD GRANDE: SELECTOR DE HOJA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () => _mostrarSelectorHojas(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4DB6AC), Color(0xFF26A69A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4DB6AC).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _hojaActual?.getSheetName() ?? 'Sin hoja',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // DOS CARDS PEQUEÑAS: BASES TOTALES E INGRESOS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF37474F),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bases Totales',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_basesDeHojaActual.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
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
                              color: const Color(0xFF37474F),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ingresos',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _formatCurrency(_totalPrecio),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // HEADER "BASES DEL MES" / BÚSQUEDA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _isSearching
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'Buscar...',
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Color(0xFF4DB6AC),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                    _aplicarFiltros();
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                color: const Color(0xFF4DB6AC),
                                onPressed: () {
                                  setState(() {
                                    _isSearching = false;
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                  _aplicarFiltros();
                                },
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Bases del Mes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.search),
                                    color: const Color(0xFF4DB6AC),
                                    iconSize: 24,
                                    onPressed: () {
                                      setState(() => _isSearching = true);
                                    },
                                    tooltip: 'Buscar',
                                  ),
                                  Stack(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.filter_list),
                                        color: const Color(0xFF4DB6AC),
                                        iconSize: 24,
                                        onPressed: _mostrarFiltros,
                                        tooltip: 'Filtros',
                                      ),
                                      if (_filtroDoctor != null ||
                                          _filtroEstadoId != null)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Text(
                                              '${(_filtroDoctor != null ? 1 : 0) + (_filtroEstadoId != null ? 1 : 0)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 12),

                  // LISTA DE BASES
                  Expanded(
                    child: _basesFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay bases en esta hoja',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargarDatos,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: _basesFiltradas.length,
                              itemBuilder: (context, index) {
                                final base = _basesFiltradas[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4DB6AC),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DentalBaseDetail(
                                                  dentalBase: base,
                                                ),
                                          ),
                                        );
                                        _cargarDatos();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // Información de la base
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${base.doctorName}  #${base.oa}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    base.patientName,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    base.estado.name,
                                                    style: TextStyle(
                                                      color: base.estado.id == 5
                                                          ? Colors.greenAccent
                                                          : Colors.white60,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Botones de acción (iconos)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                              ),
                                              iconSize: 20,
                                              onPressed: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        DentalBaseForm(
                                                          dentalBase: base,
                                                        ),
                                                  ),
                                                );
                                                _cargarDatos();
                                              },
                                              tooltip: 'Editar',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                              iconSize: 20,
                                              onPressed: () async {
                                                final confirmar = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    title: const Text(
                                                      'Confirmar eliminación',
                                                    ),
                                                    content: Text(
                                                      '¿Está seguro de eliminar la base OA ${base.oa}?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Cancelar',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        style:
                                                            TextButton.styleFrom(
                                                              foregroundColor:
                                                                  Colors.red,
                                                            ),
                                                        child: const Text(
                                                          'Eliminar',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirmar == true) {
                                                  await DatabaseHelper.instance
                                                      .deleteDentalBase(
                                                        base.oa,
                                                      );
                                                  _cargarDatos();
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: const Text(
                                                          'Base eliminada',
                                                        ),
                                                        backgroundColor:
                                                            Colors.orange,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              tooltip: 'Eliminar',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DentalBaseForm()),
          );
          _cargarDatos();
        },
        backgroundColor: const Color(0xFF4DB6AC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Modal para seleccionar hoja
  void _mostrarSelectorHojas() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seleccionar Hoja',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._todasLasHojas.map((hoja) {
                final isSelected = hoja.id == _hojaActual?.id;
                return ListTile(
                  title: Text(hoja.getSheetName()),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF4DB6AC))
                      : null,
                  selected: isSelected,
                  onTap: () {
                    Navigator.pop(context);
                    _cambiarHoja(hoja);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Modal de filtros (BottomSheet profesional)
  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String? tempDoctor = _filtroDoctor;
        int? tempEstadoId = _filtroEstadoId;

        // Obtener lista de doctores únicos
        final doctores =
            _basesDeHojaActual.map((b) => b.doctorName).toSet().toList()
              ..sort();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filtrar Bases',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          if (tempDoctor != null || tempEstadoId != null)
                            TextButton.icon(
                              onPressed: () {
                                setStateDialog(() {
                                  tempDoctor = null;
                                  tempEstadoId = null;
                                });
                              },
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('Limpiar todo'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Filtro por Doctor
                      const Text(
                        'Doctor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: tempDoctor,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: Color(0xFF4DB6AC),
                            ),
                          ),
                          hint: const Text('Seleccionar doctor'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todos los doctores'),
                            ),
                            ...doctores.map((doctor) {
                              return DropdownMenuItem(
                                value: doctor,
                                child: Text(doctor),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setStateDialog(() {
                              tempDoctor = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Filtro por Estado
                      const Text(
                        'Estado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonFormField<int>(
                          value: tempEstadoId,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.build_circle,
                              color: Color(0xFF4DB6AC),
                            ),
                          ),
                          hint: const Text('Seleccionar estado'),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Todos los estados'),
                            ),
                            ...BaseState.allStates.map((estado) {
                              return DropdownMenuItem(
                                value: estado.id,
                                child: Text(estado.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setStateDialog(() {
                              tempEstadoId = value;
                            });
                          },
                        ),
                      ),

                      // Chips de filtros activos
                      if (tempDoctor != null || tempEstadoId != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Filtros activos:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (tempDoctor != null)
                              Chip(
                                label: Text(tempDoctor!),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setStateDialog(() {
                                    tempDoctor = null;
                                  });
                                },
                                backgroundColor: const Color(
                                  0xFF4DB6AC,
                                ).withOpacity(0.1),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF4DB6AC),
                                ),
                              ),
                            if (tempEstadoId != null)
                              Chip(
                                label: Text(
                                  BaseState.getById(tempEstadoId!)!.name,
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setStateDialog(() {
                                    tempEstadoId = null;
                                  });
                                },
                                backgroundColor: const Color(
                                  0xFF4DB6AC,
                                ).withOpacity(0.1),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF4DB6AC),
                                ),
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Botón aplicar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filtroDoctor = tempDoctor;
                              _filtroEstadoId = tempEstadoId;
                            });
                            _aplicarFiltros();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4DB6AC),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Aplicar Filtros',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
