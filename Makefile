# =============================================================================
# CYBERGHOST OSINT ULTIMATE - Makefile
# =============================================================================

.PHONY: help install uninstall update clean test build docker run dev \
		backup restore docs lint format security release

# Configurações
SHELL := /bin/bash
VERSION := 7.0.0
PROJECT_NAME := cyberghost-osint
INSTALL_DIR := $(HOME)/$(PROJECT_NAME)
BIN_DIR := /usr/local/bin
DOCKER_IMAGE := cyberghost/$(PROJECT_NAME):$(VERSION)
DOCKER_LATEST := cyberghost/$(PROJECT_NAME):latest

# Cores
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# Help
help:
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║     CYBERGHOST OSINT ULTIMATE - Makefile Commands          ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Installation:$(NC)"
	@echo "  make install     - Install CYBERGHOST OSINT"
	@echo "  make uninstall   - Uninstall CYBERGHOST OSINT"
	@echo "  make update      - Update CYBERGHOST OSINT"
	@echo ""
	@echo "$(GREEN)Development:$(NC)"
	@echo "  make dev         - Setup development environment"
	@echo "  make test        - Run tests"
	@echo "  make lint        - Run linters"
	@echo "  make format      - Format code"
	@echo "  make security    - Run security checks"
	@echo ""
	@echo "$(GREEN)Build:$(NC)"
	@echo "  make build       - Build project"
	@echo "  make clean       - Clean build artifacts"
	@echo ""
	@echo "$(GREEN)Docker:$(NC)"
	@echo "  make docker      - Build Docker image"
	@echo "  make docker-run  - Run Docker container"
	@echo "  make docker-push - Push Docker image"
	@echo ""
	@echo "$(GREEN)Operations:$(NC)"
	@echo "  make backup      - Create backup"
	@echo "  make restore     - Restore from backup"
	@echo "  make logs        - View logs"
	@echo ""
	@echo "$(GREEN)Documentation:$(NC)"
	@echo "  make docs        - Generate documentation"
	@echo "  make readme      - Generate README"
	@echo ""
	@echo "$(GREEN)Release:$(NC)"
	@echo "  make release     - Create release"
	@echo "  make version     - Show version"

# Install
install:
	@echo "$(YELLOW)[*] Installing CYBERGHOST OSINT...$(NC)"
	@./scripts/install.sh
	@echo "$(GREEN)[+] Installation complete$(NC)"

# Uninstall
uninstall:
	@echo "$(YELLOW)[*] Uninstalling CYBERGHOST OSINT...$(NC)"
	@./scripts/uninstall.sh
	@echo "$(GREEN)[+] Uninstall complete$(NC)"

# Update
update:
	@echo "$(YELLOW)[*] Updating CYBERGHOST OSINT...$(NC)"
	@git pull origin main
	@./scripts/update.sh
	@echo "$(GREEN)[+] Update complete$(NC)"

# Development setup
dev:
	@echo "$(YELLOW)[*] Setting up development environment...$(NC)"
	@python3 -m venv venv
	@source venv/bin/activate && pip install -r requirements-dev.txt
	@pre-commit install
	@echo "$(GREEN)[+] Development environment ready$(NC)"

# Tests
test:
	@echo "$(YELLOW)[*] Running tests...$(NC)"
	@source venv/bin/activate && pytest tests/ -v --cov=src --cov-report=html
	@echo "$(GREEN)[+] Tests completed$(NC)"

# Lint
lint:
	@echo "$(YELLOW)[*] Running linters...$(NC)"
	@shellcheck src/**/*.sh scripts/*.sh
	@source venv/bin/activate && flake8 src/ tests/
	@source venv/bin/activate && pylint src/
	@echo "$(GREEN)[+] Linting completed$(NC)"

# Format code
format:
	@echo "$(YELLOW)[*] Formatting code...$(NC)"
	@shfmt -w -i 4 src/ scripts/
	@source venv/bin/activate && black src/ tests/
	@source venv/bin/activate && isort src/ tests/
	@echo "$(GREEN)[+] Formatting completed$(NC)"

# Security checks
security:
	@echo "$(YELLOW)[*] Running security checks...$(NC)"
	@source venv/bin/activate && bandit -r src/
	@source venv/bin/activate && safety check
	@echo "$(GREEN)[+] Security checks completed$(NC)"

# Build
build:
	@echo "$(YELLOW)[*] Building project...$(NC)"
	@mkdir -p dist
	@tar -czf dist/$(PROJECT_NAME)-$(VERSION).tar.gz --exclude=.git --exclude=venv --exclude=__pycache__ --exclude=*.pyc .
	@echo "$(GREEN)[+] Build complete: dist/$(PROJECT_NAME)-$(VERSION).tar.gz$(NC)"

# Clean
clean:
	@echo "$(YELLOW)[*] Cleaning...$(NC)"
	@rm -rf dist/ build/ *.egg-info/ .pytest_cache/ .coverage htmlcov/
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete
	@echo "$(GREEN)[+] Clean completed$(NC)"

# Docker build
docker:
	@echo "$(YELLOW)[*] Building Docker image...$(NC)"
	@docker build -t $(DOCKER_IMAGE) -t $(DOCKER_LATEST) -f docker/Dockerfile .
	@echo "$(GREEN)[+] Docker image built: $(DOCKER_IMAGE)$(NC)"

# Docker run
docker-run:
	@echo "$(YELLOW)[*] Running Docker container...$(NC)"
	@docker-compose -f docker/docker-compose.yml up -d
	@echo "$(GREEN)[+] Docker containers running$(NC)"

# Docker push
docker-push:
	@echo "$(YELLOW)[*] Pushing Docker image...$(NC)"
	@docker push $(DOCKER_IMAGE)
	@docker push $(DOCKER_LATEST)
	@echo "$(GREEN)[+] Docker image pushed$(NC)"

# Backup
backup:
	@echo "$(YELLOW)[*] Creating backup...$(NC)"
	@./scripts/backup.sh
	@echo "$(GREEN)[+] Backup created$(NC)"

# Restore
restore:
	@echo "$(YELLOW)[*] Restoring from backup...$(NC)"
	@./scripts/restore.sh
	@echo "$(GREEN)[+] Restore completed$(NC)"

# Logs
logs:
	@echo "$(YELLOW)[*] Viewing logs...$(NC)"
	@tail -f logs/*.log

# Generate documentation
docs:
	@echo "$(YELLOW)[*] Generating documentation...$(NC)"
	@source venv/bin/activate && sphinx-build docs/source docs/build
	@echo "$(GREEN)[+] Documentation generated: docs/build$(NC)"

# Generate README
readme:
	@echo "$(YELLOW)[*] Generating README...$(NC)"
	@./scripts/generate_readme.py
	@echo "$(GREEN)[+] README generated$(NC)"

# Create release
release:
	@echo "$(YELLOW)[*] Creating release v$(VERSION)...$(NC)"
	@git tag -a v$(VERSION) -m "Release v$(VERSION)"
	@git push origin v$(VERSION)
	@echo "$(GREEN)[+] Release created$(NC)"

# Version
version:
	@echo "$(PROJECT_NAME) v$(VERSION)"

# Default target
.DEFAULT_GOAL := help