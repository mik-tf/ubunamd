<h1> Ubunamd - Ubuntu AMD GPU Setup Tool</h1>

<h2> Table of Contents</h2>

- [Introduction](#introduction)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Manual Installation](#manual-installation)
  - [Using Make](#using-make)
- [Usage](#usage)
- [Commands](#commands)
- [Examples](#examples)
- [Logging](#logging)
- [License](#license)
- [Support](#support)

## Introduction

Ubunamd is a comprehensive GPU setup tool for Ubuntu systems with AMD graphics cards. It automates the installation and configuration of AMD drivers and ROCm toolkit, making GPU setup simple and reliable.

## Features

- Automated AMD driver installation
- ROCm toolkit setup
- System compatibility checks
- Detailed logging system
- GPU status monitoring
- Interactive installation process
- Command-line interface
- Secure execution model

## Requirements

- Ubuntu operating system (20.04 or newer recommended)
- AMD GPU with ROCm support (Polaris/Vega/Navi or newer)
- Sudo privileges
- Internet connection
- Basic system utilities

## Installation

### Manual Installation

```bash
# Download
wget https://raw.githubusercontent.com/mik-tf/ubunamd/main/ubunamd.sh

# Install
bash ubunamd.sh install

# Remove installer
rm ubunamd.sh
```

### Using Make

The project includes a Makefile for easier management. Available make commands:

```bash
# First clone the repository
git clone https://github.com/mik-tf/ubunamd.git
cd ubunamd

# Install the tool
make build

# Reinstall (uninstall then install)
make rebuild

# Remove the installation
make delete
```

The Makefile commands do the following:
- `make build`: Installs the script system-wide
- `make rebuild`: Removes existing installation and reinstalls
- `make delete`: Removes the installation completely

## Usage

Run the command with no arguments to see help:
```bash
ubunamd
```

## Commands

- `build` - Run full GPU setup
- `status` - Show GPU status
- `install` - Install script system-wide
- `uninstall` - Remove script from system
- `logs` - Show full logs
- `recent-logs [n]` - Show last n lines of logs
- `delete-logs` - Delete all logs
- `help` - Show help message
- `version` - Show version information

## Examples

```bash
# Run full setup
ubunamd build

# Check GPU status
ubunamd status

# View logs
ubunamd logs

# Show recent logs
ubunamd recent-logs 100
```

## Logging

Logs are stored in `/var/log/ubunamd/` with the following features:
- Installation logging
- Error tracking
- Status updates
- Timestamp information
- Log rotation
- Cleanup utilities

## License

Apache License 2.0

## Support

For issues and questions:
[GitHub Repository](https://github.com/mik-tf/ubunamd)