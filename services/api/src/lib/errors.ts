export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string,
  ) {
    super(message);
  }

  toJSON() {
    return { error: { code: this.code, message: this.message } };
  }
}

export const ERRORS = {
  VALIDATION_ERROR: (m = '입력 내용을 확인해 주세요.') =>
    new ApiError(400, 'VALIDATION_ERROR', m),
  INVALID_PHONE: () =>
    new ApiError(400, 'INVALID_PHONE', '올바른 휴대폰 번호를 입력해 주세요.'),
  OTP_EXPIRED: () =>
    new ApiError(400, 'OTP_EXPIRED', '인증번호가 만료되었어요. 다시 받아 주세요.'),
  OTP_INVALID: () =>
    new ApiError(400, 'OTP_INVALID', '인증번호가 맞지 않아요.'),
  OTP_RATE_LIMITED: () =>
    new ApiError(429, 'OTP_RATE_LIMITED', '오늘 인증 요청 횟수를 초과했어요. 내일 다시 시도해 주세요.'),
  UNAUTHORIZED: () => new ApiError(401, 'UNAUTHORIZED', '다시 로그인해 주세요.'),
  FORBIDDEN: () => new ApiError(403, 'FORBIDDEN', '권한이 없어요.'),
  NOT_FOUND: () => new ApiError(404, 'NOT_FOUND', '요청한 정보를 찾을 수 없어요.'),
  EVENT_NOT_FOUND: () => new ApiError(404, 'EVENT_NOT_FOUND', '모임을 찾을 수 없어요.'),
  USER_GROUP_LIMIT: () =>
    new ApiError(409, 'USER_GROUP_LIMIT', '가입할 수 있는 그룹 수(10개)에 도달했어요.'),
  ALREADY_MEMBER: () =>
    new ApiError(409, 'ALREADY_MEMBER', '이미 이 그룹에 참여 중이에요.'),
  GROUP_FULL: () => new ApiError(409, 'GROUP_FULL', '그룹 정원(30명)이 가득 찼어요.'),
  INVITE_EXPIRED: () => new ApiError(400, 'INVITE_EXPIRED', '초대 링크가 만료되었어요.'),
  POLL_CLOSED: () =>
    new ApiError(409, 'POLL_CLOSED', '투표가 마감되었어요. 화면을 새로고침해 주세요.'),
  ATTENDANCE_CLOSED: () => new ApiError(409, 'ATTENDANCE_CLOSED', '참석 응답이 마감되었어요.'),
  INCOMPLETE_POLL: () =>
    new ApiError(400, 'INCOMPLETE_POLL', '모든 날짜 후보에 응답해 주세요.'),
  DATETIME_NOT_CONFIRMED: () =>
    new ApiError(409, 'DATETIME_NOT_CONFIRMED', '아직 일시가 확정되지 않았어요.'),
  EVENT_CANCELLED: () => new ApiError(409, 'EVENT_CANCELLED', '취소된 모임이에요.'),
  VERSION_MISMATCH: () =>
    new ApiError(409, 'VERSION_MISMATCH', '다른 기기에서 변경되었어요. 새로고침해 주세요.'),
  NUDGE_RATE_LIMITED: () =>
    new ApiError(429, 'NUDGE_RATE_LIMITED', '오늘은 이미 독촉을 보냈어요.'),
  DATE_IN_PAST: (m = '과거 일시는 선택할 수 없어요.') =>
    new ApiError(400, 'DATE_IN_PAST', m),
  INVALID_DEADLINE: (m = '마감 시각을 확인해 주세요.') =>
    new ApiError(400, 'INVALID_DEADLINE', m),
  ADMIN_TRANSFER_REQUIRED: () =>
    new ApiError(403, 'ADMIN_TRANSFER_REQUIRED', '그룹 관리자는 다른 분에게 관리자를 넘긴 뒤 탈퇴할 수 있어요.'),
  ORGANIZER_UNAVAILABLE: () =>
    new ApiError(409, 'ORGANIZER_UNAVAILABLE', '모임 생성자 확인이 필요해요.'),
  SERVICE_UNAVAILABLE: (m = '서비스에 연결할 수 없어요.') =>
    new ApiError(503, 'SERVICE_UNAVAILABLE', m),
  OAUTH_PROVIDER_INVALID: () =>
    new ApiError(400, 'OAUTH_PROVIDER_INVALID', '지원하지 않는 로그인 방식이에요.'),
} as const;
