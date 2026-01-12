# Usage

이 문서는 이 저장소의 설치 스크립트(`install.py`)와 설정 파일을 기준으로, **무엇이 설치/설정되는지**와 **기본값과 달라지는 단축어/키바인드**를 정리합니다.

---

## 1) Install

설치 진입점은 보통 아래 중 하나입니다.

- 원라이너: `etc/install` (git clone + `python install.py`)
- 수동: `git clone --recursive ... ~/.dotfiles && cd ~/.dotfiles && python3 install.py`
- 업데이트: `~/.local/bin/dotfiles update` (내부적으로 `install.py` 재실행)

`install.py`는 크게 두 가지를 수행합니다.

1. **심볼릭 링크 생성**: 이 repo의 설정 파일을 `$HOME` 아래 표준 위치로 링크합니다.
2. **후처리(post actions) 실행**: 플러그인/도구 설치 및 초기화를 수행합니다.

### 자동으로 생성되는 심볼릭 링크(주요)

- 셸: `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, `~/.zlogin`, `~/.zsh/` 전체
- Git: `~/.gitconfig`, `~/.gitignore`
- tmux: `~/.tmux.conf`, `~/.tmux/` 전체
- (Neo)Vim: `~/.vimrc`, `~/.vim/`, `~/.config/nvim/`
- CLI 도구: `~/.local/bin/dotfiles`, `~/.local/bin/fasd`, `~/.local/bin/fzf`(실제 바이너리는 `~/.fzf/bin/fzf`)
- 터미널 설정(SSH가 아닐 때만): `~/.config/kitty`, `~/.config/alacritty`, `~/.config/wezterm`

### 후처리에서 설치/다운로드/초기화되는 항목

아래 항목들은 `install.py` 실행 중 자동으로 수행됩니다(네트워크가 필요할 수 있음).

- `pyenv` 클론: `~/.pyenv` (`git clone https://github.com/pyenv/pyenv.git ~/.pyenv`)
- `fzf` 설치: `~/.fzf`를 클론/업데이트 후 `~/.fzf/install --all --no-update-rc`
  - `~/.local/bin/fzf`는 `~/.fzf/bin/fzf`로 링크됩니다.
- `video2gif` 설치: `~/.local/bin/video2gif`를 다운로드 후 실행 권한 부여
- Zsh 플러그인 갱신: `antidote update/reset` 실행(캐시 스크립트 생성 포함)
- tmux 플러그인 설치: TPM(`~/.tmux/plugins/tpm`)을 통해 플러그인 설치 수행
  - tmux 버전 체크(권장: `>= 2.3`), Linux에서 tmux 미설치 시 `dotfiles install tmux`로 로컬 설치를 시도할 수 있음
- `stat_dataset` 설치: `external/stat_dataset/bin/stat_dataset`를
  - 가능하면 `/usr/local/bin/stat_dataset`에 설치(sudo가 필요할 수 있음)
  - 실패 시 `~/.local/bin/stat_dataset`로 폴백
- `pman` 설치: 최신 릴리즈 바이너리를 내려받아 `/usr/local/bin/pman` 또는 `~/.local/bin/pman`에 설치
- `summon` 설치: 최신 릴리즈 바이너리를 내려받아 `summon` 설치
- `granted` 설치: 특정 버전의 릴리즈 바이너리를 내려받아 `granted`(+ `assume`가 포함되면 같이) 설치
  - 기본: `/usr/local/bin`, 실패 시 `~/.local/bin`로 폴백
- Neovim 체크: `etc/install-neovim.sh`
  - 권장 버전(`>= 0.11.2`) 미만이면 안내 메시지를 출력하고 실패로 기록됩니다.
  - macOS: `brew install neovim` 안내
  - Linux: 확인 프롬프트 후 `dotfiles install neovim`로 로컬 설치를 진행할 수 있음
- Neovim 플러그인 설치/업데이트: `nvim --headless +"Lazy! update" +qall` (옵션 `--skip-vimplug`로 스킵 가능)
- `~/.gitconfig.secret` 생성 및 `user.name`/`user.email` 인터랙티브 설정 유도

### (Linux 한정) 추가 자동 설치

Linux에서는 아래 커맨드가 없으면 `dotfiles install ...`로 로컬 설치를 시도합니다.

- `node`
- `rg` (ripgrep)
- `fd`

---

## 2) Shortcuts

아래는 “기본값과 다르게” 설정된 단축어/키바인드(또는 별칭)를 영역별로 정리한 것입니다.

### tmux

설정 파일: `tmux/tmux.conf` → `~/.tmux.conf`

- Prefix: 기본 `ctrl b` 대신 `cntrl a`
- 윈도우/레이아웃
  - `prefix + c`: 새 윈도우
  - `prefix + space`: 다음 윈도우
  - `prefix + Backspace`: 이전 윈도우
  - `prefix + =`: `main-vertical`, `prefix + Alt-=`: `main-horizontal`
- 패널 분할(현재 디렉터리 유지)
  - `prefix + v` 또는 `prefix + |`: 좌/우 분할
  - `prefix + s` 또는 `prefix + _`: 상/하 분할
- 패널 이동: `prefix + h/j/k/l` 혹은 방향키
- 패널 리사이즈: `prefix + <`/`>`/`+`/`-` 후 “resize-pane” 키테이블에서 `h/j/k/l` 또는 방향키로 반복 조절
- 복사/붙여넣기(기본은 macOS `pbcopy`/`pbpaste` 기준)
  - `prefix + Enter` 또는 `prefix + Escape`: copy-mode 진입
  - copy-mode(vi)에서 `v` 선택 시작, `y` 복사 후 종료
  - `prefix + ]`: paste-buffer
  - `prefix + p`: 시스템 클립보드(`pbpaste`) → tmux buffer로 로드 후 paste
- 탈출: `exit`

### git

설정 파일: `git/gitconfig` → `~/.gitconfig`, Zsh 별칭은 `zsh/zsh.d/alias.zsh`

- Git 별칭(일부)
  - `git history`: 그래프 로그(커스텀 포맷)
  - `git co`: checkout
  - `git unstage`: `reset HEAD --`
  - `git discard`: `checkout --`
  - `git amend` / `git amend-f`
  - `git sdiff` / `git show-side`: `delta -s` 기반 side-by-side 출력
- Zsh에서 자주 쓰는 git 단축어(일부)

  - `gs`: `git status`
  - `gd`: `git diff --no-prefix`
  - `gdns`: `git diff name-status`
  - `gu`: `git pull --autostash`
  - `gh`: `git history` 상단만 출력

### auth (AWS 등)

설정 파일: `zsh/zsh.d/alias.zsh`

- `a`: `assume ai --exec -- <cmd>` (granted의 `assume` 사용)
- `sa`: `assume ai --exec -- summon --provider summon-aws-secrets <cmd>`

참고:

- `install.py`가 `granted`(→ `assume`)와 `summon` 설치를 시도합니다.
- 실제로 동작하려면 로컬의 AWS 설정/프로파일 및 summon provider 설정이 필요할 수 있습니다.

### zsh (키바인딩)

설정 파일: `zsh/zsh.d/key-bindings.zsh`, `zsh/zsh.d/fzf-widgets.zsh`

- 히스토리 부분검색: 위/아래 방향키가 `history-substring-search-up/down`으로 동작
- 단어 단위 이동: `Alt+Left/Right` → `backward-word/forward-word`
- fzf 추가 위젯: `Ctrl+Space` → `fzf-file-widget` (`Ctrl-T` 대체/보강)
- fzf-git hashes: `Ctrl+g o` 또는 `Ctrl+g Ctrl+o` → `fzf-git-hashes-widget`

### 터미널 에뮬레이터(설치 시 링크되는 항목 위주)

- WezTerm: `config/wezterm/wezterm.lua`
  - `Cmd+Enter`로 fullscreen 토글(기본 `Alt+Enter` 동작은 비활성화)
- Alacritty: `config/alacritty/alacritty.toml`
  - macOS에서 `option_as_alt = "OnlyLeft"` (왼쪽 Option만 Alt처럼 사용)
- Ghostty / Karabiner 등은 repo에 설정이 있으나 `install.py`가 자동 링크하진 않습니다.
  - Ghostty 예시: `config/ghostty/config`에서 `Ctrl+Cmd+h/j/k/l`로 split 이동
  - Karabiner 예시: `config/karabiner/README.md` 참고(수동 복사 방식)

### (Neo)Vim

설정 파일: `vim/vimrc`, `nvim/init.lua`

- vim이 기본적으로 NeoVim으로 세팅되어 있습니다.
- `<Leader>`는 `,`(comma)
- 창 이동: `<C-h/j/k/l>` (tmux 내부에서는 tmux navigator 연동)
- `<C-Space>`: omni completion 트리거
