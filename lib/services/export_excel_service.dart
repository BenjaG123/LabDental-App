import 'package:excel/excel.dart' as excel hide Sheet;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/dental_base.dart';
import '../models/sheet.dart';

class ExcelExportService {
  static Future<String> exportSheetToExcel(
    Sheet sheet,
    List<DentalBase> bases,
    int totalRevenue,
  ) async {
    var excelFile = excel.Excel.createExcel();

    // Eliminar hoja por defecto
    excelFile.delete('Sheet1');

    // Crear hoja con nombre del mes
    var sheetName = sheet.getSheetName();
    var excelSheet = excelFile[sheetName];

    // ==================== ESTILOS ====================

    // Estilo para encabezados
    final headerStyle = excel.CellStyle(
      bold: true,
      backgroundColorHex: excel.ExcelColor.teal,
      fontColorHex: excel.ExcelColor.white,
      horizontalAlign: excel.HorizontalAlign.Center,
      verticalAlign: excel.VerticalAlign.Center,
    );

    // Estilo para totales
    final totalStyle = excel.CellStyle(
      bold: true,
      backgroundColorHex: excel.ExcelColor.amber,
      horizontalAlign: excel.HorizontalAlign.Right,
    );

    // ==================== TABLA DE BASES ====================

    // Encabezados de la tabla principal
    final headers = [
      'OA',
      'Doctor',
      'Paciente',
      'RUT',
      'Fecha Entrada',
      'Fecha Salida',
      'Precio',
    ];

    for (var i = 0; i < headers.length; i++) {
      var cell = excelSheet.cell(
        excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = excel.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Datos de las bases
    for (var i = 0; i < bases.length; i++) {
      final base = bases[i];
      final row = i + 1;

      excelSheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = excel.IntCellValue(
        base.oa,
      );
      excelSheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = excel.TextCellValue(
        base.doctorName,
      );
      excelSheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = excel.TextCellValue(
        base.patientName,
      );
      excelSheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = excel.TextCellValue(
        base.patientRUT,
      );
      excelSheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = excel.TextCellValue(
        DateFormat('dd/MM/yyyy').format(base.entryDate),
      );
      excelSheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = excel.TextCellValue(
        DateFormat('dd/MM/yyyy').format(base.exitDate),
      );
      excelSheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = excel.IntCellValue(
        base.price,
      );
    }

    // ==================== RESUMEN FINANCIERO (COLUMNA L-N) ====================

    final summaryCol = 11; // Columna L (0-indexed)
    var summaryRow = 0;

    // Título del resumen
    var titleCell = excelSheet.cell(
      excel.CellIndex.indexByColumnRow(
        columnIndex: summaryCol,
        rowIndex: summaryRow,
      ),
    );
    titleCell.value = excel.TextCellValue('Resumen Financiero');
    titleCell.cellStyle = excel.CellStyle(
      bold: true,
      fontSize: 14,
      backgroundColorHex: excel.ExcelColor.teal,
      fontColorHex: excel.ExcelColor.white,
      horizontalAlign: excel.HorizontalAlign.Center,
    );

    //Merge título (L0:N0)
    excelSheet.merge(
      excel.CellIndex.indexByString('L1'),
      excel.CellIndex.indexByString('N1'),
    );

    summaryRow += 2;

    // Cantidad de bases
    excelSheet
        .cell(
          excel.CellIndex.indexByColumnRow(
            columnIndex: summaryCol,
            rowIndex: summaryRow,
          ),
        )
        .value = excel.TextCellValue(
      'Bases Totales:',
    );
    excelSheet
        .cell(
          excel.CellIndex.indexByColumnRow(
            columnIndex: summaryCol + 1,
            rowIndex: summaryRow,
          ),
        )
        .value = excel.IntCellValue(
      bases.length,
    );
    excelSheet
            .cell(
              excel.CellIndex.indexByColumnRow(
                columnIndex: summaryCol + 1,
                rowIndex: summaryRow,
              ),
            )
            .cellStyle =
        totalStyle;

    summaryRow++;

    // Línea vacía
    summaryRow++;

    // Subtotal
    excelSheet
        .cell(
          excel.CellIndex.indexByColumnRow(
            columnIndex: summaryCol,
            rowIndex: summaryRow,
          ),
        )
        .value = excel.TextCellValue(
      'Subtotal:',
    );
    excelSheet
        .cell(
          excel.CellIndex.indexByColumnRow(
            columnIndex: summaryCol + 1,
            rowIndex: summaryRow,
          ),
        )
        .value = excel.IntCellValue(
      totalRevenue,
    );
    excelSheet
            .cell(
              excel.CellIndex.indexByColumnRow(
                columnIndex: summaryCol + 1,
                rowIndex: summaryRow,
              ),
            )
            .cellStyle =
        totalStyle;

    summaryRow++;

    // IVA 19%
    final iva = (totalRevenue * 0.19).round();
    excelSheet
        .cell(
          excel.CellIndex.indexByColumnRow(
            columnIndex: summaryCol,
            rowIndex: summaryRow,
          ),
        )
        .value = excel.TextCellValue(
      'IVA 19%:',
    );
    excelSheet
        .cell(
          excel.CellIndex.indexByColumnRow(
            columnIndex: summaryCol + 1,
            rowIndex: summaryRow,
          ),
        )
        .value = excel.IntCellValue(
      iva,
    );
    excelSheet
            .cell(
              excel.CellIndex.indexByColumnRow(
                columnIndex: summaryCol + 1,
                rowIndex: summaryRow,
              ),
            )
            .cellStyle =
        totalStyle;

    summaryRow++;

    // Total
    final total = totalRevenue + iva;
    var totalLabelCell = excelSheet.cell(
      excel.CellIndex.indexByColumnRow(
        columnIndex: summaryCol,
        rowIndex: summaryRow,
      ),
    );
    totalLabelCell.value = excel.TextCellValue('Total:');
    totalLabelCell.cellStyle = excel.CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: excel.ExcelColor.teal,
      fontColorHex: excel.ExcelColor.white,
    );

    var totalValueCell = excelSheet.cell(
      excel.CellIndex.indexByColumnRow(
        columnIndex: summaryCol + 1,
        rowIndex: summaryRow,
      ),
    );
    totalValueCell.value = excel.IntCellValue(total);
    totalValueCell.cellStyle = excel.CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: excel.ExcelColor.teal,
      fontColorHex: excel.ExcelColor.white,
      horizontalAlign: excel.HorizontalAlign.Right,
    );

    // ==================== AJUSTAR ANCHOS DE COLUMNA ====================

    excelSheet.setColumnWidth(0, 8); // OA
    excelSheet.setColumnWidth(1, 20); // Doctor
    excelSheet.setColumnWidth(2, 25); // Paciente
    excelSheet.setColumnWidth(3, 15); // RUT
    excelSheet.setColumnWidth(4, 15); // Fecha Entrada
    excelSheet.setColumnWidth(5, 15); // Fecha Salida
    excelSheet.setColumnWidth(6, 12); // Precio
    excelSheet.setColumnWidth(8, 20); // Resumen label
    excelSheet.setColumnWidth(9, 15); // Resumen value

    // ==================== GUARDAR ARCHIVO ====================

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Bases_${sheet.getSheetName().replaceAll(' ', '_')}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final fileBytes = excelFile.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
    }

    return filePath;
  }
}
