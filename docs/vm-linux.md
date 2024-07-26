

# VMs Linux: Ubuntu Desktop 22.04

Realizamos la instalación en VirtualBox. Nos aseguramos de habilitar el portapapeles compartido bidireccional y de asignar red Bridged. Instalamos las vbox guest tools asap.

Introducimos este comando para ejecutar el script. Algunas notas: cuando ponga algo de "[377/412] Linking C executable bin/nvim" va a tardar un minuto o dos, no hay que preocuparse.

```bash
bash -c "$(wget -qLO - https://github.com/pabloqpacin/lab-cybersecurity/raw/main/scripts/ubuntu-2204-base.sh)"
```
<!-- Estos son los hostnames que elegimos según la topología del lab: -->
Le asignamos el hostname `ubuntu-desktop-2204-Server`

Es buen momento para reiniciar la VM. En la pantalla de login, antes de introducir la contraseña, clickar en el engranaje y seleccionar *Ubuntu on Xorg* (el programa de escritorio remoto **anydesk** no funciona en Wayland, que es el entorno gŕafico por defecto en la opción *Ubuntu*).

<!-- captureja -->

Ya que es Desktop, personalizamos la barra lateral y el wallpaper.

En este punto, hacemos una snapshot que llamaremos `ubuntu-2204-base`.

Ahora pinchamos en la snapshot y clickamos en Clonar. La nueva máquina la llamaremos `ubuntu-desktop-2204-Cliente1`, y en la política de MAC seleccionaremos *Generar nuevas direcciones MAC*

## Clientes

En la nueva VM (y en cualquier otra VM Linux cliente que hagamos más adelante), volvemos a ejecutar el script para actualizar el sistema y asignar un hostname. En este caso `ubuntu-desktop-2204-Cliente1`

Ahora hacemos la snapshot `ubuntu-2204-base`.

TODO: hacer más movidas

> Si en algún momento se actualiza el script `ubuntu-2204-base.sh`: tomar snapshot, restaurar esta, ejecutar el script, tomar snapshot

## Server

## TODO

- [ ] [PlantUML con Docker](https://hub.docker.com/r/plantuml/plantuml-server) para safar mapas de red en markdown (en Linux)