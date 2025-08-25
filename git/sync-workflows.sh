#!/bin/bash

# GitHub Actions Workflow 동기화 스크립트
# 사용법: ./sync-workflows.sh [프로젝트 경로]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOWS_SOURCE="$SCRIPT_DIR/workflows"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 프로젝트 목록 (경로 추가 가능)
PROJECTS=(
    "/Users/tom/PRJ/factoreal/factoreal_landing"
    # 여기에 더 많은 프로젝트 추가
)

# 함수: workflow 동기화
sync_workflow() {
    local project_path="$1"
    
    if [ ! -d "$project_path" ]; then
        echo -e "${RED}❌ 프로젝트가 존재하지 않음: $project_path${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}📁 동기화 중: $project_path${NC}"
    
    # .github/workflows 디렉토리 생성
    mkdir -p "$project_path/.github/workflows"
    
    # 심볼릭 링크 제거 (있을 경우)
    if [ -L "$project_path/.github/workflows" ]; then
        rm "$project_path/.github/workflows"
        mkdir -p "$project_path/.github/workflows"
    fi
    
    # workflow 파일 복사
    cp -r "$WORKFLOWS_SOURCE"/* "$project_path/.github/workflows/" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 동기화 완료: $project_path${NC}"
        
        # Git 상태 확인
        cd "$project_path"
        if git diff --quiet .github/workflows/; then
            echo "  변경사항 없음"
        else
            echo -e "${YELLOW}  ⚠️  변경사항 있음 - commit 필요${NC}"
            git status --short .github/workflows/
        fi
    else
        echo -e "${RED}❌ 동기화 실패: $project_path${NC}"
    fi
    
    echo ""
}

# 메인 실행
main() {
    echo "================================"
    echo "GitHub Actions Workflow 동기화"
    echo "================================"
    echo ""
    
    # 인자로 특정 프로젝트 지정된 경우
    if [ $# -eq 1 ]; then
        sync_workflow "$1"
    else
        # 모든 프로젝트 동기화
        for project in "${PROJECTS[@]}"; do
            sync_workflow "$project"
        done
    fi
    
    echo "================================"
    echo "동기화 완료!"
    echo "================================"
}

main "$@"