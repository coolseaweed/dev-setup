
# Git Tools and Scripts

Git 관련 도구와 스크립트 모음입니다.

## Git Worktree Management

Git worktree를 효율적으로 관리하기 위한 스크립트들이 `worktree/` 디렉토리에 있습니다.

### 빠른 시작

```bash
# PATH에 추가
export PATH="$PATH:~/dev-setup/git/worktree"

# 별칭 설정 (선택사항)
alias gwa='gw-add.sh'      # worktree 추가
alias gwl='gw-list.sh'     # worktree 목록
alias gwr='gw-remove.sh'   # worktree 삭제
alias gws='gw-switch.sh'   # worktree 전환
alias gwc='gw-clean.sh'    # worktree 정리
```

자세한 사용법은 [worktree/README.md](./worktree/README.md)를 참조하세요.

## Git Configuration

### Credential automation

[credential](https://developer-carmel.tistory.com/10)

### Add account
```bash
git config user.name <username>
git config user.email <email>
```

### Cross Check
```bash
git config --list
git config user.name
```

## Directory Structure

```
git/
├── README.md           # 이 파일
├── worktree/          # Git worktree 관리 스크립트
│   ├── gw-add.sh      # worktree 생성
│   ├── gw-list.sh     # worktree 목록 조회
│   ├── gw-remove.sh   # worktree 삭제
│   ├── gw-switch.sh   # worktree 전환
│   ├── gw-clean.sh    # worktree 정리
│   └── README.md      # worktree 도구 문서
└── utils/
    └── git-common.sh  # 공통 함수 라이브러리
```