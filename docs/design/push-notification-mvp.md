# 푸시 알림 스펙 (MVP)

**버전:** 0.1  
**근거:** PRD §8.1 (P-N*), F5

## 채널

| 플랫폼 | 채널 |
|--------|------|
| Android | FCM — `moimday_default` |
| iOS | APNs — alert + sound |

## 페이로드 (클라이언트 수신)

```json
{
  "type": "poll_reminder",
  "eventId": "uuid",
  "groupId": "uuid",
  "title": "날짜 투표가 필요해요",
  "body": "생신 식사 — 5월 30일 후보",
  "deepLink": "moimday://events/{eventId}"
}
```

`type` 값: [data-model Notification.type](../api/data-model.md) §4 와 동일.

## 정책 연동

- 미응답·미투표만 (P-N2), 야간 이월(P-N3), 08:00 합산(P-N9)
- 응답 완료 시 스케줄 취소(P-N10)
- `autoReminderEnabled=false` → **자동** 푸시만 생략(P-N6)

## 권한

- 최초: S01/S02에서 OS 권한 요청
- 거부: P-N5 — 인앱·홈 유지, S12 안내
