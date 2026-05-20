import 'package:intl/intl.dart';

/// KST-oriented helpers for API ISO strings and display.
abstract final class DateTimeUtils {
  static DateTime nowLocal() => DateTime.now();

  static String toApiIso(DateTime dt) => dt.toUtc().toIso8601String();

  static DateTime parseApi(String iso) => DateTime.parse(iso).toLocal();

  static String formatDisplay(DateTime dt, {bool isAllDay = false}) {
    if (isAllDay) {
      return DateFormat('M월 d일 (E)', 'ko').format(dt);
    }
    return DateFormat('M월 d일 (E) HH:mm', 'ko').format(dt);
  }

  static String formatDisplayFromIso(String? iso, {bool isAllDay = false}) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return formatDisplay(parseApi(iso), isAllDay: isAllDay);
    } catch (_) {
      return iso;
    }
  }

  /// Default first poll candidate: +7 days at 18:00 local.
  static DateTime defaultFirstCandidate() {
    final n = nowLocal();
    return DateTime(n.year, n.month, n.day + 7, 18, 0);
  }

  /// Poll deadline: 72h before earliest candidate (P-E7 default hint).
  static DateTime defaultPollDeadline(DateTime earliestCandidate) {
    return earliestCandidate.subtract(const Duration(hours: 72));
  }

  /// Attendance deadline: 24h before confirmed start (P-E8).
  static DateTime defaultAttendanceDeadline(DateTime confirmedStart) {
    final d = confirmedStart.subtract(const Duration(hours: 24));
    return d.isAfter(nowLocal()) ? d : nowLocal().add(const Duration(hours: 1));
  }

  /// Client-side P-E7 for poll create.
  static String? validatePollCreate(DateTime pollDeadline, List<DateTime> options) {
    final now = nowLocal();
    if (!pollDeadline.isAfter(now)) return '투표 마감은 현재 시각 이후여야 해요.';
    if (options.length < 2) return '후보는 2개 이상 필요해요.';
    for (final o in options) {
      if (!o.isAfter(now)) return '후보 일시는 현재 시각 이후여야 해요.';
    }
    final earliest = options.reduce((a, b) => a.isBefore(b) ? a : b);
    if (!pollDeadline.isBefore(earliest)) {
      return '투표 마감은 가장 이른 후보보다 앞이어야 해요.';
    }
    return null;
  }

  /// Client-side P-E7 for fixed create.
  static String? validateFixedCreate(DateTime confirmed, DateTime attendanceDeadline) {
    final now = nowLocal();
    if (!confirmed.isAfter(now)) return '모임 일시는 현재 시각 이후여야 해요.';
    if (!attendanceDeadline.isAfter(now)) return '참석 마감은 현재 시각 이후여야 해요.';
    if (!attendanceDeadline.isBefore(confirmed)) {
      return '참석 마감은 모임 일시보다 앞이어야 해요.';
    }
    return null;
  }
}
