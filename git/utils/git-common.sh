#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print functions
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

print_info() {
    echo -e "${CYAN}Info: $1${NC}"
}

print_header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        return 1
    fi
    return 0
}

# Get the main worktree directory
get_main_worktree() {
    git worktree list | head -n1 | awk '{print $1}'
}

# Get current branch name
get_current_branch() {
    git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD
}

# Check if branch exists
branch_exists() {
    local branch="$1"
    git show-ref --verify --quiet "refs/heads/$branch"
}

# Check if worktree exists for a branch
worktree_exists() {
    local branch="$1"
    git worktree list --porcelain | grep -q "branch refs/heads/$branch"
}

# Get worktree path for a branch
get_worktree_path() {
    local branch="$1"
    git worktree list --porcelain | awk -v branch="refs/heads/$branch" '
        /^worktree/ { current_wt = substr($0, 10) }
        /^branch/ && $2 == branch { print current_wt; exit }
    '
}

# Confirm action with user
confirm() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" response
    response=${response:-$default}
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        print_info "Created directory: $dir"
    fi
}

# Sanitize branch name for directory
sanitize_branch_name() {
    local branch="$1"
    echo "$branch" | sed 's/[^a-zA-Z0-9._-]/-/g'
}

# Get default worktree location
get_default_worktree_location() {
    local branch="$1"
    local main_worktree=$(get_main_worktree)
    local parent_dir=$(dirname "$main_worktree")
    local repo_name=$(basename "$main_worktree")
    local safe_branch=$(sanitize_branch_name "$branch")
    
    echo "${parent_dir}/${repo_name}-${safe_branch}"
}

# Check for uncommitted changes
has_uncommitted_changes() {
    ! git diff-index --quiet HEAD -- 2>/dev/null
}

# Get worktree info in formatted way
get_worktree_info() {
    git worktree list --porcelain | awk '
        /^worktree/ { wt = substr($0, 10) }
        /^HEAD/ { head = substr($0, 6) }
        /^branch/ { branch = substr($0, 8); gsub("refs/heads/", "", branch) }
        /^$/ { 
            if (wt) {
                printf "%s|%s|%s\n", wt, branch ? branch : "detached", head
            }
            wt = ""; branch = ""; head = ""
        }
        END {
            if (wt) {
                printf "%s|%s|%s\n", wt, branch ? branch : "detached", head
            }
        }
    '
}

# Format file size
format_size() {
    local size=$1
    if [[ $size -ge 1073741824 ]]; then
        echo "$(( size / 1073741824 ))G"
    elif [[ $size -ge 1048576 ]]; then
        echo "$(( size / 1048576 ))M"
    elif [[ $size -ge 1024 ]]; then
        echo "$(( size / 1024 ))K"
    else
        echo "${size}B"
    fi
}

# Get age of last commit in human readable format
get_commit_age() {
    local commit="$1"
    if [[ -z "$commit" ]]; then
        echo "unknown"
        return
    fi
    
    local timestamp=$(git show -s --format=%ct "$commit" 2>/dev/null)
    if [[ -z "$timestamp" ]]; then
        echo "unknown"
        return
    fi
    
    local now=$(date +%s)
    local diff=$((now - timestamp))
    
    if [[ $diff -lt 3600 ]]; then
        echo "$((diff / 60)) minutes ago"
    elif [[ $diff -lt 86400 ]]; then
        echo "$((diff / 3600)) hours ago"
    elif [[ $diff -lt 604800 ]]; then
        echo "$((diff / 86400)) days ago"
    elif [[ $diff -lt 2592000 ]]; then
        echo "$((diff / 604800)) weeks ago"
    else
        echo "$((diff / 2592000)) months ago"
    fi
}