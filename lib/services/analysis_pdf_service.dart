import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AnalysisPdfService {
  // ─── Warna konstan ─────────────────────────────────────────────────────────
  static const _blue      = PdfColor(0.08, 0.39, 0.75);   // #1565C0
  static const _blueLight = PdfColor(0.39, 0.71, 0.96);   // #64B5F6
  static const _white     = PdfColors.white;
  static const _white70   = PdfColor(1, 1, 1, 0.7);
  static const _grey      = PdfColors.grey;
  static const _grey600   = PdfColors.grey600;
  static const _border    = PdfColor(0.90, 0.91, 0.92);   // #E5E7EB

  static const _greenFg   = PdfColor(0.02, 0.47, 0.34);   // #047857
  static const _greenBg   = PdfColor(0.82, 0.98, 0.90);   // #D1FAE5
  static const _yellowFg  = PdfColor(0.57, 0.25, 0.05);   // #92400E
  static const _yellowBg  = PdfColor(0.99, 0.91, 0.54);   // #FDE68A
  static const _redFg     = PdfColor(0.73, 0.11, 0.11);   // #B91C1C
  static const _redBg     = PdfColor(0.99, 0.79, 0.79);   // #FECACA

  /// Generate dan share PDF laporan analitik
  static Future<void> generateAndShare({
    required Map<String, double?> sensorData,
    required Map<String, double> distribution,
    required int mode,
    required List<Map<String, dynamic>> chartImages,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    const months = [
      'Jan','Feb','Mar','Apr','Mei','Jun',
      'Jul','Agt','Sep','Okt','Nov','Des',
    ];
    final dateStr =
        '${now.day} ${months[now.month - 1]} ${now.year}, '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')} WIB';
    final modeStr = mode == 0
        ? 'Hari Ini'
        : mode == 1
        ? '7 Hari Terakhir'
        : '30 Hari Terakhir';

    // ─── Halaman 1: Header + Data Sensor + Distribusi ──────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header gradient
            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [_blue, _blueLight],
                ),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'WITFood — Laporan Analitik Sensor',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: _white,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Periode: $modeStr',
                    style: pw.TextStyle(fontSize: 13, color: _white),
                  ),
                  pw.Text(
                    'Digenerate: $dateStr',
                    style: pw.TextStyle(fontSize: 11, color: _white70),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Data Sensor Terbaru
            pw.Text(
              'Data Sensor Terbaru',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: _border, width: 1),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _blue),
                  children: [
                    _cell('Sensor',  isHeader: true),
                    _cell('Nilai',   isHeader: true),
                    _cell('Satuan',  isHeader: true),
                    _cell('Status',  isHeader: true),
                  ],
                ),
                ...sensorData.entries.map((e) {
                  final unit   = e.key == 'VOC' ? 'mg/m³' : 'ppm';
                  final val    = e.value;
                  final valStr = val != null ? val.toStringAsFixed(2) : '-';
                  final status = _getStatus(e.key, val);
                  return pw.TableRow(children: [
                    _cell(e.key),
                    _cell(valStr),
                    _cell(unit),
                    _cellColored(status, _statusColor(status)),
                  ]);
                }),
              ],
            ),

            pw.SizedBox(height: 24),

            // Distribusi Status
            pw.Text(
              'Distribusi Status Sensor',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Row(children: [
              _statBox(
                'Aman',
                '${(distribution['Normal']  ?? 0).toStringAsFixed(0)}%',
                _greenFg,
                _greenBg,
              ),
              pw.SizedBox(width: 12),
              _statBox(
                'Warning',
                '${(distribution['Warning'] ?? 0).toStringAsFixed(0)}%',
                _yellowFg,
                _yellowBg,
              ),
              pw.SizedBox(width: 12),
              _statBox(
                'Bahaya',
                '${(distribution['Danger']  ?? 0).toStringAsFixed(0)}%',
                _redFg,
                _redBg,
              ),
            ]),

            pw.Spacer(),
            pw.Divider(),
            pw.Text(
              'Halaman 1 dari ${chartImages.isEmpty ? 1 : 2}',
              style: pw.TextStyle(fontSize: 10, color: _grey),
            ),
          ],
        ),
      ),
    );

    // ─── Halaman 2+: Charts ────────────────────────────────────────────────
    if (chartImages.isNotEmpty) {
      for (int i = 0; i < chartImages.length; i += 2) {
        final charts = chartImages.sublist(
            i, (i + 2).clamp(0, chartImages.length));

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Grafik & Visualisasi',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Periode: $modeStr — $dateStr',
                  style: pw.TextStyle(fontSize: 11, color: _grey600),
                ),
                pw.SizedBox(height: 16),

                ...charts.map((chart) {
                  final bytes = chart['bytes'] as Uint8List?;
                  final title = chart['title'] as String? ?? '';
                  if (bytes == null) return pw.SizedBox();
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        width: double.infinity,
                        height: 240,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _border),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Image(
                          pw.MemoryImage(bytes),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  );
                }),

                pw.Spacer(),
                pw.Divider(),
                pw.Text(
                  'Halaman ${(i ~/ 2) + 2} • WITFood Analytics',
                  style: pw.TextStyle(fontSize: 10, color: _grey),
                ),
              ],
            ),
          ),
        );
      }
    }

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'analitik_sensor_$modeStr.pdf',
    );
  }

  // ─── Helper Widgets ────────────────────────────────────────────────────────
  static pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight:
          isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? _white : PdfColors.black,
          fontSize: 11,
        ),
      ),
    );
  }

  static pw.Widget _cellColored(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            color: color,
            fontWeight: pw.FontWeight.bold,
            fontSize: 11),
      ),
    );
  }

  static pw.Widget _statBox(
      String label, String value, PdfColor fg, PdfColor bg) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: fg),
            ),
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 12, color: fg),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Logic ──────────────────────────────────────────────────────────
  static String _getStatus(String sensor, double? value) {
    if (value == null) return '-';
    const thresholds = {
      'NH3':    {'warning': 10.0,    'danger': 25.0},
      'H2S':    {'warning': 5.0,     'danger': 10.0},
      'CH4':    {'warning': 50.0,    'danger': 100.0},
      'CO2':    {'warning': 1000.0,  'danger': 5000.0},
      'VOC':    {'warning': 0.5,     'danger': 1.0},
      'C2H5OH': {'warning': 20.0,    'danger': 50.0},
      'CO':     {'warning': 9.0,     'danger': 35.0},
      'ACETONE':     {'warning': 20.0,    'danger': 50.0},
      'H2':     {'warning': 20.0,    'danger': 50.0},
    };
    final t = thresholds[sensor];
    if (t == null) return 'Normal';
    if (value >= t['danger']!)  return 'Bahaya';
    if (value >= t['warning']!) return 'Warning';
    return 'Normal';
  }

  static PdfColor _statusColor(String status) {
    if (status == 'Bahaya')  return _redFg;
    if (status == 'Warning') return _yellowFg;
    return _greenFg;
  }
}