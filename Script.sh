#!/bin/bash

clear

if ping -q -c 3 google.com >/dev/null 2>&1; then
	echo -e "\e[1m\e[32mConexión a internet detectada.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mError, no se ha podido conectar a internet.\e[0m"
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
if dialog --title "Arch Jecht Installer" --yesno "Este Script aun esta en desarrollo y asume lo siguiente:\n -Se dispone de conexion a internet.\n -Esta máquina ya tiene creadas (al menos)y preformateadas las particiones / y swap.\n\nLo hare lo mejor que pueda pero si algo falla que no venga nadie a llorarme." 0 0;then
	clear
else
	exit 1
fi

#Asignacion de teclado a español
if loadkeys es;then
	echo -e "\e[1m\e[32mTeclado configurado a Español.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido configurar el teclado, tendras que hacerlo manualmente depues."
fi


#Establecer zona horaria
if timedatectl set-timezone Europe/Madrid;then
	timedatectl set-ntp true
	echo -e "\e[1m\e[32mZona horaria establecida en Madrid.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido establecer la zona horaria, tendras que hacerlo manualmente depues."
fi

clear

#Mostrar particiones disponibles
if lsblk -n --output TYPE,KNAME,SIZE,FSTYPE,LABEL | awk '$1=="part"';then
	echo ""
	echo ""
	echo "Estas son las particiones disponibles, escribe donde se instalara el sistema (ejemplo: sda1)."
	echo "ATENCIÓN: LA PARTICIÓN ELEGIDA DEBE ESTAR VACIA Y EN CASO DE QUE NO LO ESTE TODO LO QUE CONTENGA SERA ELIMINADO."
	echo "ESTE ES EL PASO MÁS IMPORTANTE, ELIGE CON EXTREMO CUIDADO Y ASEGURATE DE ESCRIBIRLO CORRECTAMENTE."
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se pueden mostrar las particiones, soluciona el problema y vuelve a empezar"
	exit 1
fi
read -r system_partition

clear

if lsblk -n --output TYPE,KNAME,SIZE,FSTYPE,LABEL | awk '$1=="part"';then
	echo ""
	echo ""
	echo "Estas son las particiones disponibles, escribe cual quieres que sea usada como swap (ejemplo: sda2)."
	echo "Si no deseas usar swap simplemente dejalo en blanco y pulsa Intro."
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se pueden mostrar las particiones, soluciona el problema y vuelve a empezar"
	exit 1
fi
read -r swap_partition

#Formateo, Montaje e instalacion
if [ -z "$swap_partition" ]
then
	echo -e "\e[1m\e[32mSwap deshabilitado.\e[0m"
elif mkswap /dev/$swap_partition;then
	swapon /dev/$swap_partition
	echo -e "\e[1m\e[32mSwap creado y habilidato.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se puede crear o montar la partición $swap_partition para swap, se continuara sin ella."
fi

if mkfs.ext4 /dev/$system_partition;then
	echo -e "\e[1m\e[32mParticion $system_partition formateada correctamente a EXT4.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido formatear la partición $system_partition para el sistema, soluciona el problema y vuelve a empezar."
	exit 1
fi
if mount /dev/$system_partition /mnt;then
	echo -e "\e[1m\e[32mParticion montada correctamente, comenzando instalación...\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido montar la partición $system_partition para el sistema, soluciona el problema y vuelve a empezar."
	exit 1
fi
if pacstrap /mnt base linux-lts linux-firmware;then
	echo -e "\e[1m\e[32mSe ha instalado el sistema base Linux correctamente.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m Error durante la instalacion, soluciona el problema y vuelve a empezar"
	exit 1
fi


#Generar tabla de particiones
if genfstab -U /mnt >> /mnt/etc/fstab;then
	echo -e "\e[1m\e[32mfstab generado...\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido generar la tabla de particiones, soluciona el problema y vuelve a empezar"
	exit 1
fi

#Entrar como root al sistema instalado
#if arch-chroot /mnt;then
#	echo "Accediendo al sistema instalado como root."
#else
#	echo "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido acceer al sistema instalado, soluciona el problema y vuelve a empezar"
#	exit 1
#fi

#Establecer zona horaria para la instalacion, creo que no funciona porque luego no se refleja
if arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime;then
	arch-chroot /mnt hwclock --systohc
	echo -e "\e[1m\e[32mEstablecida zona horaria del sistema a Madrid.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido establcer la zona horaria del sistema, soluciona el problema y vuelve a empezar"
	exit 1
fi

#Generar locales
if arch-chroot /mnt sed -i "s/# es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/" /etc/locale.gen;then
	arch-chroot /mnt locale-gen
	echo -e "\e[1m\e[32mLocales generados.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se han podido generar los locales, se continuara sin ellos."
fi

#Establecer layout para consola
if arch-chroot /mnt echo "KEYMAP=es" > locale;then
	echo -e "\e[1m\e[32mLayout para consola establecido.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido establecer el layout para consola, se continuara sin ellos."
fi


#Establecer nombre del dispositivo
if nombre=`dialog --stdout --inputbox "Escribe el hostname." 0 0`;then
	arch-chroot /mnt echo $nombre > /etc/hostname;
	arch-chroot /mnt echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$nombre.localdomain $nombre" > locale;
	echo -e "\e[1m\e[32mHostname establecido.\e[0m"
else
	nombre='Dispositivo'
	arch-chroot /mnt echo $nombre > /etc/hostname;
	arch-chroot /mnt echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$nombre.localdomain $nombre" > locale;
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m Error estableciendo Hostname, se nombrara Dispositivo."
fi


arch-chroot /mnt pacman -Sy nano sudo git grub os-prober mtools efibootmgr dosfstools networkmanager openssh dhcpcd --noconfirm

#Establecer contraseña de root
if echo "Escribe la contraseña para root";then
	arch-chroot /mnt passwd
	echo -e "\e[1m\e[32mContraseña establecida.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se ha establcer la nueva contraseña prar root, omitiendo."
fi

#Creacion de usuario principal
if echo "escribe tu nombre de usuario";then
	read user
	arch-chroot /mnt useradd -m $user
	echo "Escribe la contraseña para $user"
	arch-chroot /mnt passwd $user
	echo -e "\e[1m\e[32m$user creado.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido crear a $user, omitiendo."
fi

#Añadir a grupos
if arch-chroot /mnt usermod -aG wheel,video,audio,storage $user;then
	echo -e "\e[1m\e[32m$user añadido a grupos principales.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido añadir a $user a los grupos principales, omitiendo."
fi

#Habilitar sudo
if arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers;then
	echo -e "\e[1m\e[32msudo habiitado.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se podido habilitar sudo, omitiendo."
fi


#Instalar grub para BIOS
if echo "escribe la unidad donde se instalara GRUB (ejemplo: sda)";then
	read grubdisk
	arch-chroot /mnt grub-install --target=i386-pc /dev/$grubdisk
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
	echo -e "\e[1m\e[32mgrub instalado.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se podido instalar grub en $grubdisk, el sistema no podra arrancar."
fi


#Habilitar red
if arch-chroot /mnt systemctl enable NetworkManager;then
	echo -e "\e[1m\e[32mServicio de red habilitado.\e[0m"
else
	echo -e "\e[5m\e[31m\e[1mERROR:\e[0m No se podido habilitar la red, no habra conexión hasta que se haga manualmente."
fi

#Instalacion de escritorio

#instalacion de aplicaciones

#logout
umount /mnt
clear
echo -e "\e[1m\e[32mSistema instalado.\e[0m"
#poweroff
