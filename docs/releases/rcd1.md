# Notas de la release `amethyst-23.2-rcd1`

Texto publicado el 23 de noviembre de 2026 en
[`amethyst-23.2-rcd1`](https://github.com/Daxandere/android_device_xiaomi_amethyst/releases/tag/amethyst-23.2-rcd1),
sobre el commit [`afb024f`](https://github.com/Daxandere/android_device_xiaomi_amethyst/commit/afb024fa1c9da9c4cc133565b61de52250f33eb4).
Se guarda acá tal cual salió, para que quede versionado y sirva de base para el
próximo RC: se copia el archivo, se actualizan versión, incremental, fecha,
tamaños, SHA-256 y commit, y se vuelve a publicar con la misma estructura.

---

![LineageOS 23.2](https://img.shields.io/badge/LineageOS-23.2-167C80?style=flat-square) ![Android 16](https://img.shields.io/badge/Android-16-3DDC84?style=flat-square) ![Dispositivo](https://img.shields.io/badge/dispositivo-amethyst-8E75B2?style=flat-square) ![Estado](https://img.shields.io/badge/estado-RC1-F5A623?style=flat-square)

**LineageOS 23.2 · RC1** para el Redmi Note 14 Pro+ 5G Global (`amethyst`, 24115RA8EG).
Primer candidato de la rama `amethyst-23.2-rc1`: OTA completo A/B, compilado desde el
árbol del dispositivo publicado en [`afb024f`](https://github.com/Daxandere/android_device_xiaomi_amethyst/commit/afb024fa1c9da9c4cc133565b61de52250f33eb4).

| Dato | Valor |
|---|---|
| Dispositivo | Redmi Note 14 Pro+ 5G Global · `amethyst` · 24115RA8EG |
| Sistema | LineageOS 23.2 sobre Android 16 |
| Build | `lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst` |
| Incremental | `1795395067` |
| HyperOS base | Global `OS3.0.307.0.WOPMIXM` · HyperOS 3.0 · Android 16 |
| Fecha | 23 de noviembre de 2026 |
| Rama | `amethyst-23.2-rc1` en [`afb024f`](https://github.com/Daxandere/android_device_xiaomi_amethyst/commit/afb024fa1c9da9c4cc133565b61de52250f33eb4) |

## Descargas

| Asset | Qué es | Tamaño | SHA-256 |
|---|---|---|---|
| [`lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip`](https://github.com/Daxandere/android_device_xiaomi_amethyst/releases/download/amethyst-23.2-rcd1/lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip) | OTA completo A/B de LineageOS 23.2 vanilla, sin servicios de Google ni microG | 2 083 623 970 B | `676c8c068716ccc0daa9489778533273cd31b9b4c76534ef0cad9210231016b7` |
| [`MindTheGapps-16.0.0-arm64-20261023_034858.zip`](https://github.com/Daxandere/android_device_xiaomi_amethyst/releases/download/amethyst-23.2-rcd1/MindTheGapps-16.0.0-arm64-20261023_034858.zip) | MindTheGapps para Android 16 arm64: opcional, se flashea después del ROM si querés Play Store | 523 923 293 B | `6929593937cd85541228e4e5db9cbb5455338bf33c75eabf610de632ac155810` |

### Variante con microG

Este OTA pasa de 2 GiB, el máximo por archivo de una release de GitHub, así que se publica en el servidor de builds en lugar de como asset. Se descarga desde acá:

**[lineage-23.2-20261123-UNOFFICIAL-rcd1-microg-amethyst.zip](https://ferrari.serverhive.in/daxandere/rc1-microg/lineage-23.2-20261123-UNOFFICIAL-rcd1-microg-amethyst.zip)** · 2 173 371 156 B

Es el mismo árbol que el vanilla, más microG Services, microG Companion, GsfProxy y Aurora Store preinstalados. Límites, *signature spoofing* y la verificación completa en el teléfono: [`docs/MICROG.md`](https://github.com/Daxandere/android_device_xiaomi_amethyst/blob/amethyst-23.2-rc1/docs/MICROG.md).

SHA-256: `6bbbe660d0c3209766122b072ad5346831968563f0b75d12101762f28080ea07`

## Requisitos

- HyperOS Global `OS3.0.307.0.WOPMIXM` (HyperOS 3.0 sobre Android 16) instalado en el teléfono antes de flashear, o una versión posterior de la misma región. Los blobs, el kernel y el firmware declarados por el árbol son de esa base: no mezclar regiones (`WOPMIXM` / `WOPINXM` / `WOPCNXM`) ni bajar de versión. El detalle está en [`docs/FIRMWARE.md`](https://github.com/Daxandere/android_device_xiaomi_amethyst/blob/amethyst-23.2-rc1/docs/FIRMWARE.md).
- Comprobación: `adb shell getprop ro.build.version.incremental` tiene que devolver `OS3.0.307.0.WOPMIXM`, y `adb shell getprop ro.product.model` tiene que devolver `24115RA8EG`. En el teléfono: *Ajustes → Acerca del teléfono → versión de HyperOS*.
- Bootloader desbloqueado y recovery de LineageOS para `amethyst` (el del RC sirve para las dos variantes).
- El teléfono es A/B: la instalación es por *sideload* del OTA completo, no con `fastboot flash`.
- La variante con microG exige borrar datos; la vanilla, no.

## Instalar

```bash
adb reboot sideload
adb sideload lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip
adb sideload MindTheGapps-16.0.0-arm64-20261023_034858.zip   # opcional, sin reiniciar entre los dos
```

Al terminar, el recovery deja el build nuevo en el slot inactivo y lo marca para el siguiente arranque.

Si venís de otra ROM o querés el estado de fábrica, borrá datos antes del primer arranque:

```bash
fastboot -w
fastboot reboot
```

## Verificar la descarga

```bash
sha256sum lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip
# 676c8c068716ccc0daa9489778533273cd31b9b4c76534ef0cad9210231016b7

sha256sum MindTheGapps-16.0.0-arm64-20261023_034858.zip
# 6929593937cd85541228e4e5db9cbb5455338bf33c75eabf610de632ac155810
```

## Qué lleva este build

- Power HAL `android.hardware.power-service.lineage-libperfmgr` con los boosts de GPU, DDR y L3, el `cpu_dma_latency` por defecto que acepta el kernel y la frecuencia L3 que acepta el nodo.
- Rango de refresco 60–120 Hz en Ajustes de pantalla, con el interruptor de pantalla fluida oculto.
- Cámara: overlay de Aperture restaurado (lentes auxiliares, principal y frontal 1080p60), EIS2 de terceros activo con los perfiles CamX de stock y macro limitada a 720p.
- Firmware, kernel, DTBs, DTBO y módulos del Global `OS3.0.307.0.WOPMIXM`, más las políticas StrongBox y Weaver.

## Estado

Probado en el dispositivo el 23 de noviembre de 2026.

| Build | Incremental | Probado |
|---|---|---|
| Vanilla `rcd1` | `1795395067` | arranque, cámara, pantalla, batería |
| microG `rcd1-microg` | `1795399981` | instalación limpia, Self-Check completo, registro de dispositivo, Cloud Messaging, Aurora Store |

## Problemas conocidos

- 2160p con la lente de 0.7× todavía cierra Aperture.
- Grabación a 1080p con estabilización activa puede mostrar croma corrupto.

## Documentación

- [`docs/DOWNLOAD.md`](https://github.com/Daxandere/android_device_xiaomi_amethyst/blob/amethyst-23.2-rc1/docs/DOWNLOAD.md) — descargas, variantes y cuándo borrar datos.
- [`docs/FLASH.md`](https://github.com/Daxandere/android_device_xiaomi_amethyst/blob/amethyst-23.2-rc1/docs/FLASH.md) — instalación paso a paso.
- [`docs/MICROG.md`](https://github.com/Daxandere/android_device_xiaomi_amethyst/blob/amethyst-23.2-rc1/docs/MICROG.md) — variante con microG.
- [`docs/BRANCHES.md`](https://github.com/Daxandere/android_device_xiaomi_amethyst/blob/amethyst-23.2-rc1/docs/BRANCHES.md) — inventario de ramas, pruebas pendientes y detalle de cada fallo.

---

Build no oficial, sin relación con el proyecto LineageOS. Compilado desde el árbol del dispositivo en `amethyst-23.2-rc1`; el código fuente de cada componente está en el árbol publicado y en los repositorios que enlaza.
