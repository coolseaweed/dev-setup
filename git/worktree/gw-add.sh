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
    # Handle both absolute and relative paths
    if [[ "$CUSTOM_PATH" = /* ]]; then
        # Absolute path
        WORKTREE_PATH="$CUSTOM_PATH"
    else
        # Relative path - make it absolute
        WORKTREE_PATH="$(pwd)/$CUSTOM_PATH"
    fi
elif [[ -n "$BASE_PATH" ]]; then
    # Use specified base directory
    if [[ "$BASE_PATH" = /* ]]; then
        # Absolute base path
        BASE_DIR="$BASE_PATH"
    else
        # Relative base path - make it absolute
        BASE_DIR="$(pwd)/$BASE_PATH"
    fi
    # Ensure base directory exists
    if [[ ! -d "$BASE_DIR" ]]; then
        print_error "Base directory does not exist: $BASE_DIR"
        exit 1
    fi
    REPO_NAME=$(basename "$(get_main_worktree)")
    SAFE_BRANCH=$(sanitize_branch_name "$BRANCH")
    WORKTREE_PATH="${BASE_DIR}/${REPO_NAME}-${SAFE_BRANCH}"
else
    # Use default location (parent directory of main worktree)
    WORKTREE_PATH=$(get_default_worktree_location "$BRANCH")
fi

# Check if path already exists
if [[ -e "$WORKTREE_PATH" ]]; then
    print_error "Path already exists: $WORKTREE_PATH"
    exit 1
fi

# Build git worktree command
GIT_CMD="git worktree add"

# Add path
GIT_CMD="$GIT_CMD \"$WORKTREE_PATH\""

# Handle branch creation options
if [[ "$FORCE_BRANCH" == true ]]; then
    GIT_CMD="$GIT_CMD -B \"$BRANCH\""
    if [[ -n "$FROM_BRANCH" ]]; then
        GIT_CMD="$GIT_CMD \"$FROM_BRANCH\""
    fi
elif [[ "$NEW_BRANCH" == true ]]; then
    if ! branch_exists "$BRANCH"; then
        GIT_CMD="$GIT_CMD -b \"$BRANCH\""
        if [[ -n "$FROM_BRANCH" ]]; then
            GIT_CMD="$GIT_CMD \"$FROM_BRANCH\""
        fi
    else
        print_error "Branch '$BRANCH' already exists. Use -B to force."
        exit 1
    fi
else
    # Existing branch
    if ! branch_exists "$BRANCH"; then
        print_error "Branch '$BRANCH' does not exist. Use -b to create it."
        exit 1
    fi
    GIT_CMD="$GIT_CMD \"$BRANCH\""
fi

# Set default merge target based on from branch if specified, otherwise current branch
if [[ -z "$TARGET_BRANCH" ]] && ([[ "$NEW_BRANCH" == true ]] || [[ "$FORCE_BRANCH" == true ]]); then
    if [[ -n "$FROM_BRANCH" ]]; then
        TARGET_BRANCH="$FROM_BRANCH"
        print_info "Setting default merge target to base branch: $TARGET_BRANCH"
    else
        CURRENT_BRANCH=$(get_current_branch)
        if [[ -n "$CURRENT_BRANCH" ]]; then
            TARGET_BRANCH="$CURRENT_BRANCH"
            print_info "Setting default merge target to current branch: $TARGET_BRANCH"
        fi
    fi
fi

# Show what we're about to do
print_header "Creating Worktree"
echo "Branch: $BRANCH"
echo "Path: $WORKTREE_PATH"
if [[ -n "$FROM_BRANCH" ]]; then
    echo "From: $FROM_BRANCH"
fi
if [[ -n "$TARGET_BRANCH" ]]; then
    echo "Merge target: $TARGET_BRANCH"
fi

# Execute the command
print_info "Executing: $GIT_CMD"
eval $GIT_CMD

if [[ $? -eq 0 ]]; then
    print_success "Worktree created successfully!"
    
    # Set merge target branch if specified
    if [[ -n "$TARGET_BRANCH" ]]; then
        print_info "Setting merge target branch to: $TARGET_BRANCH"
        
        # Store merge target in git config for this branch
        git config --local "branch.${BRANCH}.mergeTarget" "$TARGET_BRANCH"
        
        # Set up the branch for proper PR targeting
        if [[ "$NEW_BRANCH" == true ]] || [[ "$FORCE_BRANCH" == true ]]; then
            cd "$WORKTREE_PATH"
            
            # Create a git alias for easy PR creation
            if branch_exists "$TARGET_BRANCH"; then
                git config --local "alias.pr-create" "!f() { \
                    if command -v gh &> /dev/null; then \
                        gh pr create --base $TARGET_BRANCH \"\$@\"; \
                    else \
                        echo 'Create PR with base branch: $TARGET_BRANCH'; \
                        echo 'GitHub: gh pr create --base $TARGET_BRANCH'; \
                        echo 'GitLab: glab mr create --target-branch $TARGET_BRANCH'; \
                    fi; \
                }; f"
                
                print_info "Created git alias 'pr-create' for this branch"
                echo "Run 'git pr-create' to create a PR targeting $TARGET_BRANCH"
            fi
            
            cd - > /dev/null
        fi
        
        print_success "Merge target set to: $TARGET_BRANCH"
        echo "You can view this with: git config branch.${BRANCH}.mergeTarget"
    fi
    
    # Show post-creation info
    echo ""
    echo "To start working in the new worktree:"
    echo "  cd $WORKTREE_PATH"
    
    # Optionally checkout to the new worktree
    if [[ "$CHECKOUT_AFTER" == true ]]; then
        print_info "Switching to new worktree..."
        cd "$WORKTREE_PATH"
        exec $SHELL
    fi
else
    print_error "Failed to create worktree"
    exit 1
fi