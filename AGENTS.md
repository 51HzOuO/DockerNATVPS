# Build/Lint/Test Commands
- **Syntax check**: `bash -n Debian/*.sh` - Check shell script syntax
- **Lint**: `shellcheck Debian/*.sh` - Lint shell scripts for common issues
- **Docker build test**: `cd Debian && docker build -t test-image -f Dockerfile .` - Test Dockerfile builds
- **Run single test**: `cd Debian && bash -x Create.sh 2222 2223 2233 50 256` - Test Create.sh with sample parameters

# Code Style Guidelines
- **Shell scripts**: Use `#!/bin/bash` shebang, follow POSIX shell conventions
- **Functions**: Define message functions for localization, use descriptive names
- **Input validation**: Always validate numeric inputs with regex `^[0-9]+$`
- **Error handling**: Use `exit 1` on failures, check command exit codes with `$?`
- **Naming**: Use snake_case for variables, UPPER_CASE for constants
- **Comments**: Add Chinese comments for complex logic, keep them concise
- **Docker**: Use latest Debian base image, expose only necessary ports (22 for SSH)
- **Security**: Generate random passwords, avoid hardcoded credentials
- **Formatting**: 2-space indentation, consistent spacing around operators</content>
<parameter name="filePath">/Users/51hz/CodeProjects/temp/AGENTS.md