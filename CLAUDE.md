# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a personal development environment setup and management repository. It contains scripts, configurations, and documentation for consistently setting up and maintaining development environments across different machines.

## Key Commands

### Quick Setup
- **Initial environment setup**: `./run.sh` - Sets up dotfiles (.bashrc, .vimrc) and Vim plugins
- **Docker installation**: `sudo ./docker/install_docker.sh`
- **Kubernetes installation**: `sudo ./kubernetes/install_kubernetes.sh`
- **Miniconda installation**: `./miniconda/install_conda.sh`

### Docker Operations
- **Build dev container**: `docker-compose -f docker-compose-dev.yaml build`
- **Run dev container**: `docker-compose -f docker-compose-dev.yaml up -d`
- **Change Docker root directory**: Use `./docker/change_docker_root_dir.sh`
- **Remove Docker**: `sudo ./docker/remove_docker.sh`

### Kubernetes Management
- **Setup master node**: `sudo ./kubernetes/setup_cluster.sh`
- **Remove Kubernetes**: `sudo ./kubernetes/remove_kubeadm.sh`
- **Apply Flannel CNI**: `kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`

## Architecture Overview

This repository follows a modular structure where each technology stack has its own directory with installation scripts and documentation:

### Directory Structure
- **docker/**: Docker installation and configuration management
  - Includes scripts for Ubuntu-based Docker setup
  - Docker Compose configuration for development containers
  - Instructions for changing Docker data directory

- **kubernetes/**: Kubernetes cluster setup using kubeadm
  - Automated installation for Ubuntu 20.04 LTS
  - Master and worker node configuration
  - Includes troubleshooting guides in README

- **dot_files/**: Personal configuration files
  - Custom .bashrc with git-aware prompt
  - Vim configuration
  - macOS window manager configs (skhd, yabai)

- **git/**: Git configuration helpers
- **nfs/**: NFS mount setup documentation
- **miniconda/**: Python environment management
- **vim/**: Vim-specific documentation and tips

### Key Design Decisions

1. **Consistency**: All scripts follow similar patterns for installation and removal
2. **Idempotency**: Scripts can be run multiple times safely (backup existing configs)
3. **Ubuntu-focused**: Primary support for Ubuntu 20.04 LTS, with some macOS support
4. **Root requirement**: Most infrastructure scripts require sudo/root access
5. **Modular approach**: Each component can be installed independently

## Development Workflow

When modifying or adding new setup scripts:
1. Follow existing script patterns (error handling with `set -e`, clear comments)
2. Add corresponding remove/uninstall scripts where applicable
3. Document requirements and compatibility in component README files
4. Test on clean Ubuntu 20.04 systems when possible

## Important Configuration Details

- **Docker dev container**: Uses custom user "coolseaweed" (UID: 1001, GID: 100)
- **Kubernetes**: Default pod network CIDR is 10.244.0.0/16
- **Bash prompt**: Custom prompt with git branch awareness
- **Environment**: Assumes Homebrew on macOS (`/opt/homebrew/bin/brew`)

## Notes for Maintenance

- Always backup existing configurations before overwriting (.orig extension)
- Kubernetes requires swap to be disabled
- Docker and Kubernetes scripts need root privileges
- The run.sh script is interactive and asks for confirmation before replacing dotfiles