# Dockerfile del servidor dedicado externo de 8-Bit Bros — Chavo.
#
# Este contenedor NO compila el juego: corre el binario ya exportado
# desde el editor de Godot con el preset "Linux Servidor (dedicado,
# para Render)" (ver export_presets.cfg del proyecto). Esto es lo más
# simple y confiable: no depende de bajar plantillas de exportación
# adentro del contenedor ni de que la versión de Godot del CI matchee
# exacto con la del editor.
#
# Antes de construir esta imagen (o de que Render la construya):
#   1) Abrí el proyecto en el editor de Godot 4.8.
#   2) Project > Export... > elegí el preset
#      "Linux Servidor (dedicado, para Render)".
#   3) Exportá. Va a generar los archivos dentro de esta misma
#      carpeta, en build/ (8-bit-bros-servidor.x86_64 y su .pck).
#   4) Recién ahí hacé commit/push y desplegá en Render.
#
# Ver README.md en esta carpeta para el paso a paso completo.

FROM ubuntu:24.04

# Dependencias mínimas de runtime que necesita un binario de Godot
# headless en Linux.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        libx11-6 \
        libxcursor1 \
        libxinerama1 \
        libxrandr2 \
        libxi6 \
        libgl1 \
        libasound2t64 \
        libpulse0 \
        libudev1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /servidor

COPY build/ /servidor/

RUN chmod +x /servidor/8-bit-bros-servidor.x86_64

ENV SDL_AUDIODRIVER=dummy

# Render pasa el puerto real en la variable de entorno PORT; el juego
# (Codigo/red.gd -> _iniciar_como_servidor_dedicado) ya lo lee solo.
CMD ["/servidor/8-bit-bros-servidor.x86_64", "--headless"]
