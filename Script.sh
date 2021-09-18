#!/bin/bash

clear

if ping -q -c 3 google.com >/dev/null 2>&1; then
	echo "Conexión a internet detectada."
else
	echo "Error, no se ha podido conectar a internet."
	exit 1
fi

pacman -Sy dialog --noconfirm


#echo "Este Script aun esta en desarrollo y asume lo siguiente:"
#echo "-Se dispone de conexion a internet"
#echo "-Esta máquina ya tiene creadas y preformateadas las particiones que se usaran durante la instalacion."
#echo "Lo hare lo mejor que pueda pero si algo falla que no venga nadie a llorarme."
#echo "Si todo esta preparado pulsa Intro para continuar, en caso contrario pulsa q para abortar la instalacion."
#read -n 1 -r -s conform
#Aceptacion
if dialog --title "Arch Jecht Installer" --yesno "Este Script aun esta en desarrollo y asume lo siguiente:\n -Se dispone de conexion a internet.\n -Esta máquina ya tiene creadas y preformateadas las particiones / y swap.\n\nLo hare lo mejor que pueda pero si algo falla que no venga nadie a llorarme." 0 0
;then
	clear
else
	exit 1
fi

#Asignacion de teclado a español
if loadkeys es;then
	echo "Teclado configurado a Español."
else
	echo "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido configurar el teclado, tendras que hacerlo manualmente depues."
fi


#Establecer zona horaria
if timedatectl set-timezone Europe/Madrid;then
	timedatectl set-ntp true
	echo "Zona horaria establecida en Madrid."
else
	echo "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido establecer la zona horaria, tendras que hacerlo manualmente depues."
fi


#Mostrar particiones disponibles
if fdisk -l;then
	echo "Estas son las particiones disponibles, elige donde se instalara el sistema (ejemplo: sda1)."
else
	echo "\e[5m\e[31m\e[1mERROR:\e[0m No se pueden mostrar las particiones, soluciona el problema y vuelve a empezar"
	exit 1
fi
read -r system_partition

#Montaje e instalacion
if mount /dev/$system_partition /mnt;then
	echo "Particion montada correctamente, comenzando instalación..."
else
	echo "Error montando particion."
	exit 1
fi
if pacstrap /mnt base linux-lts linux-firmware;then
	echo "Se ha instalado el sistema base Linux correctamente."
else
	echo "\e[5m\e[31m\e[1mERROR:\e[0m Error durante la instalacion, soluciona el problema y vuelve a empezar"
	exit 1
fi


#Generar tabla de particiones
if genfstab -U /mnt >> /mnt/etc/fstab;then
	echo "fstab generado..."
else
	echo "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido generar la tabla de particiones, soluciona el problema y vuelve a empezar"
	exit 1
fi

#Entrar como root al sistema instalado
if arch-chroot /mnt;then
	echo "Accediendo al sistema instalado como root."
else
	echo "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido acceer al sistema instalado, soluciona el problema y vuelve a empezar"
	exit 1
fi

#Establecer zona horaria para la instalacion, creo que no funciona porque luego no se refleja
if ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime;then
	hwclock --systohc
	echo "Establecida zona horaria del sistema a Madrid."
else
	echo "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido establcer la zona horaria del sistema, soluciona el problema y vuelve a empezar"
	exit 1
fi
