# 용어집 (Glossary)

| 용어 | 정의 | PRD/API |
|------|------|---------|
| **그룹 관리자** | `FamilyGroup.adminUserId`. 초대·멤버 제거·그룹 해체 | P-G2 |
| **모임 생성자** | `Event.organizerId`. 일시·최종 확정·취소·편집 | §8.0 |
| **조율자** | 문맥상 **모임 생성자**와 동일 (혼용 금지) | §8.0 |
| **후보 투표 모드** | `Event.mode = poll` | F3-a |
| **일시 확정 모드** | `Event.mode = fixed` | P-E9 |
| **투표 마감** | `pollDeadlineAt` | P-E7 |
| **참석 마감** | `attendanceDeadlineAt` | P-E8 |
| **모임 확정** | `status = finalized`, 캘린더 반영 | P-E6 |
| **대상 스냅샷** | 생성 시 `targetMemberIds` 고정 | P-E13 |
| **미응답** | 스냅샷 대상 중 해당 단계 미완료 | P-N2 |

## 응답 값

| UI (KO) | 투표 API | 참석 API |
|---------|----------|----------|
| 가능 | `yes` | — |
| 불가 | `no` | `decline` |
| 미정 | `maybe` | `maybe` |
| 참석 | — | `attend` |
