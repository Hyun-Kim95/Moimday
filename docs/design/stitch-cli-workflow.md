# Stitch 2B — CLI 워크플로

Moimday **2B**는 Cursor MCP가 아니라 **`stitch-design-cli`** 로 진행한다.

## 인증

- API 키: 사용자 로컬 `C:\Users\User\.cursor\mcp.json` → `mcpServers.stitch.env.STITCH_API_KEY`
- **레포·문서에 키를 복사하지 않는다.** 셸에서만 환경 변수로 주입한다.

PowerShell 예시:

```powershell
$cfg = Get-Content "$env:USERPROFILE\.cursor\mcp.json" -Raw | ConvertFrom-Json
$env:STITCH_API_KEY = $cfg.mcpServers.stitch.env.STITCH_API_KEY
```

## CLI 설치·점검

```bash
npx -y stitch-design-cli doctor
npx -y stitch-design-cli project list --json
```

`doctor`의 `api.tools.list` 경고는 알려진 스키마 이슈일 수 있으며, `api.projects.list`가 성공이면 생성·조회는 진행 가능하다.

## 표준 순서 (MCP SOP 대응)

| MCP (kit SOP) | CLI |
|---------------|-----|
| `list_projects` | `stitch project list --json` |
| `create_project` | `stitch project create --title "Moimday" --json` |
| `get_project` | `stitch project get <project-id> --json` |
| `generate_screen_from_text` | `stitch screen generate --project-id … --prompt "…" --device-type MOBILE --include-html --include-image --json` |
| `list_screens` / `get_screen` | `stitch screen list --project-id …` / `stitch screen get …` |

디자인 시스템 전용 CLI 명령은 없을 수 있다. 이 경우 **공통 스타일 블록**을 각 `screen generate` 프롬프트에 포함한다 ([stitch-2b-track.md](./stitch-2b-track.md)).

## 진행 기록

실행 결과(`projectId`, screen ID, Stitch URL)는 [stitch-2b-track.md](./stitch-2b-track.md)에만 기록한다.

## 관련

- Kit MCP SOP(참고): [stitch-sop.md](../../vendor/cursor-workspace-kit/docs/design/stitch-sop.md)
- 2B 프롬프트·체크리스트: [stitch-2b-track.md](./stitch-2b-track.md)
