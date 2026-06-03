import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'sensor_service.dart';

/// Service untuk generate dan share PDF hasil scan tray
class TrayPdfService {
  /// Generate dan share PDF untuk satu item tray
  static Future<void> generateAndShare({
    required String trayId,
    required String datetime,
    required String status,
    required Map<String, double?> gasValues,
  }) async {
    final pdf = pw.Document();

    // Warna berdasarkan status
    PdfColor statusColor;
    switch (status.toLowerCase()) {
      case 'bahaya':
        statusColor = const PdfColor.fromInt(0xFFB91C1C);
        break;
      case 'warning':
        statusColor = const PdfColor.fromInt(0xFF92400E);
        break;
      default:
        statusColor = const PdfColor.fromInt(0xFF047857);
    }

    // ─── PERSIAPAN DATA GRAFIK ──────────────────────────────────────────

    // 1. Data untuk Donut/Pie Chart (Distribusi Status)
    int normal = 0, warning = 0, danger = 0;
    for (final e in gasValues.entries) {
      final s = _getStatus(e.key, e.value);
      if (s == 'Bahaya') danger++;
      else if (s == 'Warning') warning++;
      else normal++;
    }

    // 2. Data untuk Bar Chart (Profil Konsentrasi - Pengganti Radar Chart)
    final keys = ['NH3', 'H2S', 'CH4', 'CO2', 'VOC', 'C2H5OH', 'CO', 'ACETONE', 'H2'];
    final maxVals = {'NH3': 25.0, 'H2S': 10.0, 'CH4': 100.0, 'CO2': 5000.0, 'VOC': 1.0, 'C2H5OH': 100.0, 'CO': 50.0, 'ACETONE': 100.0, 'H2': 100.0};
    final barData = <pw.PointChartValue>[];
    for (int i = 0; i < keys.length; i++) {
      final k = keys[i];
      final v = gasValues[k] ?? 0.0;
      final max = maxVals[k] ?? 100.0;
      barData.add(pw.PointChartValue(i.toDouble(), (v / max).clamp(0.0, 1.0)));
    }

    // 3. Data untuk Line Chart (Trend 24 Jam)
    final lineData = <pw.PointChartValue>[];
    try {
      final hourlyData = await SensorService.getHourlyToday();
      for (var avg in hourlyData) {
        // Ambil nilai tertinggi dari gas utama untuk grafik trend
        final y = avg.nh3 ?? avg.h2s ?? avg.ch4 ?? avg.co2 ?? 0.0;
        lineData.add(pw.PointChartValue(avg.time.hour.toDouble(), y));
      }
    } catch (_) {
      // Abaikan jika gagal memuat data trend
    }
    if (lineData.isEmpty) {
      lineData.add(const pw.PointChartValue(0, 0));
    }

    // Hitung titik kordinat Y otomatis untuk Line Chart agar pas dengan data tertinggi
    double maxLineY = 50.0;
    for (var point in lineData) {
      if (point.y > maxLineY) maxLineY = point.y;
    }
    double stepY = (maxLineY / 5).ceilToDouble();
    final yTicks = List<double>.generate(6, (i) => i * stepY);

    // ─── HALAMAN 1: TABEL DATA ──────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF00A39B),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('WITFood',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.SizedBox(height: 4),
                    pw.Text('Laporan Hasil Scan Sensor Gas',
                        style: const pw.TextStyle(fontSize: 13, color: PdfColors.white)),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Info Tray
              pw.Text('Informasi Tray', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB)),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                padding: const pw.EdgeInsets.all(16),
                child: pw.Column(
                  children: [
                    _infoRow('ID Tray', trayId),
                    _divider(),
                    _infoRow('Waktu Scan', datetime),
                    _divider(),
                    _infoRowColored('Status', status, statusColor),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Tabel Gas
              pw.Text('Data Sensor Gas', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFE5E7EB), width: 1),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF00A39B)),
                    children: [
                      _tableCell('Sensor', isHeader: true),
                      _tableCell('Nilai', isHeader: true),
                      _tableCell('Satuan', isHeader: true),
                      _tableCell('Status', isHeader: true),
                    ],
                  ),
                  ...gasValues.entries.map((e) {
                    final unit = e.key == 'VOC' ? 'mg/m³' : 'ppm';
                    final val = e.value;
                    final valStr = val != null ? val.toStringAsFixed(2) : '-';
                    final st = _getStatus(e.key, val);
                    return pw.TableRow(children: [
                      _tableCell(e.key),
                      _tableCell(valStr),
                      _tableCell(unit),
                      _tableCellColored(st, _statusPdfColor(st)),
                    ]);
                  }),
                ],
              ),

              pw.SizedBox(height: 24),

              // Threshold Referensi
              pw.Text('Referensi Batas Aman', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFE5E7EB), width: 1),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF374151)),
                    children: [
                      _tableCell('Sensor', isHeader: true),
                      _tableCell('Batas Warning', isHeader: true),
                      _tableCell('Batas Bahaya', isHeader: true),
                    ],
                  ),
                  _thresholdRow('NH3', '≥ 10 ppm', '≥ 25 ppm'),
                  _thresholdRow('H2S', '≥ 5 ppm', '≥ 10 ppm'),
                  _thresholdRow('CH4', '≥ 50 ppm', '≥ 100 ppm'),
                  _thresholdRow('CO2', '≥ 1000 ppm', '≥ 5000 ppm'),
                  _thresholdRow('VOC', '≥ 0.5 mg/m³', '≥ 1.0 mg/m³'),
                  _thresholdRow('C2H5OH', '≥ 20 ppm', '≥ 50 ppm'),
                  _thresholdRow('CO', '≥ 9 ppm', '≥ 35 ppm'),
                  _thresholdRow('ACETONE', '≥ 20 ppm', '≥ 50 ppm'),
                  _thresholdRow('H2', '≥ 20 ppm', '≥ 50 ppm'),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 6),
              pw.Text('Dokumen ini digenerate otomatis oleh WITFood.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              pw.Text('Dicetak pada: ${_nowFormatted()}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    // ─── HALAMAN 2: GRAFIK ANALISIS ─────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Analisis Visual Data Gas',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 24),

              // 1. Chart Distribusi (Pie Chart)
              pw.Text('Distribusi Status Gas', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Container(
                height: 180,
                child: pw.Chart(
                  grid: pw.PieGrid(),
                  datasets: [
                    if (normal > 0) pw.PieDataSet(value: normal.toDouble(), color: const PdfColor.fromInt(0xFF047857), legend: 'Normal'),
                    if (warning > 0) pw.PieDataSet(value: warning.toDouble(), color: const PdfColor.fromInt(0xFF92400E), legend: 'Warning'),
                    if (danger > 0) pw.PieDataSet(value: danger.toDouble(), color: const PdfColor.fromInt(0xFFB91C1C), legend: 'Bahaya'),
                  ],
                ),
              ),

              pw.SizedBox(height: 32),

              // 2. Bar Chart (Profil Konsentrasi - Pengganti Radar)
              pw.Text('Profil Konsentrasi Gas (Skala Normalisasi)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Container(
                height: 180,
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis.fromStrings(keys, ticks: true),
                    yAxis: pw.FixedAxis([0, 0.2, 0.4, 0.6, 0.8, 1.0]), // Menggunakan pw.FixedAxis
                  ),
                  datasets: [
                    pw.BarDataSet(
                      color: const PdfColor.fromInt(0xFF00A39B),
                      width: 15,
                      data: barData,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 32),

              // 3. Line Chart (Trend 24 Jam)
              pw.Text('Trend Sensor Historis (24 Jam Terakhir)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Container(
                height: 180,
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis([0, 4, 8, 12, 16, 20, 24]), // Interval waktu (0 - 24 jam)
                    yAxis: pw.FixedAxis(yTicks), // Sumbu Y akan menyesuaikan dengan data trend
                  ),
                  datasets: [
                    pw.LineDataSet(
                      color: const PdfColor.fromInt(0xFF1565C0),
                      lineWidth: 2,
                      data: lineData,
                    ),
                  ],
                ),
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 6),
              pw.Text('Hal 2 - Visualisasi digenerate oleh PDF Engine',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    // Simpan & share PDF
    final bytes = await pdf.save();

    final dir = await getExternalStorageDirectory();
    final filePath = '${dir!.path}/$trayId.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    await Printing.sharePdf(
      bytes: bytes,
      filename: '$trayId.pdf',
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────────────────────────

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _infoRowColored(String label, String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(value, style: const pw.TextStyle(color: PdfColors.white)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _divider() => pw.Divider(color: const PdfColor.fromInt(0xFFE5E7EB));

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
          fontSize: 11,
        ),
      ),
    );
  }

  static pw.Widget _tableCellColored(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, fontSize: 11),
      ),
    );
  }

  static pw.TableRow _thresholdRow(String sensor, String warning, String danger) {
    return pw.TableRow(children: [
      _tableCell(sensor),
      _tableCellColored(warning, const PdfColor.fromInt(0xFF92400E)),
      _tableCellColored(danger, const PdfColor.fromInt(0xFFB91C1C)),
    ]);
  }

  // ─── Helper Logic ────────────────────────────────────────────────────────────

  static String _getStatus(String sensor, double? value) {
    if (value == null) return '-';
    final thresholds = {
      'NH3': {'warning': 10.0, 'danger': 25.0},
      'H2S': {'warning': 5.0, 'danger': 10.0},
      'CH4': {'warning': 50.0, 'danger': 100.0},
      'CO2': {'warning': 1000.0, 'danger': 5000.0},
      'VOC': {'warning': 0.5, 'danger': 1.0},
      'C2H5OH': {'warning': 20.0, 'danger': 50.0},
      'CO': {'warning': 9.0, 'danger': 35.0},
      'ACETONE': {'warning': 20.0, 'danger': 50.0},
      'H2': {'warning': 20.0, 'danger': 50.0},
    };
    final t = thresholds[sensor.toUpperCase()];
    if (t == null) return 'Normal';
    if (value >= t['danger']!) return 'Bahaya';
    if (value >= t['warning']!) return 'Warning';
    return 'Normal';
  }

  static PdfColor _statusPdfColor(String status) {
    switch (status) {
      case 'Bahaya': return const PdfColor.fromInt(0xFFB91C1C);
      case 'Warning': return const PdfColor.fromInt(0xFF92400E);
      default: return const PdfColor.fromInt(0xFF047857);
    }
  }

  static String _nowFormatted() {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
    return '${now.day} ${months[now.month - 1]} ${now.year}, '
        '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')} WIB';
  }
}