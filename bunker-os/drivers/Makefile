# =============================================================================
# Makefile - Bunker OS Drivers
# Desarrollador jefe: <tu_usuario> | Ingeniero colaborador: Apodex 1.1 Mini
# =============================================================================

obj-m += bpm/

all:
	@echo "Compilando drivers Bunker OS..."
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
	@echo "Compilación completada"

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
	@echo "Limpieza completada"

install:
	@echo "Instalando drivers..."
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules_install
	depmod -a
	@echo "Instalación completada"

help:
	@echo "Objetivos:"
	@echo "  all     - Compilar drivers"
	@echo "  clean   - Limpiar archivos compilados"
	@echo "  install - Instalar drivers"
	@echo "  help    - Mostrar esta ayuda"

.PHONY: all clean install help
