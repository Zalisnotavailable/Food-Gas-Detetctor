import 'package:supabase_flutter/supabase_flutter.dart';

/// Model untuk satu baris data sensor
class SensorReading {
  final DateTime timestamp;
  final String deviceId;
  final double? nh3;
  final double? h2s;
  final double? ch4;
  final double? co2;
  final double? voc;
  final double? c2h5oh;
  final double? co;
  final double? acetone;
  final double? h2;

  SensorReading({
    required this.timestamp,
    required this.deviceId,
    this.nh3,
    this.h2s,
    this.ch4,
    this.co2,
    this.voc,
    this.c2h5oh,
    this.co,
    this.acetone,
    this.h2,
  });

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      timestamp: DateTime.parse(map['timestamp']),
      deviceId:  map['device_id'] ?? 'sensor_01',
      nh3:       (map['nh3'] as num?)?.toDouble(),
      h2s:       (map['h2s'] as num?)?.toDouble(),
      ch4:       (map['ch4'] as num?)?.toDouble(),
      co2:       (map['co2'] as num?)?.toDouble(),
      voc:       (map['voc'] as num?)?.toDouble(),
      c2h5oh:    (map['c2h5oh'] as num?)?.toDouble(),
      co:        (map['co'] as num?)?.toDouble(),
      acetone:   (map['acetone'] as num?)?.toDouble(),
      h2:        (map['h2'] as num?)?.toDouble(),
    );
  }
}

/// Model untuk data rata-rata (per jam atau per hari)
class SensorAvg {
  final DateTime time;
  final double? nh3, h2s, ch4, co2, voc, c2h5oh, co, acetone, h2;

  SensorAvg({
    required this.time,
    this.nh3, this.h2s, this.ch4, this.co2,
    this.voc, this.c2h5oh, this.co, this.acetone, this.h2,
  });

  factory SensorAvg.fromMap(Map<String, dynamic> map, {bool isHourly = true}) {
    return SensorAvg(
      time:    DateTime.parse(map[isHourly ? 'hour' : 'day']),
      nh3:     (map['nh3'] as num?)?.toDouble(),
      h2s:     (map['h2s'] as num?)?.toDouble(),
      ch4:     (map['ch4'] as num?)?.toDouble(),
      co2:     (map['co2'] as num?)?.toDouble(),
      voc:     (map['voc'] as num?)?.toDouble(),
      c2h5oh:  (map['c2h5oh'] as num?)?.toDouble(),
      co:      (map['co'] as num?)?.toDouble(),
      acetone: (map['acetone'] as num?)?.toDouble(),
      h2:      (map['h2'] as num?)?.toDouble(),
    );
  }
}

class SensorService {
  static final _db = Supabase.instance.client;

  // ─── Data terbaru (1 baris) ────────────────────────────────────────────────
  static Future<SensorReading?> getLatest({String deviceId = 'sensor_01'}) async {
    final res = await _db
        .from('sensor_readings')
        .select()
        .eq('device_id', deviceId)
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();

    return res == null ? null : SensorReading.fromMap(res);
  }

  // ─── Rata-rata per jam (chart Hari Ini) ────────────────────────────────────
  static Future<List<SensorAvg>> getHourlyToday({String deviceId = 'sensor_01'}) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);

    final res = await _db
        .from('sensor_hourly_avg')
        .select()
        .eq('device_id', deviceId)
        .gte('hour', start.toIso8601String())
        .order('hour', ascending: true);

    return (res as List).map((e) => SensorAvg.fromMap(e, isHourly: true)).toList();
  }

  // ─── Rata-rata per hari (chart Minggu) ─────────────────────────────────────
  static Future<List<SensorAvg>> getDailyThisWeek({String deviceId = 'sensor_01'}) async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    final res = await _db
        .from('sensor_daily_avg')
        .select()
        .eq('device_id', deviceId)
        .gte('day', weekAgo.toIso8601String())
        .order('day', ascending: true);

    return (res as List).map((e) => SensorAvg.fromMap(e, isHourly: false)).toList();
  }

  // ─── Rata-rata per hari (chart Bulan) ──────────────────────────────────────
  static Future<List<SensorAvg>> getDailyThisMonth({String deviceId = 'sensor_01'}) async {
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));

    final res = await _db
        .from('sensor_daily_avg')
        .select()
        .eq('device_id', deviceId)
        .gte('day', monthAgo.toIso8601String())
        .order('day', ascending: true);

    return (res as List).map((e) => SensorAvg.fromMap(e, isHourly: false)).toList();
  }

  // ─── Realtime stream (data langsung dari sensor) ───────────────────────────
  /// Panggil ini untuk live update di UI
  static Stream<SensorReading> realtimeStream({String deviceId = 'sensor_01'}) {
    return _db
        .from('sensor_readings')
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .order('timestamp', ascending: false)
        .limit(1)
        .map((data) => SensorReading.fromMap(data.first));
  }

  // ─── Hitung status sensor (Normal / Warning / Danger) ─────────────────────
  static String getStatus(String sensor, double? value) {
    if (value == null) return 'Unknown';

    // Threshold berdasarkan standar keamanan pangan
    final thresholds = {
      'nh3':    {'warning': 10.0,  'danger': 25.0},
      'h2s':    {'warning': 5.0,   'danger': 10.0},
      'ch4':    {'warning': 50.0,  'danger': 100.0},
      'co2':    {'warning': 1000.0,'danger': 5000.0},
      'voc':    {'warning': 0.5,   'danger': 1.0},
      'c2h5oh': {'warning': 20.0,  'danger': 50.0},
      'co':     {'warning': 9.0,   'danger': 35.0},
      'h2':     {'warning': 20.0,  'danger': 50.0},
    };

    final t = thresholds[sensor.toLowerCase()];
    if (t == null) return 'Normal';

    if (value >= t['danger']!) return 'Danger';
    if (value >= t['warning']!) return 'Warning';
    return 'Normal';
  }
}