# Makefile - Bunker OS

# Desarrollador jefe: <tu_usuario>
# Ingeniero colaborador: Apodex 1.1 Mini

.PHONY: all help init install test clean build kernel drivers package

SHELL := /bin/bash
BUNKER_ROOT ?= /usr/lib/bunker
PREFIX ?= /usr

# =============================================================================
# Objetivos principales
# =============================================================================

all: help

help:
	@echo "Bunker OS - Makefile"
	@echo ""
	@echo "Objetivos:"
	@echo "  init       - Inicializar el sistema (crear directorios)"
	@echo "  install    - Instalar todos los componentes"
	@echo "  test       - Ejecutar suite de pruebas"
	@echo "  build      - Compilar extensiones del kernel y drivers"
	@echo "  kernel     - Compilar extensiones del kernel"
	@echo "  drivers    - Compilar drivers"
	@echo "  clean      - Limpiar archivos compilados"
	@echo "  package    - Empaquetar para Arch (makepkg)"

# =============================================================================
# Inicialización
# =============================================================================

init:
	@echo "Inicializando Bunker OS..."
	mkdir -p $(BUNKER_ROOT)/core
	mkdir -p $(BUNKER_ROOT)/engine
	mkdir -p $(BUNKER_ROOT)/hardware
	mkdir -p $(BUNKER_ROOT)/shared
	mkdir -p $(BUNKER_ROOT)/guardian/watchdogs
	mkdir -p $(BUNKER_ROOT)/guardian/daemons
	mkdir -p $(BUNKER_ROOT)/services
	mkdir -p $(BUNKER_ROOT)/sentinel/modules
	mkdir -p $(BUNKER_ROOT)/rollback
	mkdir -p $(BUNKER_ROOT)/test
	mkdir -p /etc/bunker
	mkdir -p /var/lib/bunker/state
	mkdir -p /var/lib/bunker/snapshots
	mkdir -p /var/lib/bunker/incidents
	mkdir -p /var/lib/bunker/hypotheses
	mkdir -p /var/lib/bunker/baseline
	mkdir -p /var/log/bunker
	mkdir -p /run/bunker
	@echo "Inicialización completada"

# =============================================================================
# Instalación
# =============================================================================

install: init
	@echo "Instalando Bunker OS..."
	install -Dm755 cli/bunker $(DESTDIR)$(PREFIX)/bin/bunker
	install -Dm755 core/core.sh $(DESTDIR)$(BUNKER_ROOT)/core/core.sh
	install -Dm755 core/config.sh $(DESTDIR)$(BUNKER_ROOT)/core/config.sh
	install -Dm755 core/api.sh $(DESTDIR)$(BUNKER_ROOT)/core/api.sh
	install -Dm755 engine/engine.sh $(DESTDIR)$(BUNKER_ROOT)/engine/engine.sh
	install -Dm755 engine/mode-selector.sh $(DESTDIR)$(BUNKER_ROOT)/engine/mode-selector.sh
	install -Dm755 engine/engine-flags.sh $(DESTDIR)$(BUNKER_ROOT)/engine/engine-flags.sh
	install -Dm755 hardware/hal.sh $(DESTDIR)$(BUNKER_ROOT)/hardware/hal.sh
	install -Dm755 shared/lib.sh $(DESTDIR)$(BUNKER_ROOT)/shared/lib.sh
	install -Dm755 guardian/guardian.sh $(DESTDIR)$(BUNKER_ROOT)/guardian/guardian.sh
	install -Dm755 guardian/watchdogs/*.sh $(DESTDIR)$(BUNKER_ROOT)/guardian/watchdogs/
	install -Dm755 guardian/daemons/*.sh $(DESTDIR)$(BUNKER_ROOT)/guardian/daemons/
	install -Dm755 rollback/rollback.sh $(DESTDIR)$(BUNKER_ROOT)/rollback/rollback.sh
	install -Dm755 test/test-runner.sh $(DESTDIR)$(BUNKER_ROOT)/test/test-runner.sh
	install -Dm755 test/integration-test.sh $(DESTDIR)$(BUNKER_ROOT)/test/integration-test.sh
	install -Dm755 test/regression-test.sh $(DESTDIR)$(BUNKER_ROOT)/test/regression-test.sh
	install -Dm755 sentinel/sentinel.sh $(DESTDIR)$(BUNKER_ROOT)/sentinel/sentinel.sh
	install -Dm755 services/*.sh $(DESTDIR)$(BUNKER_ROOT)/services/
	install -Dm755 sentinel/modules/*.sh $(DESTDIR)$(BUNKER_ROOT)/sentinel/modules/
	install -Dm644 base/etc/bunker.conf $(DESTDIR)/etc/bunker/bunker.conf
	install -Dm644 base/systemd/bunker-core.service $(DESTDIR)$(PREFIX)/lib/systemd/system/bunker-core.service
	install -Dm644 base/systemd/bunker-guardian.service $(DESTDIR)$(PREFIX)/lib/systemd/system/bunker-guardian.service
	install -Dm644 base/systemd/bunker-sentinel.service $(DESTDIR)$(PREFIX)/lib/systemd/system/bunker-sentinel.service
	install -Dm644 base/systemd/bunker-maintenance.service $(DESTDIR)$(PREFIX)/lib/systemd/system/bunker-maintenance.service
	install -Dm644 base/systemd/bunker-update.service $(DESTDIR)$(PREFIX)/lib/systemd/system/bunker-update.service
	install -Dm644 base/systemd/bunker-health.service $(DESTDIR)$(PREFIX)/lib/systemd/system/bunker-health.service
	install -Dm644 base/systemd/bunker-recovery.service $(DESTDIR)$(PREFIX)/lib/systemd/system/bunker-recovery.service
	install -Dm644 base/systemd/bunker-harden.service $(DESTDIR)$(PREFIX)/lib/systemd/system/bunker-harden.service
	install -Dm644 base/systemd/bunker-ai.service $(DESTDIR)$(PREFIX)/lib/systemd/system/bunker-ai.service
	install -Dm755 base/pacman/bunker-post-install.hook $(DESTDIR)/usr/share/pacman/hooks/BunkerPostInstall.hook
	@echo "Instalación completada"

# =============================================================================
# Pruebas
# =============================================================================

test:
	@echo "Ejecutando suite de pruebas..."
	./test/test-runner.sh

integration-test:
	@echo "Ejecutando pruebas de integración..."
	./test/integration-test.sh

regression-test:
	@echo "Ejecutando pruebas de regresión..."
	./test/regression-test.sh

# =============================================================================
# Compilación
# =============================================================================

build: kernel drivers

kernel:
	@echo "Compilando extensiones del kernel..."
	@if [ -d kernel-extensions ]; then \
		cd kernel-extensions && make || echo "Error al compilar kernel-extensions"; \
	fi

drivers:
	@echo "Compilando drivers..."
	@if [ -d drivers ]; then \
		cd drivers && make || echo "Error al compilar drivers"; \
	fi

clean:
	@echo "Limpieza..."
	rm -rf kernel-extensions/build drivers/build
	@echo "Limpieza completada"

# =============================================================================
# Empaquetado
# =============================================================================

package:
	@echo "Empaquetando para Arch Linux..."
	@if command -v makepkg &>/dev/null; then \
		cd base && makepkg -si --noconfirm || echo "Error al empaquetar"; \
	else \
		echo "makepkg no encontrado. Instala pacman-contrib o base-devel."; \
	fi