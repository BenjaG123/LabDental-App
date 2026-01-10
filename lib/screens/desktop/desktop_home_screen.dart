import 'package:flutter/material.dart';
import '../../models/sheet.dart';
import '../../models/dental_base.dart';
import '../../database/database_helper.dart';
import '../../services/laboratory_service.dart';
import '../../services/export_excel_service.dart' as excel_service;
import '../../widgets/desktop/dental_bases_data_table.dart';
import '../../widgets/desktop/dental_base_form_dialog.dart';
import '../../widgets/desktop/analytics_card.dart';
import '../../widgets/desktop/production_chart.dart';
import '../../widgets/desktop/revenue_chart.dart';
import '../../widgets/desktop/top_doctors_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'desktop_profile_screen.dart';

/// Pantalla principal desktop con sidebar y split-screen
class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  final _laboratoryService = LaboratoryService();

  // Datos
  String _laboratoryName = 'Cargando...';
  String _userInitial = 'U';
  List<Sheet> _allSheets = [];
  Sheet? _selectedSheet;
  List<DentalBase> _bases = [];
  List<DentalBase> _filteredBases = [];
  bool _isLoading = true;

  // Búsqueda y filtros
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyPending = false; // Toggle pendientes/completadas

  // Navegación
  int _selectedNavIndex = 0; // 0 = Dashboard, 1 = Analytics, 2 = Profile

  // Analytics
  DateTime?
  _selectedAnalyticsMonth; // null = todas las hojas, fecha = mes específico

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _laboratoryService.getCurrentUserLaboratory(),
        _laboratoryService.getCurrentUserProfile(),
        DatabaseHelper.instance.getAllSheets(),
      ]);

      final lab = results[0] as Map<String, dynamic>?;
      final profile = results[1] as Map<String, dynamic>?;
      final sheets = results[2] as List<Sheet>;

      if (mounted) {
        setState(() {
          _laboratoryName = lab?['name'] ?? 'Mi Laboratorio';
          _userInitial = (profile?['full_name'] ?? 'U')[0].toUpperCase();
          _allSheets = sheets;
          _selectedSheet = sheets.isNotEmpty ? sheets.first : null;
          _isLoading = false;
        });

        if (_selectedSheet != null) {
          _loadSheetBases(_selectedSheet!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSheetBases(Sheet sheet) async {
    final bases = await DatabaseHelper.instance.getDentalBasesBySheet(
      sheet.id,
      onlyPending: _showOnlyPending,
    );

    if (mounted) {
      setState(() {
        _bases = bases;
        _applyFilters();
      });
    }
  }

  /// Aplicar filtros de búsqueda
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredBases = _bases;
    } else {
      final query = _searchQuery.toLowerCase();
      // Normalizar query para RUT (sin puntos ni guiones)
      final normalizedQuery = query.replaceAll(RegExp(r'[.-]'), '');

      _filteredBases = _bases.where((base) {
        // Normalizar RUT para comparación
        final normalizedRut = base.patientRUT
            .replaceAll(RegExp(r'[.-]'), '')
            .toLowerCase();

        return base.oa.toString().contains(query) ||
            base.doctorName.toLowerCase().contains(query) ||
            base.patientName.toLowerCase().contains(query) ||
            base.patientRUT.toLowerCase().contains(
              query,
            ) || // Búsqueda con formato
            normalizedRut.contains(normalizedQuery); // Búsqueda sin formato
      }).toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR NAVEGACIÓN
          _buildSidebar(),

          // CONTENIDO PRINCIPAL
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  /// Sidebar fijo a la izquierda
  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF37474F),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del sidebar
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Logo/Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF4DB6AC),
                  child: Text(
                    _userInitial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _laboratoryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 20),

          // Menú de navegación
          _buildNavItem(icon: Icons.dashboard, label: 'Inicio', index: 0),
          _buildNavItem(icon: Icons.analytics, label: 'Estadísticas', index: 1),
          _buildNavItem(icon: Icons.person, label: 'Perfil', index: 2),

          const Spacer(),

          // Footer
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Bases Lab Desktop\nv1.0.0',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedNavIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? const Color(0xFF4DB6AC) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _selectedNavIndex = index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Contenido principal (cambia según navegación)
  Widget _buildMainContent() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildAnalytics();
      case 2:
        return _buildProfile();
      default:
        return _buildDashboard();
    }
  }

  /// Dashboard principal con split-screen
  Widget _buildDashboard() {
    return Row(
      children: [
        // Lista de hojas (izquierda)
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de hojas
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: const Text(
                  'Hojas Mensuales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
                  ),
                ),
              ),

              // Lista de hojas
              Expanded(
                child: ListView.builder(
                  itemCount: _allSheets.length,
                  itemBuilder: (context, index) {
                    final sheet = _allSheets[index];
                    final isSelected = _selectedSheet?.id == sheet.id;

                    return Material(
                      color: isSelected
                          ? const Color(0xFF4DB6AC).withOpacity(0.1)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedSheet = sheet);
                          _loadSheetBases(sheet);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF4DB6AC)
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder,
                                color: isSelected
                                    ? const Color(0xFF4DB6AC)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  sheet.getSheetName(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF4DB6AC)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Área de contenido (derecha)
        Expanded(child: _buildContentArea()),
      ],
    );
  }

  /// Área de contenido principal con tabla
  Widget _buildContentArea() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Header con título y acciones
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedSheet?.getSheetName() ?? 'Sin hoja',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_bases.length} bases',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botones de acción
                ElevatedButton.icon(
                  onPressed: _handleExportExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  label: const Text(
                    'Exportar Excel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleNewBase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DB6AC),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Nueva Base',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filtros rápidos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Mostrar:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(
                    'Completadas (${_showOnlyPending ? 0 : _bases.length})',
                    style: const TextStyle(fontSize: 13),
                  ),
                  selected: !_showOnlyPending,
                  onSelected: (bool value) {
                    if (value) {
                      setState(() => _showOnlyPending = false);
                      if (_selectedSheet != null) {
                        _loadSheetBases(_selectedSheet!);
                      }
                    }
                  },
                  selectedColor: const Color(0xFF4DB6AC).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF4DB6AC),
                  backgroundColor: Colors.grey.shade200,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(
                    'Pendientes (${_showOnlyPending ? _bases.length : 0})',
                    style: const TextStyle(fontSize: 13),
                  ),
                  selected: _showOnlyPending,
                  onSelected: (bool value) {
                    if (value) {
                      setState(() => _showOnlyPending = true);
                      if (_selectedSheet != null) {
                        _loadSheetBases(_selectedSheet!);
                      }
                    }
                  },
                  selectedColor: Colors.orange.withOpacity(0.2),
                  checkmarkColor: Colors.orange,
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
          ),

          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por OA, doctor, paciente, RUT...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),

          // Tabla de datos
          Expanded(
            child: DentalBasesDataTable(
              bases: _filteredBases,
              onEdit: _handleEdit,
              onDelete: _handleDelete,
            ),
          ),
        ],
      ),
    );
  }

  /// Manejar edición de base
  Future<void> _handleEdit(DentalBase base) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DentalBaseFormDialog(dentalBase: base),
    );

    if (result == true && _selectedSheet != null) {
      _loadSheetBases(_selectedSheet!);
    }
  }

  /// Manejar nueva base
  Future<void> _handleNewBase() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const DentalBaseFormDialog(),
    );

    if (result == true && _selectedSheet != null) {
      _loadSheetBases(_selectedSheet!);
    }
  }

  /// Manejar eliminación de base
  Future<void> _handleDelete(DentalBase base) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar la base OA ${base.oa}?'),
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

    if (confirm == true) {
      await DatabaseHelper.instance.deleteDentalBase(base.oa);
      if (_selectedSheet != null) {
        _loadSheetBases(_selectedSheet!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Base eliminada correctamente')),
        );
      }
    }
  }

  /// Exportar Excel con selector de ruta
  Future<void> _handleExportExcel() async {
    if (_selectedSheet == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No hay hoja seleccionada')));
      return;
    }

    try {
      // Seleccionar carpeta de destino
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccionar carpeta para guardar Excel',
      );

      if (selectedDirectory == null) {
        // Usuario canceló
        return;
      }

      // Generar nombre de archivo
      final fileName = 'Hoja_${_selectedSheet!.getSheetName()}.xlsx';
      final filePath = '$selectedDirectory${Platform.pathSeparator}$fileName';

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(width: 12),
                Text('Generando Excel...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Generar Excel
      final allBases = await DatabaseHelper.instance.getDentalBasesBySheet(
        _selectedSheet!.id,
      );
      final total = await DatabaseHelper.instance.getTotalPriceInSheet(
        _selectedSheet!.id,
      );
      await excel_service.ExcelExportService.exportSheetToExcel(
        _selectedSheet!,
        allBases,
        total,
      );

      // Mostrar éxito
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel generado exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pantalla de Analytics
  Widget _buildAnalytics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAnalyticsSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Analytics',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Estadísticas y métricas de producción',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Selector de mes
              Row(
                children: [
                  Text(
                    'Filtrar por mes:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<DateTime?>(
                      value: _selectedAnalyticsMonth,
                      underline: const SizedBox(),
                      hint: const Text('Todas las hojas'),
                      items: [
                        const DropdownMenuItem<DateTime?>(
                          value: null,
                          child: Text('Todas las hojas'),
                        ),
                        ..._allSheets.map((sheet) {
                          final date = DateTime(sheet.year, sheet.month);
                          return DropdownMenuItem<DateTime?>(
                            value: date,
                            child: Text(sheet.getSheetName()),
                          );
                        }),
                      ],
                      onChanged: (DateTime? value) {
                        setState(() => _selectedAnalyticsMonth = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Cards
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  AnalyticsCard(
                    icon: Icons.production_quantity_limits,
                    title: _selectedAnalyticsMonth == null
                        ? 'Total Bases'
                        : 'Bases del Mes',
                    value: (summary['totalBases'] ?? 0).toString(),
                    subtitle: _selectedAnalyticsMonth == null
                        ? 'Todas las hojas'
                        : DateFormat(
                            'MMMM yyyy',
                          ).format(_selectedAnalyticsMonth!),
                    color: const Color(0xFF4DB6AC),
                  ),
                  AnalyticsCard(
                    icon: Icons.attach_money,
                    title: _selectedAnalyticsMonth == null
                        ? 'Ingresos Totales'
                        : 'Ingresos del Mes',
                    value:
                        '\$${NumberFormat('#,###').format(summary['totalRevenue'] ?? 0)}',
                    subtitle: _selectedAnalyticsMonth == null
                        ? 'Todas las hojas'
                        : DateFormat(
                            'MMMM yyyy',
                          ).format(_selectedAnalyticsMonth!),
                    color: Colors.green,
                  ),
                  AnalyticsCard(
                    icon: Icons.medical_services,
                    title: 'Doctores',
                    value: (summary['doctorsCount'] ?? 0).toString(),
                    subtitle: 'Registrados',
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Charts Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Production Chart
                  const Expanded(
                    flex: 2,
                    child: SizedBox(height: 350, child: ProductionChart()),
                  ),
                  const SizedBox(width: 16),
                  // Revenue Chart
                  const Expanded(
                    flex: 2,
                    child: SizedBox(height: 350, child: RevenueChart()),
                  ),
                  const SizedBox(width: 16),
                  // Top Doctors
                  const Expanded(
                    flex: 1,
                    child: SizedBox(height: 350, child: TopDoctorsWidget()),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Obtener resumen de analytics
  Future<Map<String, dynamic>> _getAnalyticsSummary() async {
    List<Sheet> sheetsToAnalyze;

    if (_selectedAnalyticsMonth != null) {
      // Filtrar por mes específico
      sheetsToAnalyze = _allSheets
          .where(
            (sheet) =>
                sheet.month == _selectedAnalyticsMonth!.month &&
                sheet.year == _selectedAnalyticsMonth!.year,
          )
          .toList();
    } else {
      // Todas las hojas
      sheetsToAnalyze = _allSheets;
    }

    int totalBases = 0;
    int totalRevenue = 0;
    final Set<String> uniqueDoctors = {};

    for (final sheet in sheetsToAnalyze) {
      final bases = await DatabaseHelper.instance.getDentalBasesBySheet(
        sheet.id,
        onlyPending: false,
      );
      final revenue = await DatabaseHelper.instance.getTotalPriceInSheet(
        sheet.id,
        onlyPending: false,
      );

      totalBases += bases.length;
      totalRevenue += revenue;
      for (final base in bases) {
        uniqueDoctors.add(base.doctorName);
      }
    }

    return {
      'totalBases': totalBases,
      'totalRevenue': totalRevenue,
      'doctorsCount': uniqueDoctors.length,
    };
  }

  /// Pantalla de Perfil
  Widget _buildProfile() {
    return const DesktopProfileScreen();
  }
}
