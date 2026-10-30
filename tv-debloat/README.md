# TV debloat

Scripts para quitar bloatware y aligerar un Android TV / Google TV por ADB inalámbrico.
Se ejecutan desde un ordenador en la **misma red Wi‑Fi** que el TV.

1. En el TV: Ajustes → Sistema → Acerca de → pulsa 7 veces "Compilación" → Opciones de desarrollador → activa **Depuración inalámbrica** (o "Depuración por red").
2. Instala `adb` (Android platform-tools).
3. Si el TV pide emparejar, usa el puerto y código de "Emparejar con código":
   `./debloat.sh 192.168.1.74:39937 --pair 192.168.1.74:<PUERTO_PAREO> <CODIGO>`
   Si no: `./debloat.sh 192.168.1.74:39937`
4. Acepta el aviso de depuración en la pantalla del TV.

**TD Systems y otras marcas poco comunes:** el script solo incluye los paquetes de Google
y de las marcas principales. Ejecuta primero `./debloat.sh 192.168.1.74:39937 --list` para guardar
el inventario de paquetes del TV y revisar qué apps del fabricante sobran. No desactives nada que
contenga `tvcenter`, `tvinput`, `tuner`, `hdmi` o `settings`: es lo que hace funcionar la TDT, las
entradas HDMI y los ajustes.

Para una interfaz más ligera, descarga un launcher (Projectivy Launcher, FLauncher…) como
`launcher.apk` en esta carpeta antes de ejecutar el script.

Los paquetes se **desactivan**, no se desinstalan. `./restore.sh 192.168.1.74:39937` lo revierte todo.
