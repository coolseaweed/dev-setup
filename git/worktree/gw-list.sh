#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/git-common.sh"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

List all git worktrees with detailed information.

Options:
    -s, --short         Show short format (path and branch only)
    -v, --verbose       Show verbose output with size and age
    -p, --porcelain     Machine-readable output
    -h, --help          Show this help message

Examples:
    $(basename "$0")              # List all worktrees
    $(basename "$0") -s           # Short format
    $(basename "$0") -v           # Verbose with size and age

EOF
    exit 0
}

# Parse arguments
SHORT_FORMAT=false
VERBOSE_FORMAT=false
PORCELAIN_FORMAT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--short)
            SHORT_FORMAT=true
            shift
            ;;
        -v|--verbose)
            VERBOSE_FORMAT=true
            shift
            ;;
        -p|--porcelain)
            PORCELAIN_FORMAT=true
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

# Get current directory to highlight current worktree
CURRENT_DIR=$(pwd)

# Function to get directory size
get_dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS
            du -sk "$dir" 2>/dev/null | cut -f1
        else
            # Linux
            du -sb "$dir" 2>/dev/null | cut -f1
        fi
    else
        echo "0"
    fi
}

# Porcelain format
if [[ "$PORCELAIN_FORMAT" == true ]]; then
    git worktree list --porcelain
    exit 0
fi

# Short format
if [[ "$SHORT_FORMAT" == true ]]; then
    git worktree list | while read -r line; do
        path=$(echo "$line" | awk '{print $1}')
        branch=$(echo "$line" | sed -n 's/.*\[\(.*\)\].*/\1/p')
        
        if [[ "$path" == "$CURRENT_DIR"* ]]; then
            echo -e "${GREEN}→ $path ${CYAN}[$branch]${NC}"
        else
            echo "  $path [$branch]"
        fi
    done
    exit 0
fi

# Default and verbose format
print_header "Git Worktrees"

# Get main worktree
MAIN_WORKTREE=$(get_main_worktree)

# Process worktrees
worktree_count=0
total_size=0

while IFS='|' read -r path branch commit; do
    worktree_count=$((worktree_count + 1))
    
    # Check if this is the current worktree
    is_current=false
    if [[ "$path" == "$CURRENT_DIR"* ]]; then
        is_current=true
    fi
    
    # Check if this is the main worktree
    is_main=false
    if [[ "$path" == "$MAIN_WORKTREE" ]]; then
        is_main=true
    fi
    
    # Format the output
    if [[ "$is_current" == true ]]; then
        echo -ne "${GREEN}→ "
    else
        echo -n "  "
    fi
    
    # Show path
    if [[ "$is_main" == true ]]; then
        echo -ne "${BOLD}$path${NC} "
    else
        echo -ne "$path "
    fi
    
    # Show branch
    if [[ "$branch" == "detached" ]]; then
        echo -ne "${YELLOW}[detached HEAD]${NC}"
    else
        echo -ne "${CYAN}[$branch]${NC}"
    fi
    
    # Show additional info for verbose mode
    if [[ "$VERBOSE_FORMAT" == true ]]; then
        echo ""
        
        # Get directory size
        if [[ -d "$path" ]]; then
            size_kb=$(get_dir_size "$path")
            size_formatted=$(format_size $((size_kb * 1024)))
            total_size=$((total_size + size_kb))
            echo -n "    Size: $size_formatted"
        else
            echo -n "    ${RED}Directory not found${NC}"
        fi
        
        # Get last commit age
        if [[ -n "$commit" ]] && [[ "$commit" != "0000000000000000000000000000000000000000" ]]; then
            age=$(get_commit_age "$commit")
            echo -n " | Last commit: $age"
        fi
        
        # Check for uncommitted changes
        if [[ -d "$path" ]]; then
            cd "$path" 2>/dev/null && {
                if has_uncommitted_changes; then
                    echo -n " | ${YELLOW}Has uncommitted changes${NC}"
                fi
                cd - > /dev/null
            }
        fi
    fi
    
    echo ""
    
done < <(get_worktree_info)

# Summary
echo ""
echo "Total worktrees: $worktree_count"

if [[ "$VERBOSE_FORMAT" == true ]] && [[ $total_size -gt 0 ]]; then
    total_formatted=$(format_size $((total_size * 1024)))
    echo "Total size: $total_formatted"
fi

# Show helpful commands
echo ""
echo "Commands:"
echo "  Create:  gw-add.sh <branch>"
echo "  Remove:  gw-remove.sh <branch>"
echo "  Switch:  gw-switch.sh"
echo "  Clean:   gw-clean.sh"