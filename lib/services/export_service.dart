import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/category.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // ========== EXPORT TO PDF ==========

  Future<String?> exportTransactionsToPDF(
    List<Transaction> transactions, {
    String? title,
  }) async {
    final pdf = pw.Document();

    // Calcular totales
    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Título
          pw.Header(
            level: 0,
            child: pw.Text(
              title ?? 'Reporte de Movimientos',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Fecha de generación
          pw.Text(
            'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),

          // Resumen
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Resumen',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Ingresos:'),
                    pw.Text(
                      '\$${totalIncome.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Egresos:'),
                    pw.Text(
                      '\$${totalExpense.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red,
                      ),
                    ),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Balance:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '\$${balance.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: balance >= 0 ? PdfColors.green : PdfColors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Tabla de transacciones
          pw.Text(
            'Transacciones (${transactions.length})',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Fecha', isHeader: true),
                  _buildTableCell('Tipo', isHeader: true),
                  _buildTableCell('Categoría', isHeader: true),
                  _buildTableCell('Nota', isHeader: true),
                  _buildTableCell('Monto', isHeader: true),
                ],
              ),
              // Rows
              ...transactions.map((transaction) {
                final category =
                    TransactionCategory.getById(transaction.categoryId);
                return pw.TableRow(
                  children: [
                    _buildTableCell(
                      DateFormat('dd/MM/yy').format(transaction.date),
                    ),
                    _buildTableCell(
                      transaction.isIncome ? 'Ingreso' : 'Egreso',
                    ),
                    _buildTableCell(category.name),
                    _buildTableCell(transaction.note ?? '-'),
                    _buildTableCell(
                      '\$${transaction.amount.toStringAsFixed(2)}',
                      textAlign: pw.TextAlign.right,
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/fyncee_movimientos_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      print('Error al exportar PDF: $e');
      return null;
    }
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: textAlign,
      ),
    );
  }

  // ========== EXPORT TO CSV ==========

  Future<String?> exportTransactionsToCSV(
    List<Transaction> transactions,
  ) async {
    final List<List<String>> rows = [
      // Header
      ['Fecha', 'Tipo', 'Categoría', 'Nota', 'Monto'],
      // Data
      ...transactions.map((transaction) {
        final category = TransactionCategory.getById(transaction.categoryId);
        return [
          DateFormat('dd/MM/yyyy').format(transaction.date),
          transaction.isIncome ? 'Ingreso' : 'Egreso',
          category.name,
          transaction.note ?? '',
          transaction.amount.toStringAsFixed(2),
        ];
      }),
    ];

    final csv = const ListToCsvConverter().convert(rows);

    try {
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/fyncee_movimientos_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csv);
      return file.path;
    } catch (e) {
      print('Error al exportar CSV: $e');
      return null;
    }
  }

  // ========== EXPORT GOALS TO PDF ==========

  Future<String?> exportGoalsToPDF(List<Goal> goals) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Título
          pw.Header(
            level: 0,
            child: pw.Text(
              'Reporte de Metas de Ahorro',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Fecha de generación
          pw.Text(
            'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),

          // Metas
          ...goals.map((goal) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 24),
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${goal.emoji} ${goal.name}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${goal.progressPercentage}%',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: goal.isCompleted
                              ? PdfColors.green
                              : PdfColors.blue,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Ahorro actual:'),
                      pw.Text(
                        '\$${goal.currentAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Meta:'),
                      pw.Text(
                        '\$${goal.targetAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Falta:'),
                      pw.Text(
                        '\$${goal.remainingAmount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  // Barra de progreso
                  pw.Container(
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                  ),
                  pw.SizedBox(height: -16), // Overlap
                  pw.Container(
                    width: (goal.progress > 1 ? 1 : goal.progress) * 500, // Ancho proporcional
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: goal.isCompleted
                          ? PdfColors.green
                          : PdfColors.blue,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/fyncee_metas_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      print('Error al exportar metas PDF: $e');
      return null;
    }
  }

  // ========== SHARE FILE ==========

  Future<void> shareFile(String filePath, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'Reporte de Fyncee',
      );
    } catch (e) {
      print('Error al compartir archivo: $e');
    }
  }
}
