import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sheet.dart';
import '../database/database_helper.dart';
import '../services/export_excel_service.dart';

class SheetsScreen extends StatefulWidget {
  const SheetsScreen({super.key});

  @override
  State<SheetsScreen> createState() => _SheetsScreenState();
}

class _SheetsScreenState extends State<SheetsScreen> {
  List<Sheet> _sheets = [];
  Map<int, int> _baseCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSheets();
  }

  Future<void> _loadSheets() async {
    setState(() => _isLoading = true);

    final sheets = await DatabaseHelper.instance.getAllSheets();
    final counts = <int, int>{};

    for (var sheet in sheets) {
      final count = await DatabaseHelper.instance.countBasesInSheet(sheet.id);
      counts[sheet.id] = count;
    }

    setState(() {
      _sheets = sheets;
      _baseCounts = counts;
      _isLoading = false;
    });
  }

  Future<void> _deleteSheet(Sheet sheet) async {
    final baseCount = _baseCounts[sheet.id] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar eliminación'),
        content: Text(
          baseCount > 0
              ? '¿Está seguro de eliminar la hoja "${sheet.getSheetName()}"?\n\n'
                    'Esta hoja tiene $baseCount base${baseCount > 1 ? 's' : ''}. '
                    'Las bases NO se eliminarán, solo la hoja.'
              : '¿Está seguro de eliminar la hoja "${sheet.getSheetName()}"?',
        ),
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

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteSheet(sheet.id);
      _loadSheets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hoja "${sheet.getSheetName()}" eliminada'),
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
                  const Text(
                    'Gestión de Hojas',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4DB6AC),
                    ),
                  ),
                ],
              ),
            ),

            // CONTENIDO
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4DB6AC),
                      ),
                    )
                  : _sheets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay hojas creadas',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Las hojas se crean automáticamente\nal registrar bases dentales',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF4DB6AC),
                      onRefresh: _loadSheets,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _sheets.length,
                        itemBuilder: (context, index) {
                          final sheet = _sheets[index];
                          final baseCount = _baseCounts[sheet.id] ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Icono
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4DB6AC,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month,
                                      size: 28,
                                      color: Color(0xFF4DB6AC),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Información
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sheet.getSheetName(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF37474F),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$baseCount base${baseCount != 1 ? 's' : ''}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Botones
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Botón exportar Excel
                                      IconButton(
                                        icon: const Icon(Icons.file_download),
                                        color: const Color(0xFF4DB6AC),
                                        iconSize: 24,
                                        tooltip: 'Exportar a Excel',
                                        onPressed: () async {
                                          try {
                                            // Obtener bases y total
                                            final allBases =
                                                await DatabaseHelper.instance
                                                    .getDentalBasesBySheet(
                                                      sheet.id,
                                                    );

                                            // Filtrar solo bases terminadas (estadoId = 5)
                                            final completedBases = allBases
                                                .where(
                                                  (base) => base.estado.id == 5,
                                                )
                                                .toList();

                                            final total = await DatabaseHelper
                                                .instance
                                                .getTotalPriceInSheet(sheet.id);

                                            // Exportar
                                            final filePath =
                                                await ExcelExportService.exportSheetToExcel(
                                                  sheet,
                                                  completedBases,
                                                  total,
                                                );

                                            // Compartir archivo
                                            await Share.shareXFiles(
                                              [XFile(filePath)],
                                              subject:
                                                  'Reporte ${sheet.getSheetName()}',
                                              text:
                                                  'Reporte de bases dentales - ${sheet.getSheetName()}',
                                            );

                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                    'Compartiendo archivo Excel...',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Error al exportar: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
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
                                      ),
                                      // Botón eliminar
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.red.shade400,
                                        iconSize: 24,
                                        tooltip: 'Eliminar hoja',
                                        onPressed: () => _deleteSheet(sheet),
                                      ),
                                    ],
                                  ),
                                ],
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
    );
  }
}
