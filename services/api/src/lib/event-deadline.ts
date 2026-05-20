import { ERRORS } from './errors.js';

export type DateOptionInput = { startsAt: string | Date; isAllDay?: boolean };

function toDate(v: string | Date): Date {
  return v instanceof Date ? v : new Date(v);
}

export function assertFutureDate(d: Date, label = '일시'): void {
  if (d.getTime() <= Date.now()) throw ERRORS.DATE_IN_PAST(`${label}는 현재 시각 이후여야 해요.`);
}

/** P-E7 poll: now < pollDeadline < min(option starts) */
export function validatePollCreate(
  pollDeadlineAt: string | Date,
  options: DateOptionInput[],
): void {
  const now = Date.now();
  const deadline = toDate(pollDeadlineAt);
  if (deadline.getTime() <= now) throw ERRORS.INVALID_DEADLINE('투표 마감은 현재 시각 이후여야 해요.');

  const starts = options.map((o) => toDate(o.startsAt));
  for (const s of starts) assertFutureDate(s, '후보 일시');

  const earliest = Math.min(...starts.map((s) => s.getTime()));
  if (deadline.getTime() >= earliest) {
    throw ERRORS.INVALID_DEADLINE('투표 마감은 가장 이른 후보보다 앞이어야 해요.');
  }
}

/** P-E7 fixed: now < attendanceDeadline < confirmedStarts */
export function validateFixedCreate(
  confirmedStartsAt: string | Date,
  attendanceDeadlineAt: string | Date,
): void {
  const confirmed = toDate(confirmedStartsAt);
  const attendance = toDate(attendanceDeadlineAt);
  assertFutureDate(confirmed, '모임 일시');
  if (attendance.getTime() <= Date.now()) {
    throw ERRORS.INVALID_DEADLINE('참석 마감은 현재 시각 이후여야 해요.');
  }
  if (attendance.getTime() >= confirmed.getTime()) {
    throw ERRORS.INVALID_DEADLINE('참석 마감은 모임 일시보다 앞이어야 해요.');
  }
}

/** P-E8 default: confirmed - 24h, but must be > now */
export function defaultAttendanceDeadline(confirmedStartsAt: Date): Date {
  const preferred = new Date(confirmedStartsAt.getTime() - 24 * 60 * 60 * 1000);
  const minFuture = new Date(Date.now() + 60 * 60 * 1000);
  return preferred.getTime() > Date.now() ? preferred : minFuture;
}

export function validatePollDeadlineExtension(
  newDeadline: string | Date,
  optionStarts: Date[],
): void {
  const deadline = toDate(newDeadline);
  if (deadline.getTime() <= Date.now()) throw ERRORS.INVALID_DEADLINE('새 투표 마감은 현재 시각 이후여야 해요.');
  if (optionStarts.length) {
    const earliest = Math.min(...optionStarts.map((s) => s.getTime()));
    if (deadline.getTime() >= earliest) {
      throw ERRORS.INVALID_DEADLINE('투표 마감은 가장 이른 후보보다 앞이어야 해요.');
    }
  }
}
