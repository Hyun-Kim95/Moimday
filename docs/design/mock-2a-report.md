# 2A 자체 목업 — 산출 보고

| 항목 | 내용 |
|------|------|
| 단계 | client-project-lifecycle **2A** |
| 경로 | [`mock-internal/`](../../mock-internal/) |
| PRD | v0.6 (승인 완료) |
| API 연동 | **없음** (정적 프로토타입) |

## 포함 화면

| ID | 파일 내 screen id | 비고 |
|----|-------------------|------|
| S01 | s01 | 온보딩 |
| S02 | s02 | OTP |
| S03 | s03 | 그룹·초대 |
| S04 | s04 | **홈** (기본 진입) |
| S05 | s05 | 모임 목록 + FAB |
| S06 | s06 | 모임 만들기 |
| S07 | s07-poll / s07-attend | 투표·참석 (툴바 전환) |
| S08 | dialog | 투표·참석 바텀시트 |
| S13 | s13 | 투표 집계 |
| S14 | s14 | 일시 확정 |
| S09~S12 | s09~s12 | 일정·알림·설정·도움말 |

## 상태 UI (Gate 1)

- 기본: S04, S07
- 다크모드: 툴바 **Dark** 토글
- 빈/로딩/오류: 목업 범위에서 **S04 빈 상태**는 후속 변형으로 추가 가능(현재는 데이터 있음 샘플)

## 실행 방법

```bash
cd mock-internal
npx --yes serve -p 5173
```

브라우저: http://localhost:5173

## 디자인 토큰

- `mock-internal/styles/tokens.css` — primary `#2b8c7e`, 라이트/다크
- Gate 2에서 Stitch/제품 코드로 이전 예정

## PRD 정합

- F2 홈 3섹션, F3 투표/참석 분기, F4 finalized 일정, 가족 미완료 명단 반영
- 상세: [screen-spec-mvp.md](./screen-spec-mvp.md), [ui-states-mvp.md](./ui-states-mvp.md)
