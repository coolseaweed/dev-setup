#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/git-common.sh"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <branch-name|path>

Remove a git worktree safely.

Options:
    -f, --force         Force removal even with uncommitted changes
    -b, --remove-branch Also remove the branch after removing worktree
    -y, --yes           Skip confirmation prompt
    -h, --help          Show this help message

Examples:
    $(basename "$0") feature/old-feature      # Remove worktree for branch
    $(basename "$0") /path/to/worktree        # Remove worktree by path
    $(basename "$0") -f feature/test          # Force remove with uncommitted changes
    $(basename "$0") -fb feature/obsolete     # Remove worktree and branch

EOF
    exit 0
}

# Parse arguments
TARGET=""
FORCE_REMOVE=false
REMOVE_BRANCH=false
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_REMOVE=true
            shift
            ;;
        -b|--remove-branch)
            REMOVE_BRANCH=true
            shift
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
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
            TARGET="$1"
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "$TARGET" ]]; then
    print_error "Branch name or path is required"
    usage
fi

# Check if we're in a git repository
check_git_repo || exit 1

# Determine if target is a path or branch name
WORKTREE_PATH=""
BRANCH_NAME=""

if [[ -d "$TARGET" ]]; then
    # Target is a path - get absolute path
    WORKTREE_PATH="$(cd "$TARGET" && pwd)"
    # Get branch name from worktree using improved parsing
    BRANCH_NAME=$(git worktree list --porcelain | awk -v path="$WORKTREE_PATH" '
        /^worktree/ { current_wt = substr($0, 10) }
        /^branch/ && current_wt == path { 
            branch = substr($0, 8)
            gsub("refs/heads/", "", branch)
            print branch
            exit
        }
    ')
    
    # If branch name not found, it might be a detached HEAD
    if [[ -z "$BRANCH_NAME" ]]; then
        print_warning "Could not determine branch name for worktree at: $WORKTREE_PATH"
    fi
elif worktree_exists "$TARGET"; then
    # Target is a branch name
    BRANCH_NAME="$TARGET"
    WORKTREE_PATH=$(get_worktree_path "$BRANCH_NAME")
    
    # Validate that we got a single, valid path
    if [[ -z "$WORKTREE_PATH" ]]; then
        print_error "Could not find worktree path for branch: $TARGET"
        exit 1
    fi
    
    # Check if multiple paths were returned (shouldn't happen with fixed function)
    if [[ $(echo "$WORKTREE_PATH" | wc -l) -gt 1 ]]; then
        print_error "Multiple worktrees found for branch: $TARGET"
        echo "Worktrees found:"
        echo "$WORKTREE_PATH"
        exit 1
    fi
else
    print_error "Worktree not found: $TARGET"
    echo "Use 'gw-list.sh' to see available worktrees"
    exit 1
fi

# Check if this is the main worktree
MAIN_WORKTREE=$(get_main_worktree)
if [[ "$WORKTREE_PATH" == "$MAIN_WORKTREE" ]]; then
    print_error "Cannot remove the main worktree"
    exit 1
fi

# Check if we're currently in the worktree being removed
CURRENT_DIR=$(pwd)
if [[ "$CURRENT_DIR" == "$WORKTREE_PATH"* ]]; then
    print_error "Cannot remove worktree while inside it"
    echo "Please change to a different directory first"
    exit 1
fi

# Show what will be removed
print_header "Worktree Removal"
echo "Path: $WORKTREE_PATH"
if [[ -n "$BRANCH_NAME" ]]; then
    echo "Branch: $BRANCH_NAME"
fi

# Check for uncommitted changes
if [[ -d "$WORKTREE_PATH" ]]; then
    cd "$WORKTREE_PATH" 2>/dev/null && {
        if has_uncommitted_changes; then
            print_warning "This worktree has uncommitted changes"
            if [[ "$FORCE_REMOVE" != true ]]; then
                print_error "Use -f to force removal with uncommitted changes"
                cd - > /dev/null
                exit 1
            fi
        fi
        cd - > /dev/null
    }
fi

# Confirm removal
if [[ "$SKIP_CONFIRM" != true ]]; then
    echo ""
    if [[ "$REMOVE_BRANCH" == true ]]; then
        print_warning "This will also delete the branch: $BRANCH_NAME"
    fi
    
    if ! confirm "Remove this worktree?"; then
        echo "Removal cancelled"
        exit 0
    fi
fi

# Remove the worktree
print_info "Removing worktree..."
if [[ "$FORCE_REMOVE" == true ]]; then
    git worktree remove --force "$WORKTREE_PATH"
else
    git worktree remove "$WORKTREE_PATH"
fi

if [[ $? -eq 0 ]]; then
    print_success "Worktree removed successfully"
    
    # Check if the directory still exists (might have leftover files like .next, node_modules, etc.)
    if [[ -d "$WORKTREE_PATH" ]]; then
        print_info "Removing remaining directory and its contents..."
        rm -rf "$WORKTREE_PATH"
        if [[ $? -eq 0 ]]; then
            print_success "Directory completely removed"
        else
            print_warning "Failed to remove remaining directory: $WORKTREE_PATH"
        fi
    fi
else
    print_error "Failed to remove worktree"
    exit 1
fi

# Check if user wants to remove the branch (if not explicitly specified)
if [[ "$REMOVE_BRANCH" == false ]] && [[ -n "$BRANCH_NAME" ]] && [[ "$SKIP_CONFIRM" != true ]]; then
    echo ""
    print_info "The branch '$BRANCH_NAME' still exists."
    if confirm "Do you want to remove the branch as well?" "n"; then
        REMOVE_BRANCH=true
    fi
fi

# Optionally remove the branch
if [[ "$REMOVE_BRANCH" == true ]] && [[ -n "$BRANCH_NAME" ]]; then
    print_info "Removing branch: $BRANCH_NAME"
    
    # Check if branch exists
    if branch_exists "$BRANCH_NAME"; then
        # Check if it's the current branch
        CURRENT_BRANCH=$(get_current_branch)
        if [[ "$CURRENT_BRANCH" == "$BRANCH_NAME" ]]; then
            print_error "Cannot delete the current branch"
            exit 1
        fi
        
        # Try to delete the branch
        if git branch -d "$BRANCH_NAME" 2>/dev/null; then
            print_success "Branch removed successfully"
        elif [[ "$FORCE_REMOVE" == true ]]; then
            git branch -D "$BRANCH_NAME"
            print_success "Branch force-removed successfully"
        else
            print_warning "Branch has unmerged changes. Use -f to force removal"
        fi
    else
        print_warning "Branch not found: $BRANCH_NAME"
    fi
fi

# Clean up any prunable worktrees
print_info "Cleaning up prunable worktrees..."
git worktree prune

# Final status message
if [[ "$REMOVE_BRANCH" == false ]] && [[ -n "$BRANCH_NAME" ]] && branch_exists "$BRANCH_NAME"; then
    echo ""
    print_info "Note: Branch '$BRANCH_NAME' still exists."
    echo "To remove it later, use: git branch -d $BRANCH_NAME"
    echo "Or use: $(basename "$0") -b $BRANCH_NAME"
fi

print_success "Cleanup complete!"