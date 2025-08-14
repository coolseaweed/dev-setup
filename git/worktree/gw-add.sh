#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/git-common.sh"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <branch-name>

Create a new git worktree for the specified branch.

Options:
    -p, --path PATH     Custom path for the worktree (supports absolute paths)
    -P, --base-path DIR Base directory for worktree creation (default: parent of main repo)
    -b, --new-branch    Create a new branch
    -B, --force-branch  Create a new branch (force, overwrites if exists)
    -c, --checkout      Switch to the new worktree after creation
    -f, --from BRANCH   Create new branch from specified branch (default: current)
    -t, --target BRANCH Set merge target branch (default: current branch for new branches)
    -h, --help          Show this help message

Examples:
    $(basename "$0") feature/new-feature           # Create worktree for existing branch
    $(basename "$0") -b feature/new-feature        # Create new branch with current branch as merge target
    $(basename "$0") -p ~/projects/feature test    # Create worktree at custom path
    $(basename "$0") -P ~/work feature/test        # Create in ~/work directory
    $(basename "$0") -bc feature/new -f develop    # Create from develop and switch to it
    $(basename "$0") -b feature/new -t main        # Override merge target to main

EOF
    exit 0
}

# Parse arguments
BRANCH=""
CUSTOM_PATH=""
BASE_PATH=""
NEW_BRANCH=false
FORCE_BRANCH=false
CHECKOUT_AFTER=false
FROM_BRANCH=""
TARGET_BRANCH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--path)
            CUSTOM_PATH="$2"
            shift 2
            ;;
        -P|--base-path)
            BASE_PATH="$2"
            shift 2
            ;;
        -b|--new-branch)
            NEW_BRANCH=true
            shift
            ;;
        -B|--force-branch)
            FORCE_BRANCH=true
            shift
            ;;
        -c|--checkout)
            CHECKOUT_AFTER=true
            shift
            ;;
        -f|--from)
            FROM_BRANCH="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_BRANCH="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        -*)
            print_error "Unknown option: $1"
            usage
            ;;
        *)
            BRANCH="$1"
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "$BRANCH" ]]; then
    print_error "Branch name is required"
    usage
fi

# Check if we're in a git repository
check_git_repo || exit 1

# Check if worktree already exists for this branch
if worktree_exists "$BRANCH"; then
    existing_path=$(get_worktree_path "$BRANCH")
    print_error "Worktree already exists for branch '$BRANCH' at: $existing_path"
    echo "Use 'cd $existing_path' to switch to it"
    exit 1
fi

# Determine worktree path
if [[ -n "$CUSTOM_PATH" ]]; then
    WORKTREE_PATH="$([[ "$CUSTOM_PATH" = /* ]] && echo "$CUSTOM_PATH" || echo "$(pwd)/$CUSTOM_PATH")"
elif [[ -n "$BASE_PATH" ]]; then
    BASE_DIR="$([[ "$BASE_PATH" = /* ]] && echo "$BASE_PATH" || echo "$(pwd)/$BASE_PATH")"
    [[ ! -d "$BASE_DIR" ]] && { print_error "Base directory does not exist: $BASE_DIR"; exit 1; }
    REPO_NAME=$(basename "$(get_main_worktree)")
    SAFE_BRANCH=$(sanitize_branch_name "$BRANCH")
    WORKTREE_PATH="${BASE_DIR}/${REPO_NAME}-${SAFE_BRANCH}"
else
    WORKTREE_PATH=$(get_default_worktree_location "$BRANCH")
fi

# Check if path already exists
if [[ -e "$WORKTREE_PATH" ]]; then
    print_error "Path already exists: $WORKTREE_PATH"
    exit 1
fi

# Create worktree
if [[ "$FORCE_BRANCH" == true ]]; then
    git worktree add -B "$BRANCH" "$WORKTREE_PATH" ${FROM_BRANCH:+"$FROM_BRANCH"}
elif [[ "$NEW_BRANCH" == true ]]; then
    if branch_exists "$BRANCH"; then
        print_error "Branch '$BRANCH' already exists. Use -B to force."
        exit 1
    fi
    git worktree add -b "$BRANCH" "$WORKTREE_PATH" ${FROM_BRANCH:+"$FROM_BRANCH"}
else
    if ! branch_exists "$BRANCH"; then
        print_error "Branch '$BRANCH' does not exist. Use -b to create it."
        exit 1
    fi
    git worktree add "$WORKTREE_PATH" "$BRANCH"
fi

# Set default merge target
if [[ -z "$TARGET_BRANCH" ]] && ([[ "$NEW_BRANCH" == true ]] || [[ "$FORCE_BRANCH" == true ]]); then
    TARGET_BRANCH="${FROM_BRANCH:-$(get_current_branch)}"
fi

# Show info
print_header "Creating Worktree"
echo "Branch: $BRANCH"
echo "Path: $WORKTREE_PATH"
[[ -n "$FROM_BRANCH" ]] && echo "From: $FROM_BRANCH"
[[ -n "$TARGET_BRANCH" ]] && echo "Target: $TARGET_BRANCH"

if [[ $? -eq 0 ]]; then
    print_success "Worktree created at: $WORKTREE_PATH"
    
    # Set merge target and PR alias
    if [[ -n "$TARGET_BRANCH" ]]; then
        git config --local "branch.${BRANCH}.mergeTarget" "$TARGET_BRANCH"
        
        if [[ ("$NEW_BRANCH" == true || "$FORCE_BRANCH" == true) && -n "$(command -v gh)" ]]; then
            (cd "$WORKTREE_PATH" && git config --local "alias.pr-create" "!gh pr create --base $TARGET_BRANCH")
            print_info "Use 'git pr-create' to create PR targeting $TARGET_BRANCH"
        fi
    fi
    
    # Copy .env* files from main worktree
    MAIN_WORKTREE=$(get_main_worktree)
    if [[ -n "$MAIN_WORKTREE" ]]; then
        ENV_FILES=$(find "$MAIN_WORKTREE" -maxdepth 1 -name ".env*" -type f 2>/dev/null)
        if [[ -n "$ENV_FILES" ]]; then
            print_info "Copying .env files..."
            while IFS= read -r env_file; do
                cp "$env_file" "$WORKTREE_PATH/"
                echo "  - $(basename "$env_file")"
            done <<< "$ENV_FILES"
        fi
    fi
    
    # Run npm install if package.json exists
    if [[ -f "$WORKTREE_PATH/package.json" ]]; then
        print_info "Running npm install..."
        (cd "$WORKTREE_PATH" && npm install)
        if [[ $? -eq 0 ]]; then
            print_success "Dependencies installed successfully"
        else
            print_warning "npm install failed, but worktree was created"
        fi
    fi
    
    # Auto checkout if requested
    if [[ "$CHECKOUT_AFTER" == true ]]; then
        cd "$WORKTREE_PATH" && exec $SHELL
    fi
else
    print_error "Failed to create worktree"
    exit 1
fi