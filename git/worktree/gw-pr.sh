#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/git-common.sh"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [title]

Create a Pull Request using the configured merge target branch.

Options:
    -t, --target BRANCH Override the configured merge target
    -d, --draft         Create as draft PR
    -f, --fill          Pre-fill PR description
    -h, --help          Show this help message

Examples:
    $(basename "$0")                    # Create PR with configured target
    $(basename "$0") "Fix bug"          # Create PR with title
    $(basename "$0") -t main "Feature"  # Override target branch
    $(basename "$0") -d                 # Create draft PR

EOF
    exit 0
}

# Parse arguments
TARGET_OVERRIDE=""
DRAFT=false
FILL=false
PR_TITLE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET_OVERRIDE="$2"
            shift 2
            ;;
        -d|--draft)
            DRAFT=true
            shift
            ;;
        -f|--fill)
            FILL=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            print_error "Unknown option: $1"
            usage
            ;;
        *)
            PR_TITLE="$1"
            shift
            ;;
    esac
done

# Check if we're in a git repository
check_git_repo || exit 1

# Get current branch
CURRENT_BRANCH=$(get_current_branch)
if [[ -z "$CURRENT_BRANCH" ]]; then
    print_error "Could not determine current branch"
    exit 1
fi

# Get configured merge target
MERGE_TARGET=""
if [[ -n "$TARGET_OVERRIDE" ]]; then
    MERGE_TARGET="$TARGET_OVERRIDE"
else
    MERGE_TARGET=$(git config "branch.${CURRENT_BRANCH}.mergeTarget" 2>/dev/null || echo "")
fi

# Default to main/master if no target configured
if [[ -z "$MERGE_TARGET" ]]; then
    if branch_exists "main"; then
        MERGE_TARGET="main"
    elif branch_exists "master"; then
        MERGE_TARGET="master"
    else
        print_error "No merge target configured and no main/master branch found"
        echo "Set merge target with: git config branch.${CURRENT_BRANCH}.mergeTarget <target-branch>"
        exit 1
    fi
    print_warning "No merge target configured, defaulting to: $MERGE_TARGET"
fi

print_header "Creating Pull Request"
echo "Current branch: $CURRENT_BRANCH"
echo "Target branch: $MERGE_TARGET"

# Check if target branch exists
if ! branch_exists "$MERGE_TARGET"; then
    print_error "Target branch '$MERGE_TARGET' does not exist"
    exit 1
fi

# Build PR creation command
if command -v gh &> /dev/null; then
    # GitHub CLI
    CMD="gh pr create --base $MERGE_TARGET"
    
    if [[ -n "$PR_TITLE" ]]; then
        CMD="$CMD --title \"$PR_TITLE\""
    fi
    
    if [[ "$DRAFT" == true ]]; then
        CMD="$CMD --draft"
    fi
    
    if [[ "$FILL" == true ]]; then
        CMD="$CMD --fill"
    fi
    
    print_info "Executing: $CMD"
    eval $CMD
    
elif command -v glab &> /dev/null; then
    # GitLab CLI
    CMD="glab mr create --target-branch $MERGE_TARGET"
    
    if [[ -n "$PR_TITLE" ]]; then
        CMD="$CMD --title \"$PR_TITLE\""
    fi
    
    if [[ "$DRAFT" == true ]]; then
        CMD="$CMD --draft"
    fi
    
    if [[ "$FILL" == true ]]; then
        CMD="$CMD --fill"
    fi
    
    print_info "Executing: $CMD"
    eval $CMD
    
else
    # Manual instructions
    print_warning "Neither 'gh' nor 'glab' CLI found"
    echo ""
    echo "Create PR manually with these settings:"
    echo "  Source branch: $CURRENT_BRANCH"
    echo "  Target branch: $MERGE_TARGET"
    if [[ -n "$PR_TITLE" ]]; then
        echo "  Title: $PR_TITLE"
    fi
    echo ""
    echo "GitHub URL format:"
    echo "  https://github.com/OWNER/REPO/compare/${MERGE_TARGET}...${CURRENT_BRANCH}"
    echo ""
    echo "Or install GitHub CLI: brew install gh"
    echo "Or install GitLab CLI: brew install glab"
fi