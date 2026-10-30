# Makefile - Bunker OS v2.6.0

# Desarrollador jefe: <tu_usuario>
# Ingeniero colaborador: Apodex 1.1 Mini
# Version: 2.6.0

.PHONY: all help init install test clean build kernel drivers package test-study study

SHELL := /bin/bash
BUNKER_ROOT ?= /usr/lib/bunker
PREFIX ?= /usr

# =============================================================================
# Objetivos principales
# =============================================================================

all: help

help:
	@echo "Bunker OS v2.6.0 - Makefile"
	@echo ""
	@echo "Objetivos:"
	@echo "  init             - Inicializar el sistema (crear directorios)"
	@echo "  install          - Instalar todos los componentes"
	@echo "  test             - Ejecutar suite de pruebas"
	@echo "  test-study       - Ejecutar pruebas de Bunker Study"
	@echo "  build            - Compilar extensiones del kernel y drivers"
	@echo "  kernel           - Compilar extensiones del kernel"
	@echo "  drivers          - Compilar drivers"
	@echo "  study            - Instalar modulo Bunker Study"
	@echo "  clean            - Limpiar archivos compilados"
	@echo "  package          - Empaquetar para Arch (makepkg)"

# =============================================================================
# Inicializacion
# =============================================================================

init:
	@echo "Inicializando Bunker OS v2.6.0..."
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
	mkdir -p $(BUNKER_ROOT)/study/lib
	mkdir -p $(BUNKER_ROOT)/study/tools
	mkdir -p $(BUNKER_ROOT)/study/ui
	mkdir -p $(BUNKER_ROOT)/study/tests
	mkdir -p /etc/bunker
	mkdir -p /var/lib/bunker/state
	mkdir -p /var/lib/bunker/snapshots
	mkdir -p /var/lib/bunker/incidents
	mkdir -p /var/lib/bunker/hypotheses
	mkdir -p /var/lib/bunker/baseline
	mkdir -p /var/lib/bunker/study
	mkdir -p /var/log/bunker
	mkdir -p /run/bunker
	@echo "Inicializacion completada"

# =============================================================================
# Instalacion
# =============================================================================

install: init
	@echo "Instalando Bunker OS v2.6.0..."
	install -Dm755 cli/bunker $(DESTDIR)$(PREFIX)/bin/bunker
	install -Dm755 core/core.sh $(DESTDIR)$(BUNKER_ROOT)/core/core.sh
	install -Dm755 core/config.sh $(DESTDIR)$(BUNKER_ROOT)/core/config.sh
	install -Dm755 core/api.sh $(DESTDIR)$(BUNKER_ROOT)/core/api.sh
	install -Dm755 engine/engine.sh $(DESTDIR)$(BUNKER_ROOT)/engine/engine.sh
	install -Dm755 engine/mode-selector.sh $(DESTDIR)$(BUNKER_ROOT)/engine/mode-selector.sh
	install -Dm755 engine/engine-flags.sh $(DESTDIR)$(BUNKER_ROOT)/engine/engine-flags.sh
	install -Dm755 hardware/hal.sh $(DESTDIR)$(BUNKER_ROOT)/hardware/hal.sh
	install -Dm755 shared/lib.sh $(DESTDIR)$(BUNKER_ROOT)/shared/lib.sh
	install -Dm755 shared/command-registry.sh $(DESTDIR)$(BUNKER_ROOT)/shared/command-registry.sh
	install -Dm755 guardian/guardian.sh $(DESTDIR)$(BUNKER_ROOT)/guardian/guardian.sh
	install -Dm755 guardian/watchdogs/*.sh $(DESTDIR)$(BUNKER_ROOT)/guardian/watchdogs/
	install -Dm755 guardian/daemons/*.sh $(DESTDIR)$(BUNKER_ROOT)/guardian/daemons/
	install -Dm755 rollback/rollback.sh $(DESTDIR)$(BUNKER_ROOT)/rollback/rollback.sh
	install -Dm755 test/test-runner.sh $(DESTDIR)$(BUNKER_ROOT)/test/test-runner.sh
	install -Dm755 test/integration-test.sh $(DESTDIR)$(BUNKER_ROOT)/test/integration-test.sh
	install -Dm755 test/regression-test.sh $(DESTDIR)$(BUNKER_ROOT)/test/regression-test.sh
	install -Dm755 sentinel/sentinel.sh $(DESTDIR)$(BUNKER_ROOT)/sentinel/sentinel.sh
	install -Dm755 sentinel/modules/*.sh $(DESTDIR)$(BUNKER_ROOT)/sentinel/modules/
	install -Dm755 services/*.sh $(DESTDIR)$(BUNKER_ROOT)/services/
	install -Dm755 study/study.sh $(DESTDIR)$(BUNKER_ROOT)/study/study.sh
	install -Dm755 study/lib/*.sh $(DESTDIR)$(BUNKER_ROOT)/study/lib/
	install -Dm755 study/tools/*.sh $(DESTDIR)$(BUNKER_ROOT)/study/tools/
	install -Dm755 study/ui/*.sh $(DESTDIR)$(BUNKER_ROOT)/study/ui/
	install -Dm755 study/tests/*.sh $(DESTDIR)$(BUNKER_ROOT)/study/tests/
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
	@echo "Instalacion completada"

# =============================================================================
# Instalacion de Bunker Study
# =============================================================================

study:
	@echo "Instalando modulo Bunker Study..."
	mkdir -p $(DESTDIR)$(BUNKER_ROOT)/study/lib
	mkdir -p $(DESTDIR)$(BUNKER_ROOT)/study/tools
	mkdir -p $(DESTDIR)$(BUNKER_ROOT)/study/ui
	mkdir -p $(DESTDIR)$(BUNKER_ROOT)/study/tests
	install -Dm755 study/study.sh $(DESTDIR)$(BUNKER_ROOT)/study/study.sh
	install -Dm755 study/lib/*.sh $(DESTDIR)$(BUNKER_ROOT)/study/lib/
	install -Dm755 study/tools/*.sh $(DESTDIR)$(BUNKER_ROOT)/study/tools/
	install -Dm755 study/ui/*.sh $(DESTDIR)$(BUNKER_ROOT)/study/ui/
	install -Dm755 study/tests/*.sh $(DESTDIR)$(BUNKER_ROOT)/study/tests/
	@echo "Bunker Study instalado"

# =============================================================================
# Pruebas
# =============================================================================

test:
	@echo "Ejecutando suite de pruebas..."
	./test/test-runner.sh

integration-test:
	@echo "Ejecutando pruebas de integracion..."
	./test/integration-test.sh

regression-test:
	@echo "Ejecutando pruebas de regresion..."
	./test/regression-test.sh

test-study:
	@echo "Ejecutando pruebas de Bunker Study..."
	./study/tests/test-study.sh run

# =============================================================================
# Compilacion
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
