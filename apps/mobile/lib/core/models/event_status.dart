enum EventStatus {
  pollOpen('poll_open', '날짜 투표 중'),
  attendanceOpen('attendance_open', '일시 확정 · 참석 답변'),
  finalized('finalized', '모임 확정'),
  cancelled('cancelled', '취소됨');

  const EventStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static EventStatus fromApi(String v) =>
      EventStatus.values.firstWhere((e) => e.apiValue == v, orElse: () => pollOpen);
}
