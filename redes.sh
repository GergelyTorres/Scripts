#!/bin/bash

# Mostrar las interfaces disponibles y el estado que se encuentran (up/down)
echo "Interfaces de red disponibles:"
ip -brief link show

# Pedir al usuario que escoga la interfaz que desea
echo -n "Ingresa el nombre de la interfaz que quieres modificar: "
read interfaz

# Pedir estado que desa aplicar a la interfaz
echo "¿Qué desea hacer? prender (up) o apagar (down) "
read estado

# Cambiar el estado de la interfaz
sudo ip link set $interfaz $estado

# Mostrar el estado actualizado
echo "Se realizo el cambio deseado: "
ip -brief link show $interfaz

if [ "$estado" = "down" ]; then
	exit 1
fi

# Preguntar que tipo de conexion desea usar
echo "Tipo de conexión deseada: "
echo "1) Cableada"
echo "2) Inalámbrica"
read -p "selecciona una opcion (1 0 2): " tipo_conexion

if [ "$tipo_conexion" -eq 1 ]; then 
	echo "Selecciono conexion cableada"
elif [ "$tipo_conexion" -eq 2 ]; then 
	echo "Selecciono conexion inalambrica"
else
	echo "Opcion no valida"
	exit 1
fi

# Preguntar tipo de configuracion deseada
echo "Escoge el tipo de configuración que deseas: "
echo "1) Dinámica"
echo "2) Estática"
read -p "Selecciona una opcion (1 o 2): " tipo_ip

# Respaldar el archivo
sudo cp /etc/network/interfaces /etc/network/interfaces.bank

# Establecer la ip
if [ "$tipo_ip" = "1" ]; then
	echo "Configuracion dinamica..."
	sudo tee /etc/network/interfaces > /dev/null <<EOF
	auto $interfaz
	iface $interfaz inet dhcp
EOF
elif [ "$tipo_ip" =  "2" ]; then
	read -p "Introduce la IP: " ip
	read -p "Introduce la mascara de red: " mascara
	read -p "Introduce la puerta de enlace: " gateway
	read -p "Introduce los DNS (Separados por espacio): " dns

	echo "Configuradno IP estatica..."
	sudo tee /etc/network/interfaces > /dev/null <<EOF
auto $interfaz
iface $interfaz inet static
	address $ip
	netmask $mascara
	gateway $gateway
	dns-nameservers $dns
EOF
else
	echo "Opcion no valida"
	exit 1
fi

#Reiniciar red
echo "Aplicando la configuracion"
sudo systemctl restart networking
echo "Listo"

# Mostrar redes si es inalambrica
if [[ $tipo_conexion -eq 2 ]]; then
	echo "Redes inalambricas disponibles..."
	sudo iwlist $interfaz scan | grep -E "ESSID|Encryption key|Quality"

	read -p "Introduce el nombre de la red: " essid

# Verificar si tiene contraseña
	info_red=$(sudo iwlist $interfaz scanning | awk -v essid="$essid" '
												/Cell/ { red=0 }
												/ESSID/ {
													gsub(/"/, "", $0)
													if ($0 ~ essid) red=1
												}
												red && /Encryption key/ {
													print $0
												}
											')

	if [[ "$info_red" == *"on"* ]]; then
		verificar_contrasena="on"
	else
		vereficar_contrasena="off"
	fi
	
	echo "Valor de la verificacion: '$verificar_contrasena'"

	if [ "$verificar_contrasena" = "on" ]; then
		read -sp "Introduce la contraseña: " contrasena
		echo
	cat <<EOF | sudo tee /etc/wpa_supplicant.conf >/dev/null
network={
	ssid="$essid"
	psk="$contrasena"
}
EOF

	else
	cat <<EOF | sudo tee /etc/wpa_supplicant.conf > /dev/null
network={
	ssid="$essid"
	key_mgmt=NONE
}
EOF	
	fi
	sudo wpa_supplicant -B -i $interfaz -c /etc/wpa_supplicant.conf
	sudo dhclient $interfaz
	echo "Conectado a la red $essid"

	# Verificar si hay portal cautivo
	echo "Verificando si exite un portal cautivo: "
	response=$(curl -s -I http://neverssl.com/ | grep -i "HTTP/1.1")

	if echo "$response" | grep -qE "30[123]"; then
		echo "Abriendo portal cautivo"
		lynx http://neverssl.com/
	else
		echo "No se detecto un portal cautivo"
	fi
fi
