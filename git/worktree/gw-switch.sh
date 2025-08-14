#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/git-common.sh"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [branch-name]

Switch to a different git worktree.

Options:
    -l, --last          Switch to the last used worktree
    -m, --main          Switch to the main worktree
    -h, --help          Show this help message

Examples:
    $(basename "$0")                    # Interactive selection (requires fzf)
    $(basename "$0") feature/branch     # Switch to specific branch worktree
    $(basename "$0") -l                 # Switch to last used worktree
    $(basename "$0") -m                 # Switch to main worktree

EOF
    exit 0
}

# History file for tracking last worktree
HISTORY_FILE="$HOME/.git_worktree_history"

# Save current worktree to history
save_to_history() {
    local current_path="$1"
    echo "$current_path" > "$HISTORY_FILE"
}

# Get last worktree from history
get_last_worktree() {
    if [[ -f "$HISTORY_FILE" ]]; then
        cat "$HISTORY_FILE"
    else
        echo ""
    fi
}

# Parse arguments
TARGET_BRANCH=""
SWITCH_TO_LAST=false
SWITCH_TO_MAIN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--last)
            SWITCH_TO_LAST=true
            shift
            ;;
        -m|--main)
            SWITCH_TO_MAIN=true
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
            TARGET_BRANCH="$1"
            shift
            ;;
    esac
done

# Check if we're in a git repository
check_git_repo || exit 1

# Save current directory before switching
CURRENT_DIR=$(pwd)

# Handle switch to main worktree
if [[ "$SWITCH_TO_MAIN" == true ]]; then
    MAIN_WORKTREE=$(get_main_worktree)
    if [[ "$CURRENT_DIR" == "$MAIN_WORKTREE" ]]; then
        print_info "Already in main worktree"
        exit 0
    fi
    save_to_history "$CURRENT_DIR"
    print_success "Switching to main worktree: $MAIN_WORKTREE"
    cd "$MAIN_WORKTREE"
    exec $SHELL
    exit 0
fi

# Handle switch to last worktree
if [[ "$SWITCH_TO_LAST" == true ]]; then
    LAST_WORKTREE=$(get_last_worktree)
    if [[ -z "$LAST_WORKTREE" ]]; then
        print_error "No worktree history found"
        exit 1
    fi
    if [[ ! -d "$LAST_WORKTREE" ]]; then
        print_error "Last worktree no longer exists: $LAST_WORKTREE"
        exit 1
    fi
    if [[ "$CURRENT_DIR" == "$LAST_WORKTREE" ]]; then
        print_info "Already in last worktree"
        exit 0
    fi
    save_to_history "$CURRENT_DIR"
    print_success "Switching to last worktree: $LAST_WORKTREE"
    cd "$LAST_WORKTREE"
    exec $SHELL
    exit 0
fi

# Handle switch to specific branch
if [[ -n "$TARGET_BRANCH" ]]; then
    if ! worktree_exists "$TARGET_BRANCH"; then
        print_error "No worktree found for branch: $TARGET_BRANCH"
        echo "Use 'gw-add.sh $TARGET_BRANCH' to create it"
        exit 1
    fi
    
    WORKTREE_PATH=$(get_worktree_path "$TARGET_BRANCH")
    if [[ "$CURRENT_DIR" == "$WORKTREE_PATH" ]]; then
        print_info "Already in worktree for branch: $TARGET_BRANCH"
        exit 0
    fi
    
    save_to_history "$CURRENT_DIR"
    print_success "Switching to worktree: $WORKTREE_PATH"
    cd "$WORKTREE_PATH"
    exec $SHELL
    exit 0
fi

# Interactive selection (requires fzf)
if ! command -v fzf &> /dev/null; then
    print_error "fzf is required for interactive selection"
    echo "Install fzf or specify a branch name"
    echo ""
    echo "Available worktrees:"
    "$SCRIPT_DIR/gw-list.sh" -s
    exit 1
fi

# Get list of worktrees for interactive selection
print_header "Select Worktree"

# Build worktree list for fzf
WORKTREE_LIST=""
while IFS='|' read -r path branch commit; do
    if [[ "$path" == "$CURRENT_DIR" ]]; then
        # Skip current worktree
        continue
    fi
    
    # Check if this is the main worktree
    MAIN_WORKTREE=$(get_main_worktree)
    if [[ "$path" == "$MAIN_WORKTREE" ]]; then
        label="[MAIN] $branch"
    else
        label="$branch"
    fi
    
    # Add to list
    if [[ -z "$WORKTREE_LIST" ]]; then
        WORKTREE_LIST="$label|$path"
    else
        WORKTREE_LIST="$WORKTREE_LIST"$'\n'"$label|$path"
    fi
done < <(get_worktree_info)

if [[ -z "$WORKTREE_LIST" ]]; then
    print_error "No other worktrees available"
    exit 1
fi

# Use fzf for selection
SELECTED=$(echo "$WORKTREE_LIST" | fzf --height=40% --reverse --header="Select worktree to switch to:" | cut -d'|' -f2)

if [[ -z "$SELECTED" ]]; then
    echo "No worktree selected"
    exit 0
fi

# Switch to selected worktree
save_to_history "$CURRENT_DIR"
print_success "Switching to worktree: $SELECTED"
cd "$SELECTED"
exec $SHELL