# 디자인 토큰 — Stitch 선택안 (Serene Kinship)

2C에서 **Stitch(2B)** 를 선택함에 따라, 제품 구현 시 참조할 최소 토큰이다.  
SSOT: Stitch 프로젝트 `5575514198874046733` · 디자인 시스템 **Serene Kinship**.

## 브랜드

| 토큰 | 값 | 용도 |
|------|-----|------|
| `color.primary` | `#2B8C7E` | CTA, 활성 탭, 강조 |
| `color.primary-container` | `#1D8275` | 채움 변형 |
| `color.secondary-wash` | `#E8F2F0` | 카드·배경 틴트 |
| `color.tertiary-accent` | `#F4A261` | 알림·리마인더 포인트 |
| `color.surface` | `#FBF9F8` | 라이트 배경 |
| `color.on-surface` | `#1B1C1C` | 본문 |

## 형태·간격

| 토큰 | 값 |
|------|-----|
| `radius.card` | 12px |
| `radius.button` | pill(9999px) 권장 |
| `spacing.unit` | 8px 그리드 |
| `spacing.margin-mobile` | 20px |
| `touch.min` | 48px |

## 타이포

| 토큰 | 값 |
|------|-----|
| `font.latin` | Plus Jakarta Sans |
| `font.korean` | Pretendard 또는 Noto Sans KR (앱에서 페어링) |
| `type.headline-lg-mobile` | 24px / 700 |
| `type.body-md` | 16px / 400 |

## 다크모드

- 배경: Charcoal-Teal 계열 `#1A2B28` (Stitch 가이드)
- Primary: 라이트 대비를 위해 약간 desaturate

## 컴포넌트 규칙 (Stitch → 앱)

- 아이콘만 버튼 금지 — 한국어 라벨 필수 (PRD·product-ui-core와 동일)
- 하단 탭: 홈 · 모임 · 일정 · 알림 · 설정
- 카드: 12px 라운드, 얕은 그림자

## 2A와의 차이 (참고)

2A [`mock-internal/styles/tokens.css`](../../mock-internal/styles/tokens.css)도 동일 primary를 쓰나, Stitch는 Plus Jakarta·Serene Kinship 톤이 더 따뜻한 서피스·pill CTA에 가깝다. **구현 기준은 본 문서(Stitch)** 이다.
