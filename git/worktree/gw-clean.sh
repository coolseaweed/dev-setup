#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/git-common.sh"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Clean up old, unused, or orphaned git worktrees.

Options:
    -d, --days DAYS     Remove worktrees older than DAYS (default: 30)
    -o, --orphaned      Remove worktrees with deleted branches
    -e, --empty         Remove worktrees with no commits
    -n, --dry-run       Show what would be removed without removing
    -f, --force         Force removal without confirmation
    -a, --all           Clean all types (orphaned, old, empty)
    -h, --help          Show this help message

Examples:
    $(basename "$0")                # Interactive cleanup
    $(basename "$0") -o             # Remove orphaned worktrees
    $(basename "$0") -d 60          # Remove worktrees older than 60 days
    $(basename "$0") -an            # Dry run for all cleanup types
    $(basename "$0") -af            # Force clean all types

EOF
    exit 0
}

# Parse arguments
DAYS_OLD=30
CLEAN_ORPHANED=false
CLEAN_EMPTY=false
CLEAN_OLD=false
DRY_RUN=false
FORCE=false
CLEAN_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--days)
            DAYS_OLD="$2"
            CLEAN_OLD=true
            shift 2
            ;;
        -o|--orphaned)
            CLEAN_ORPHANED=true
            shift
            ;;
        -e|--empty)
            CLEAN_EMPTY=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -a|--all)
            CLEAN_ALL=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if we're in a git repository
check_git_repo || exit 1

# If -a is used, enable all cleaning types
if [[ "$CLEAN_ALL" == true ]]; then
    CLEAN_ORPHANED=true
    CLEAN_EMPTY=true
    CLEAN_OLD=true
fi

# If no specific cleaning type is selected, show interactive menu
if [[ "$CLEAN_ORPHANED" == false ]] && [[ "$CLEAN_EMPTY" == false ]] && [[ "$CLEAN_OLD" == false ]]; then
    print_header "Git Worktree Cleanup"
    echo "Select cleanup options:"
    echo "1) Remove orphaned worktrees (deleted branches)"
    echo "2) Remove old worktrees (older than $DAYS_OLD days)"
    echo "3) Remove empty worktrees (no commits)"
    echo "4) All of the above"
    echo "5) Exit"
    echo ""
    read -p "Choice [1-5]: " choice
    
    case $choice in
        1) CLEAN_ORPHANED=true ;;
        2) CLEAN_OLD=true ;;
        3) CLEAN_EMPTY=true ;;
        4) CLEAN_ALL=true; CLEAN_ORPHANED=true; CLEAN_EMPTY=true; CLEAN_OLD=true ;;
        5) exit 0 ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac
fi

# Arrays to track worktrees to remove
declare -a WORKTREES_TO_REMOVE
declare -a REMOVAL_REASONS

# Get main worktree to exclude from cleanup
MAIN_WORKTREE=$(get_main_worktree)

# Function to add worktree to removal list
add_to_removal() {
    local path="$1"
    local reason="$2"
    
    # Don't add main worktree
    if [[ "$path" == "$MAIN_WORKTREE" ]]; then
        return
    fi
    
    # Check if already in list
    for wt in "${WORKTREES_TO_REMOVE[@]}"; do
        if [[ "$wt" == "$path" ]]; then
            return
        fi
    done
    
    WORKTREES_TO_REMOVE+=("$path")
    REMOVAL_REASONS+=("$reason")
}

print_header "Scanning Worktrees"

# Check for orphaned worktrees (branches that no longer exist)
if [[ "$CLEAN_ORPHANED" == true ]]; then
    print_info "Checking for orphaned worktrees..."
    
    while IFS='|' read -r path branch commit; do
        if [[ "$path" == "$MAIN_WORKTREE" ]]; then
            continue
        fi
        
        if [[ "$branch" != "detached" ]] && [[ -n "$branch" ]]; then
            # Check if branch still exists
            if ! git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
                add_to_removal "$path" "Branch '$branch' no longer exists"
            fi
        fi
    done < <(get_worktree_info)
fi

# Check for old worktrees
if [[ "$CLEAN_OLD" == true ]]; then
    print_info "Checking for worktrees older than $DAYS_OLD days..."
    
    CUTOFF_DATE=$(date -d "$DAYS_OLD days ago" +%s 2>/dev/null || date -v -${DAYS_OLD}d +%s)
    
    while IFS='|' read -r path branch commit; do
        if [[ "$path" == "$MAIN_WORKTREE" ]]; then
            continue
        fi
        
        if [[ -d "$path" ]]; then
            # Get last modified time of the worktree directory
            if [[ "$(uname)" == "Darwin" ]]; then
                # macOS
                LAST_MODIFIED=$(stat -f %m "$path")
            else
                # Linux
                LAST_MODIFIED=$(stat -c %Y "$path")
            fi
            
            if [[ $LAST_MODIFIED -lt $CUTOFF_DATE ]]; then
                DAYS_AGO=$(( ($(date +%s) - LAST_MODIFIED) / 86400 ))
                add_to_removal "$path" "Last modified $DAYS_AGO days ago"
            fi
        fi
    done < <(get_worktree_info)
fi

# Check for empty worktrees (no commits different from main)
if [[ "$CLEAN_EMPTY" == true ]]; then
    print_info "Checking for empty worktrees..."
    
    # Get main branch
    MAIN_BRANCH=$(cd "$MAIN_WORKTREE" && get_current_branch)
    
    while IFS='|' read -r path branch commit; do
        if [[ "$path" == "$MAIN_WORKTREE" ]]; then
            continue
        fi
        
        if [[ -d "$path" ]] && [[ "$branch" != "detached" ]]; then
            cd "$path" 2>/dev/null && {
                # Check if branch has any commits not in main
                UNIQUE_COMMITS=$(git rev-list --count "$MAIN_BRANCH".."$branch" 2>/dev/null || echo "0")
                if [[ "$UNIQUE_COMMITS" == "0" ]]; then
                    add_to_removal "$path" "No unique commits (identical to $MAIN_BRANCH)"
                fi
                cd - > /dev/null
            }
        fi
    done < <(get_worktree_info)
fi

# First, prune any worktrees that can be pruned
print_info "Pruning worktrees..."
git worktree prune

# Show results
if [[ ${#WORKTREES_TO_REMOVE[@]} -eq 0 ]]; then
    print_success "No worktrees to clean up!"
    exit 0
fi

# Display worktrees to be removed
print_header "Worktrees to Remove"
for i in "${!WORKTREES_TO_REMOVE[@]}"; do
    echo "  ${WORKTREES_TO_REMOVE[$i]}"
    echo "    Reason: ${REMOVAL_REASONS[$i]}"
done

echo ""
echo "Total: ${#WORKTREES_TO_REMOVE[@]} worktree(s)"

# If dry run, exit here
if [[ "$DRY_RUN" == true ]]; then
    echo ""
    print_info "Dry run - no changes made"
    exit 0
fi

# Confirm removal
if [[ "$FORCE" != true ]]; then
    echo ""
    if ! confirm "Remove these worktrees?" "n"; then
        echo "Cleanup cancelled"
        exit 0
    fi
fi

# Remove worktrees
print_header "Removing Worktrees"
REMOVED_COUNT=0
FAILED_COUNT=0

for path in "${WORKTREES_TO_REMOVE[@]}"; do
    print_info "Removing: $path"
    if git worktree remove --force "$path" 2>/dev/null; then
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
        print_success "Removed successfully"
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        print_warning "Failed to remove (may already be gone)"
    fi
done

# Final prune
print_info "Final cleanup..."
git worktree prune

# Summary
print_header "Cleanup Complete"
echo "Removed: $REMOVED_COUNT worktree(s)"
if [[ $FAILED_COUNT -gt 0 ]]; then
    echo "Failed: $FAILED_COUNT worktree(s)"
fi

print_success "Cleanup finished!"