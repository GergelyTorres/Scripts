#!/bin/bash

MIN_LENGTH=8
REQUIRE_UPPERCASE=1
REQUIRE_DIGIT=1
REQUIRE_SPECIAL=1

crear_contrasena() {
    local contrasena="$1"
    
    if [[ ${#contrasena} -lt $MIN_LENGTH ]]; then
        echo "La contraseña debe tener al menos $MIN_LENGTH caracteres."
        return 1
    fi
    if [[ $REQUIRE_UPPERCASE -eq 1 && ! "$contrasena" =~ [A-Z] ]]; then
        echo "La contraseña debe contener al menos una letra mayúscula."
        return 1
    fi
    if [[ $REQUIRE_DIGIT -eq 1 && ! "$contrasena" =~ [0-9] ]]; then
        echo "La contraseña debe contener al menos un número."
        return 1
    fi
    if [[ $REQUIRE_SPECIAL -eq 1 && ! "$contrasena" =~ [^a-zA-Z0-9] ]]; then
        echo "La contraseña debe contener al menos un carácter especial."
        return 1
    fi
    return 0
}

# Solicitar nombre de usuario
echo -n "Ingrese el nombre de usuario: "
read usuario

# Verificar si el usuario ya existe
if id "$usuario" &>/dev/null; then
    echo "El usuario '$usuario' ya existe."
    exit 1
fi

# Solicitar contraseña
while true; do
    echo -n "Ingrese la contraseña: "
    read -s contrasena
    echo
    echo -n "Confirme la contraseña: "
    read -s confirmar_contrasena
    echo

    if [[ "$contrasena" != "$confirmar_contrasena" ]]; then
        echo "Las contraseñas no coinciden. Intente nuevamente."
    elif ! crear_contrasena "$contrasena"; then
        echo "Intente nuevamente con una contraseña válida."
    else
        break
    fi
done

# Crear usuario y asignar contraseña
sudo useradd -m "$usuario"
echo "$usuario:$contrasena" | sudo chpasswd

echo "Usuario '$usuario' creado exitosamente."
