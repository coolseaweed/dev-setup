# Git Worktree Management Scripts

Git worktree를 효율적으로 관리하기 위한 Bash 스크립트 모음입니다.

## 개요

Git worktree는 하나의 저장소에서 여러 브랜치를 동시에 체크아웃할 수 있게 해주는 강력한 기능입니다. 이 스크립트들은 worktree 생성, 관리, 전환을 더욱 쉽게 만들어줍니다.

## 설치

### 1. PATH에 추가하기

```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
export PATH="$PATH:~/dev-setup/git/worktree"

# 짧은 별칭 추가 (선택사항)
alias gwa='gw-add.sh'
alias gwl='gw-list.sh'
alias gwr='gw-remove.sh'
alias gws='gw-switch.sh'
alias gwc='gw-clean.sh'
```

### 2. 실행 권한 부여

```bash
chmod +x ~/dev-setup/git/worktree/*.sh
chmod +x ~/dev-setup/git/utils/*.sh
```

## 스크립트 설명

### gw-add.sh - Worktree 생성

새로운 worktree를 생성합니다.

```bash
# 기존 브랜치에 대한 worktree 생성
gw-add.sh feature/existing-branch

# 새 브랜치와 함께 worktree 생성
gw-add.sh -b feature/new-feature

# develop 브랜치에서 새 브랜치 생성
gw-add.sh -b feature/new -f develop

# 절대 경로에 worktree 생성
gw-add.sh -p /home/user/projects/my-feature feature/branch

# 상대 경로에 worktree 생성  
gw-add.sh -p ../other-location/feature feature/branch

# 특정 베이스 디렉토리에 worktree 생성
gw-add.sh -P ~/work-projects feature/branch

# 새 브랜치 생성 (현재 브랜치가 자동으로 머지 타겟이 됨)
gw-add.sh -b feature/new

# 머지 타겟을 main으로 명시적 지정
gw-add.sh -b feature/new -t main

# develop에서 생성하고 main을 머지 타겟으로 설정
gw-add.sh -b feature/new -f develop -t main

# 생성 후 자동으로 이동
gw-add.sh -bc feature/new-feature
```

**옵션:**
- `-b, --new-branch`: 새 브랜치 생성
- `-B, --force-branch`: 브랜치 강제 생성 (기존 브랜치 덮어쓰기)
- `-c, --checkout`: 생성 후 자동으로 worktree로 이동
- `-f, --from BRANCH`: 특정 브랜치에서 새 브랜치 생성
- `-p, --path PATH`: 커스텀 경로 지정 (절대/상대 경로 모두 지원)
- `-P, --base-path DIR`: worktree 생성할 베이스 디렉토리 지정
- `-t, --target BRANCH`: 머지 타겟 브랜치 설정 (기본값: 새 브랜치 생성 시 현재 브랜치)

### gw-list.sh - Worktree 목록 조회

현재 저장소의 모든 worktree를 표시합니다.

```bash
# 기본 목록 표시
gw-list.sh

# 간단한 형식
gw-list.sh -s

# 상세 정보 (크기, 마지막 커밋 시간 포함)
gw-list.sh -v

# 머신 읽기 가능한 형식
gw-list.sh -p
```

**옵션:**
- `-s, --short`: 간단한 형식 (경로와 브랜치만)
- `-v, --verbose`: 상세 정보 표시
- `-p, --porcelain`: 머신 읽기 가능한 형식

### gw-remove.sh - Worktree 삭제

Worktree를 안전하게 삭제합니다.

```bash
# 브랜치 이름으로 삭제
gw-remove.sh feature/old-feature

# 경로로 삭제
gw-remove.sh /path/to/worktree

# 강제 삭제 (변경사항 무시)
gw-remove.sh -f feature/test

# Worktree와 브랜치 함께 삭제
gw-remove.sh -fb feature/obsolete

# 확인 없이 삭제
gw-remove.sh -y feature/temp
```

**옵션:**
- `-f, --force`: 변경사항이 있어도 강제 삭제
- `-b, --remove-branch`: 브랜치도 함께 삭제
- `-y, --yes`: 확인 프롬프트 건너뛰기

### gw-switch.sh - Worktree 전환

다른 worktree로 빠르게 전환합니다.

```bash
# 인터랙티브 선택 (fzf 필요)
gw-switch.sh

# 특정 브랜치의 worktree로 전환
gw-switch.sh feature/branch

# 마지막 사용한 worktree로 전환
gw-switch.sh -l

# 메인 worktree로 전환
gw-switch.sh -m
```

**옵션:**
- `-l, --last`: 마지막 사용한 worktree로 전환
- `-m, --main`: 메인 worktree로 전환

**참고:** 인터랙티브 모드는 [fzf](https://github.com/junegunn/fzf) 설치가 필요합니다.

### gw-clean.sh - Worktree 정리

오래되거나 사용하지 않는 worktree를 정리합니다.

```bash
# 인터랙티브 정리
gw-clean.sh

# 삭제된 브랜치의 worktree 제거
gw-clean.sh -o

# 30일 이상 된 worktree 제거
gw-clean.sh -d 30

# 고유 커밋이 없는 worktree 제거
gw-clean.sh -e

# 모든 정리 작업 수행 (dry-run)
gw-clean.sh -an

# 강제로 모든 정리 작업 수행
gw-clean.sh -af
```

**옵션:**
- `-o, --orphaned`: 삭제된 브랜치의 worktree 제거
- `-d, --days DAYS`: N일 이상 된 worktree 제거
- `-e, --empty`: 고유 커밋이 없는 worktree 제거
- `-a, --all`: 모든 정리 유형 실행
- `-n, --dry-run`: 실제로 삭제하지 않고 시뮬레이션
- `-f, --force`: 확인 없이 강제 실행

## 워크플로우 예시

### 기능 개발 워크플로우

```bash
# 0. develop 브랜치에서 시작
cd main-repo && git checkout develop

# 1. 새 기능 브랜치와 worktree 생성 (develop이 자동으로 머지 타겟이 됨)
gw-add.sh -bc feature/new-feature

# 2. 작업 진행...

# 3. PR 생성 (자동으로 develop을 타겟으로)
gw-pr.sh "Add new feature"

# 4. 메인으로 돌아가기
gw-switch.sh -m

# 5. 작업 완료 후 정리
gw-remove.sh feature/new-feature
```

### 다중 브랜치 작업

```bash
# 여러 기능을 동시에 작업
gw-add.sh -b feature/api
gw-add.sh -b feature/ui
gw-add.sh -b feature/docs

# 현재 상태 확인
gw-list.sh -v

# 브랜치 간 빠른 전환
gw-switch.sh  # fzf로 선택

# 정기적인 정리
gw-clean.sh -d 14  # 2주 이상 된 worktree 정리
```

### 버그 수정 워크플로우

```bash
# 프로덕션 브랜치에서 핫픽스 브랜치 생성
gw-add.sh -b hotfix/critical-bug -f production

# 수정 작업...

# 메인으로 돌아가서 머지
gw-switch.sh -m
git merge hotfix/critical-bug

# 핫픽스 worktree 정리
gw-remove.sh -fb hotfix/critical-bug
```

## 디렉토리 구조

### 기본 구조
Worktree는 기본적으로 메인 저장소의 부모 디렉토리에 생성됩니다:

```
~/projects/
├── my-repo/              # 메인 저장소
├── my-repo-feature-api/  # feature/api worktree
├── my-repo-feature-ui/   # feature/ui worktree
└── my-repo-hotfix-bug/   # hotfix/bug worktree
```

### 커스텀 경로 옵션

#### 절대 경로 지정 (-p)
```bash
gw-add.sh -p /home/user/work/feature-test feature/test
# 결과: /home/user/work/feature-test/
```

#### 베이스 디렉토리 지정 (-P)
```bash
gw-add.sh -P ~/work-projects feature/test
# 결과: ~/work-projects/my-repo-feature-test/
```

### 머지 타겟 브랜치 관리

머지 타겟을 설정하면 git config에 저장되어 나중에 참조할 수 있습니다:

```bash
# 머지 타겟 설정
gw-add.sh -b feature/new -t main

# 설정된 머지 타겟 확인
git config branch.feature/new.mergeTarget
# 출력: main

# 모든 브랜치의 머지 타겟 확인
git config --get-regexp "branch\..*\.mergeTarget"
```

## 팁과 모범 사례

1. **명명 규칙**: 브랜치 이름에 일관된 규칙 사용 (예: `feature/`, `bugfix/`, `hotfix/`)

2. **정기적인 정리**: 주기적으로 `gw-clean.sh`를 실행하여 오래된 worktree 정리

3. **커밋 전 확인**: worktree를 삭제하기 전에 모든 변경사항이 커밋되었는지 확인

4. **디스크 공간 관리**: `gw-list.sh -v`로 worktree가 사용하는 공간 모니터링

5. **빠른 전환**: fzf를 설치하여 `gw-switch.sh`의 인터랙티브 모드 활용

## 문제 해결

### "Not in a git repository" 오류
현재 디렉토리가 Git 저장소가 아닙니다. Git 저장소로 이동하세요.

### "Worktree already exists" 오류
해당 브랜치의 worktree가 이미 존재합니다. `gw-list.sh`로 확인하세요.

### fzf not found
인터랙티브 선택을 위해 fzf 설치:
```bash
# macOS
brew install fzf

# Ubuntu/Debian
sudo apt-get install fzf
```

### 삭제된 worktree 경로가 남아있을 때
```bash
git worktree prune
```

## 관련 문서

- [Git Worktree 공식 문서](https://git-scm.com/docs/git-worktree)
- [Git Worktree 튜토리얼](https://git-scm.com/docs/git-worktree/2.7.0)