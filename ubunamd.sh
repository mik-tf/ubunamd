#!/bin/bash

# AMD GPU Setup Script for Ubuntu
# License: Apache 2.0

# Get script name dynamically
SCRIPT_PATH="$0"
SCRIPT_NAME=$(basename "$SCRIPT_PATH")
INSTALL_NAME=$(basename "$SCRIPT_NAME" .sh)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging configuration
LOG_DIR="/var/log/${INSTALL_NAME}"
INSTALL_LOG="${LOG_DIR}/install.log"

# Version
VERSION="0.1.0"

# Helper Functions (keep the same as original)
log() {
    echo -e "${GREEN}[SETUP]${NC} $1"
    if [ -w "$INSTALL_LOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$INSTALL_LOG"
    fi
    sleep 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    if [ -w "$INSTALL_LOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$INSTALL_LOG"
    fi
    sleep 1
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    if [ -w "$INSTALL_LOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$INSTALL_LOG"
    fi
    sleep 1
    exit 1
}

setup_logging() {
    if [ ! -d "$LOG_DIR" ]; then
        sudo mkdir -p "$LOG_DIR" || error "Failed to create log directory"
    fi

    if [ ! -f "$INSTALL_LOG" ]; then
        sudo touch "$INSTALL_LOG" || error "Failed to create log file"
    fi

    sudo chown $USER:$USER "$LOG_DIR" || error "Failed to set log directory ownership"
    sudo chown $USER:$USER "$INSTALL_LOG" || error "Failed to set log file ownership"
    sudo chmod 755 "$LOG_DIR" || error "Failed to set log directory permissions"
    sudo chmod 644 "$INSTALL_LOG" || error "Failed to set log file permissions"
}

# Remaining helper functions (show_logs, show_recent_logs, delete_logs) remain the same

install_prerequisites_and_dependencies() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        warn "This script is designed for Ubuntu. Other distributions may not work correctly."
    fi

    log "Updating package lists..."
    if ! sudo apt update; then
        error "Failed to update package lists"
    fi

    local PACKAGES=(
        "wget"
        "curl"
        "pciutils"
        "build-essential"
        "software-properties-common"
        "linux-headers-$(uname -r)"
        "clinfo"
    )

    for package in "${PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$package"; then
            log "Installing $package..."
            if ! sudo apt install -y "$package"; then
                warn "Failed to install $package"
            fi
        else
            log "$package is already installed"
        fi
    done

    if [ "${PERFORM_UPGRADE:-false}" = true ]; then
        log "Performing system upgrade..."
        if ! sudo apt upgrade -y; then
            warn "Package upgrade failed, continuing anyway..."
        fi
    fi
}

setup_gpu() {
    log "Checking GPU and drivers..."
    
    if ! lspci | grep -i "AMD\|Radeon" > /dev/null; then
        error "No AMD GPU detected in this system!"
    fi

    log "AMD GPU detected. Checking current setup..."

    # Check for existing AMD drivers
    if lsmod | grep -q amdgpu; then
        CURRENT_DRIVER=$(modinfo amdgpu | grep version | awk '{print $2}')
        log "AMDGPU drivers are loaded (Version: $CURRENT_DRIVER)"
    else
        log "Installing AMDGPU drivers..."
        
        # Add ROCm repository
        if ! sudo apt-get install -y linux-headers-generic; then
            error "Failed to install required headers"
        fi
        
        wget -q -O - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
        echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/5.7 ubuntu main' | sudo tee /etc/apt/sources.list.d/rocm.list
        
        sudo apt update
        sudo apt install -y rocm-hip-libraries rocm-dev
    fi

    # Check ROCm installation
    if ! command -v rocm-smi &>/dev/null; then
        log "Installing ROCm tools..."
        if ! sudo apt install -y rocm-smi; then
            error "Failed to install ROCm tools"
        fi
        ROCM_VERSION=$(apt show rocm-smi | grep Version | awk '{print $2}')
        log "ROCm tools installed (Version: $ROCM_VERSION)"
    else
        ROCM_VERSION=$(apt show rocm-smi | grep Version | awk '{print $2}')
        log "ROCm is already installed (Version: $ROCM_VERSION)"
    fi
}

show_gpu_info() {
    echo -e "\n${BLUE}===== GPU Information =====${NC}"
    
    echo -e "\n${GREEN}GPU Hardware Details:${NC}"
    lspci | grep -i "AMD\|Radeon"
    
    echo -e "\n${GREEN}AMD Driver Details:${NC}"
    if lsmod | grep -q amdgpu; then
        modinfo amdgpu | grep -E 'version|description'
        echo -e "\n${GREEN}ROCm Version:${NC}"
        rocm-smi --version
    else
        echo "AMDGPU drivers not loaded"
    fi
    
    echo -e "\n${GREEN}Compute Devices:${NC}"
    clinfo 2>/dev/null | grep -E 'Platform Name|Device Name' || echo "No OpenCL devices found"
}

install() {
    echo -e "${GREEN}Installing ${INSTALL_NAME} v${VERSION}...${NC}"
    if ! sudo -v; then
        error "Failed to obtain sudo privileges"
    fi

    # Remove existing installation if any
    sudo rm -f "/usr/local/bin/${INSTALL_NAME}"
    
    # Install the script
    if ! sudo cp "$SCRIPT_PATH" "/usr/local/bin/${INSTALL_NAME}"; then
        error "Failed to copy script to /usr/local/bin"
    fi

    if ! sudo chown root:root "/usr/local/bin/${INSTALL_NAME}"; then
        error "Failed to set script ownership"
    fi

    if ! sudo chmod 755 "/usr/local/bin/${INSTALL_NAME}"; then
        error "Failed to set script permissions"
    fi

    # Create log directory with proper permissions
    sudo mkdir -p "$LOG_DIR"
    sudo chown $USER:$USER "$LOG_DIR"
    sudo chmod 755 "$LOG_DIR"

    echo -e "\n${PURPLE}${INSTALL_NAME} v${VERSION} has been installed successfully.${NC}"
    echo -e "\nTo see available commands, run: ${BLUE}${INSTALL_NAME} help${NC}"
}

uninstall() {
    echo -e "${GREEN}Uninstalling ${INSTALL_NAME}...${NC}"
    if ! sudo -v; then
        error "Failed to obtain sudo privileges"
    fi

    # Remove the script
    if ! sudo rm -f "/usr/local/bin/${INSTALL_NAME}"; then
        error "Failed to remove script from /usr/local/bin"
    fi
    
    # Remove logs
    delete_logs
    
    echo -e "${GREEN}Uninstallation completed successfully.${NC}"
}

show_status() {
    clear
    echo -e
    echo -e "${BLUE}===== GPU Status (${INSTALL_NAME} v${VERSION}) =====${NC}"
    echo -e
    show_gpu_info
}

show_version() {
    echo -e "${BLUE}${INSTALL_NAME} v${VERSION}${NC}"
}

show_help() {
    echo -e
    echo -e "${BLUE}===== ${INSTALL_NAME} v${VERSION} Help =====${NC}"
    echo -e "Usage: ${INSTALL_NAME} [COMMAND]"
    echo -e
    echo "License:"
    echo "- Apache 2.0"
    echo -e
    echo "Repository:"
    echo "- https://github.com/mik-tf/ubundia"
    echo -e
    echo "Commands:"
    echo -e "${GREEN}  build${NC}           - Run full GPU setup"
    echo -e "${GREEN}  status${NC}          - Show GPU status"
    echo -e "${GREEN}  install${NC}         - Install script system-wide"
    echo -e "${GREEN}  uninstall${NC}       - Remove script from system"
    echo -e "${GREEN}  logs${NC}            - Show full logs"
    echo -e "${GREEN}  recent-logs [n]${NC} - Show last n lines of logs (default: 50)"
    echo -e "${GREEN}  delete-logs${NC}     - Delete all logs"
    echo -e "${GREEN}  help${NC}            - Show this help message"
    echo -e "${GREEN}  version${NC}         - Show version information"
    echo
    echo "Examples:"
    echo "  ${INSTALL_NAME} build            # Run full GPU setup"
    echo "  ${INSTALL_NAME} status           # Show GPU status"
    echo "  ${INSTALL_NAME} logs             # Show all logs"
    echo "  ${INSTALL_NAME} recent-logs 100  # Show last 100 log lines"
    echo "  ${INSTALL_NAME} delete-logs      # Delete all logs"
    echo
    echo "Requirements:"
    echo "- Ubuntu system (20.04 or newer recommended)"
    echo "- AMD GPU with ROCm support (Polaris/Vega/Navi or newer)"
    echo "- Sudo privileges"
    echo -e
}

# Update main() and other NVIDIA references to AMD
main() {
    clear
    echo -e "${BLUE}===== AMD GPU Setup Script v${VERSION} =====${NC}"
    
    install_prerequisites_and_dependencies
    setup_logging
    setup_gpu
    show_gpu_info
    
    echo -e "\n${GREEN}Setup complete!${NC}"
    if ! lsmod | grep -q amdgpu; then
        echo -e "${YELLOW}Please restart your system to complete the driver installation.${NC}"
    fi
}

# Command handling
handle_command() {
    case "$1" in
        "status")
            show_status
            ;;
        "install")
            install
            ;;
        "uninstall")
            uninstall
            ;;
        "logs")
            show_logs
            ;;
        "recent-logs")
            show_recent_logs "${2:-50}"
            ;;
        "delete-logs")
            delete_logs
            ;;
        "help"|"")
            show_help
            ;;
        "version")
            show_version
            ;;
        "build")
            main
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap 'echo -e "\n${RED}Script interrupted${NC}"; exit 1' SIGINT SIGTERM
    handle_command "$1" "$2"
fi