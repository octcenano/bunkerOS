# =============================================================================
# Makefile - Bunker OS Kernel Extensions
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

obj-m += bunker-core.o
bunker-core-objs += bunker-core.o bunker-mm.o

KVERSION := $(shell uname -r)
KDIR := /lib/modules/$(KVERSION)/build
PWD := $(shell pwd)

all:
	@echo "Compilando extensiones del kernel Bunker OS..."
	make -C $(KDIR) M=$(PWD) modules
	@echo "Compilación completada"

clean:
	make -C $(KDIR) M=$(PWD) clean
	@echo "Limpieza completada"

install:
	@echo "Instalando extensiones del kernel..."
	make -C $(KDIR) M=$(PWD) modules_install
	depmod -a
	@echo "Instalación completada"

test:
	@echo "Probando compilación..."
	make all

help:
	@echo "Objetivos:"
	@echo "  all     - Compilar extensiones del kernel"
	@echo "  clean   - Limpiar archivos compilados"
	@echo "  install - Instalar extensiones en el kernel"
	@echo "  test    - Probar compilación"
	@echo "  help    - Mostrar esta ayuda"

.PHONY: all clean install test help
