# Claude Code 개발 환경 한 번에 세팅 (Windows)

이 폴더(저장소)만 있으면 누구나 자기 PC에 같은 개발 환경을 만들 수 있다.
계정 정보는 들어 있지 않다. git 이름·이메일과 각종 로그인은 실행하는 사람이 자기 것으로 한다.

📄 그림처럼 보기 좋은 안내서: [claude-code-setup-guide.pdf](./claude-code-setup-guide.pdf) (기능, 설치, 설정, 문제 해결)

## 설치되는 것

| 구분 | 항목 | 용도 |
|---|---|---|
| 프로그램 | Claude Code CLI | 터미널용 Claude, 플러그인·MCP 등록 |
| | Git | 버전 관리, Claude 의 Bash 도구(Git Bash) |
| | Node.js LTS | 웹 프로젝트, Ponytail 훅 실행 |
| | Python 3.12 + uv | 스크립트, 에이전트, 패키지 관리 |
| | GitHub CLI (`gh`) | 저장소 생성, push, PR |
| | rtk | 명령 출력 압축 (토큰 절약) |
| | VS Code + Claude Code 확장 | 에디터 |
| Claude 설정 | Ponytail 플러그인 | 필요한 최소 코드만 작성 (토큰·코드량 절약) |
| | watch 플러그인 | 영상 보고 답하기 (yt-dlp·ffmpeg 는 별도) |
| | rtk 훅 | Claude 가 실행한 Bash 명령 출력 자동 압축 |
| | Context7 MCP | 라이브러리 최신 공식 문서 조회 |

전부 모든 프로젝트에 공통 적용된다 (사용자 단위 설정).

## 1. 먼저 할 것

1. 이 저장소를 받는다: GitHub 페이지의 **Code → Download ZIP** 후 압축 풀기, 또는
   `git clone https://github.com/Siuuugil/claude-code-windows-setup.git`
2. **Claude 데스크톱 앱** 설치 후 본인 Claude 계정으로 로그인: https://claude.ai/download

## 2. 실행

`setup.cmd` 를 **더블클릭**한다. (PowerShell 실행 정책을 바꾸지 않고 실행된다)

- 관리자 확인 창이 뜨면 **예** (Git, Node 설치 때)
- **git 이름·이메일**을 물으면 본인 것을 입력한다 (커밋에 기록됨). 이미 설정돼 있으면 묻지 않는다.
- "명령 없음: 새 터미널에서 다시 실행" 경고가 나오면 **`setup.cmd` 를 한 번 더 더블클릭**한다. 이미 된 단계는 건너뛴다.
- winget 이 없다고 나오면 Microsoft Store 에서 "앱 설치 관리자" 를 업데이트한 뒤 다시 실행한다.

### 이미 깔려 있는 프로그램

명령이 이미 실행되는 프로그램은 설치 방법·버전과 상관없이 **건드리지 않는다** (직접 설치한 Python 3.11, nvm 의 Node, 시스템용 VS Code 등).
버전을 확인해서:

| 표시 | 뜻 | 선택 |
|---|---|---|
| `[필수 업데이트]` | 이 환경이 동작하지 않는 오래된 버전 (Node 18 미만, Python 3.10 미만) | winget 으로 설치된 것이면 `y` 로 바로 업데이트, 아니면 화면의 직접 업데이트 방법을 따른다 |
| `[선택 업데이트]` | 새 버전이 있지만 지금도 동작함 | `y` 면 전부 업데이트, Enter 면 건너뜀 |

질문 없이 전부 업데이트하려면 터미널에서 `setup.cmd -UpdateAll`.

기존 설정도 보존된다: git 이름·이메일은 비어 있을 때만 묻고, Claude 설정은 기존 파일에 합친다 (`~/.claude/settings.json.bak` 백업).

## 3. 마지막으로 할 것

1. GitHub 로그인 (새 터미널, 브라우저에서 코드 입력):
   ```powershell
   gh auth login --web --git-protocol https
   gh auth setup-git
   ```
2. Claude 앱 **완전 종료 후 재시작** (새 PATH, 플러그인, MCP 반영)
3. VS Code 열고 Claude 확장 첫 로그인
4. (선택) 예약 작업을 쓸 PC면 Claude 앱 **Settings → This computer → System → Keep computer awake** 켜기
5. (선택) `python` 이 Microsoft Store 를 열면 **설정 → 앱 → 고급 앱 설정 → 앱 실행 별칭** 에서 python 별칭 끄기, 또는 `py` 사용

## 다른 사람에게 줄 때

- 저장소 링크를 주면 된다: https://github.com/Siuuugil/claude-code-windows-setup (개인정보 없음)
- 상위 폴더의 `.personal\` 은 만든 사람의 개인 메모리 백업이라 주지 않는다.

## 본인 PC끼리 옮길 때 (선택)

Claude 가 쌓은 메모리(작업 습관, 프로젝트 규칙)까지 옮기려면:

1. 기존 PC에서 터미널로 `setup.cmd -SaveMemory` → 상위 폴더의 `.personal\memory` 에 백업
2. 상위 폴더째(OneDrive 등으로) 새 PC에 옮긴 뒤 `setup.cmd` 실행 → 메모리 복원 (새 PC에 이미 있는 메모리는 덮어쓰지 않음)
