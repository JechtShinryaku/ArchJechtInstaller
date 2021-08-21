#!/bin/bash

clear

if ping -q -c 3 google.com >/dev/null 2>&1; then
	echo "Conexión a internet detectada."
else
	echo "Error, no se ha podido conectar a internet."
	exit 1
fi

echo "Este Script aun esta en desarrollo y asume lo siguiente:"
echo "-Se dispone de conexion a internet"
echo "-Esta máquina ya tiene creadas y preformateadas las particiones que se usaran durante la instalacion."
echo "Lo hare lo mejor que pueda pero si algo falla que no venga nadie a llorarme."
echo "Si todo esta preparado pulsa Intro para continuar, en caso contrario pulsa q para abortar la instalacion."
read -n 1 -r -s conform


if loadkeys es;then
	echo "Taclado configurado a Español."
else
	echo "\e[5m\e[31m\e[1mERROR:\e[0m No se ha podido configurar el teclado, tendras que hacerlo manualmente depues."
	exit 1
fi
