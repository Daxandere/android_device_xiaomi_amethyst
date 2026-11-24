# Descarga e instalación

Un único ZIP por build, sin variantes: LineageOS limpio, sin servicios de Google
preinstalados. La publicación principal es la release
[`amethyst-23.2-rcd1`](https://github.com/Daxandere/android_device_xiaomi_amethyst/releases/tag/amethyst-23.2-rcd1)
en GitHub, con las notas del build y los dos archivos que caben bajo el límite
de 2 GiB por asset. El servidor de builds queda como espejo.

Hay varios cortes publicados sobre un único producto limpio (vanilla): `rcd1`
(el primer RC subido como asset en GitHub), `rcd2` (primera build `user` con
claves propias) y **`rcd7`** (última build `user` firmada con `release-keys`
propias, con fluidez de QS a 120 Hz, Bluetooth, recovery F2FS y cámara 1080p/`0.7×`
corregidos). Ninguno lleva variantes ni servicios preinstalados.

## RC1 (`rcd1`)

| ZIP | Tamaño | SHA-256 |
|---|---|---|
| [GitHub](https://github.com/Daxandere/android_device_xiaomi_amethyst/releases/download/amethyst-23.2-rcd1/lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip) · [espejo](https://ferrari.serverhive.in/daxandere/rc1/lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip) | 2 083 623 970 B | `676c8c068716ccc0daa9489778533273cd31b9b4c76534ef0cad9210231016b7` |

MindTheGapps para Android 16 arm64 (opcional, se flashea después del ROM) es el
segundo asset de esa release:
[`MindTheGapps-16.0.0-arm64-20261023_034858.zip`](https://github.com/Daxandere/android_device_xiaomi_amethyst/releases/download/amethyst-23.2-rcd1/MindTheGapps-16.0.0-arm64-20261023_034858.zip),
523 923 293 B, SHA-256
`6929593937cd85541228e4e5db9cbb5455338bf33c75eabf610de632ac155810`.

Cada carpeta publica además un `SHA256SUMS.txt` con esos valores.

## Requisitos

- HyperOS Global `OS3.0.307.0.WOPMIXM` (HyperOS 3.0, Android 16) o posterior de
  la misma región, instalado antes de flashear. Comprobalo con
  `adb shell getprop ro.build.version.incremental`, que tiene que devolver
  `OS3.0.307.0.WOPMIXM`, o en *Ajustes → Acerca del teléfono → versión de
  HyperOS*. Regiones y versiones admitidas: [FIRMWARE.md](FIRMWARE.md).
- Bootloader desbloqueado y recovery de LineageOS para `amethyst`.

## Instalar

El teléfono es A/B y el ZIP es un OTA completo: se instala con *sideload* desde
el recovery de Lineage, no con `fastboot flash`.

```bash
adb reboot sideload
adb sideload lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip
```

Al terminar, el recovery deja el slot inactivo con el build nuevo y lo marca
para el siguiente arranque.

### Cuándo borrar datos

No hace falta si vienes de un build de esta misma rama; conviene si vienes de
otra ROM o quieres el estado de fábrica.

Con el teléfono en el bootloader:

```bash
fastboot -w                                   # borra userdata y metadata
fastboot reboot
```

## Qué está verificado

Probado en el teléfono (Redmi Note 14 Pro+ 5G Global, `amethyst`) el 23 de
noviembre de 2026:

| Build | Incremental | Probado |
|---|---|---|
| `rcd1` | `1795395067` | arranque, cámara base, pantalla, batería (`test-keys`) |
| `rcd2` | `1795442392` | instalación limpia por *sideload* con `release-keys` propias |
| `rcd7` | `1795533763` | uso diario completo (`user` + `release-keys`): QS blur a 120 Hz, Bluetooth + coche, recovery limpio, `0.7×` capado a 1080p y croma 1080p 24/30/60 fps corregido |

## Build actual recomendada (`rcd7`, firmada con `release-keys`)

Compilada el 24 de noviembre de 2026 como `user` con las claves privadas del árbol (`releasekey`, `ro.build.tags=release-keys`). Se instala directamente por *sideload* sin borrar datos sobre cualquier build previa firmada con estas mismas claves (`rcd2`, `rcd5`, `rcd6`).

| Artefacto | Tamaño | SHA-256 |
|---|---|---|
| [`lineage-23.2-20261124-UNOFFICIAL-rcd7-amethyst.zip`](https://ferrari.serverhive.in/daxandere/rcd7/lineage-23.2-20261124-UNOFFICIAL-rcd7-amethyst.zip) | 2 076 254 035 B | `82495f2f4db92be53d980483726ab97b5591b5a87c1322bdfdc4a2ca6cb81748` |
| [`recovery.img`](https://ferrari.serverhive.in/daxandere/rcd7/recovery.img) | 104 857 600 B | `0e143ecefc7f8dabbb2f72f55403f8a72da860cff3a87272930967302b2ba786` |

## Verificar la descarga

```bash
sha256sum lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip
# 676c8c068716ccc0daa9489778533273cd31b9b4c76534ef0cad9210231016b7
```

## Builds firmados (`rcd2`)

Compilados el 23 de noviembre de 2026 desde `d64de35` con las claves propias
del árbol (`releasekey` con huella SHA-256
`73:25:A3:54:F9:BF:6E:63:D6:25:D6:DA:AD:EA:EF:2E:33:43:1C:4D:28:42:EE:0F:B3:D6:12:00:01:61:1C:4E`)
y `ro.build.tags=release-keys`, así que Ajustes ya no marca el ROM como firmado
con claves públicas. El procedimiento y la migración están en
[SIGNING.md](SIGNING.md).

| ZIP | Tamaño | SHA-256 | Variante de build |
|---|---|---|---|
| [`lineage-23.2-20261123-UNOFFICIAL-rcd2-amethyst.zip`](https://ferrari.serverhive.in/daxandere/rcd2/lineage-23.2-20261123-UNOFFICIAL-rcd2-amethyst.zip) | 2 076 253 458 B | `cf1ce5567f7edb7437bb4350caf2b8b33fd0f8b49af5771210c0028fb0c29e00` | `user` |

Recovery, extraído de su propio `payload.bin`:

| Recovery | Tamaño | SHA-256 |
|---|---|---|
| [`recovery-rcd2.img`](https://ferrari.serverhive.in/daxandere/rcd2/recovery-rcd2.img) | 104 857 600 B | `70b350323435f1f627f81708d1eb631e8f3048083ce0719fd46d2d6f709ccb8a` |

La carpeta publica su `SHA256SUMS.txt`. El build es `user` y no expone root.

Cambiar de las claves de prueba a las propias cambia el certificado de
plataforma: para pasar de `rcd1` a `rcd2` hay que flashear el recovery nuevo y
borrar datos, como describe [SIGNING.md](SIGNING.md#4-moving-an-installed-phone-to-the-new-keys).

El `rcd2` vanilla es el build que corre ahora en el teléfono (incremental
`1795442392`), instalado en limpio por *sideload* el 23 de noviembre de 2026.

## Build de prueba (`rcd3-test`)

Compilado el 23 de noviembre de 2026 desde el árbol actual, como `userdebug` y
con las mismas claves propias, para comprobar que las mejoras siguen intactas
tras la limpieza de producto y documentación. Es `userdebug` a propósito:
permite `adb root`, que es lo que necesitan los diagnósticos de cámara. Las
builds de lanzamiento se compilan en `user`.

| ZIP | Tamaño | SHA-256 |
|---|---|---|
| [`lineage-23.2-20261123-UNOFFICIAL-rcd3-test-amethyst.zip`](https://ferrari.serverhive.in/daxandere/rcd3-test/lineage-23.2-20261123-UNOFFICIAL-rcd3-test-amethyst.zip) | 2 083 630 861 B | `c32831024080698ebab280962fbb9fe0ecdb7ad61b143ab78dddd818b152f948` |

Recovery, extraído de su propio `payload.bin`:

| Recovery | Tamaño | SHA-256 |
|---|---|---|
| `recovery.img` | 104 857 600 B | `4c0309c8de5fde422ce66831c358ec8c7e596c5c1a7e0bbe6d50cc734a5bf6b7` |

Incremental `1795459283`, `ro.build.type=userdebug` y `ro.build.tags=release-keys`.
No es una release: valida el árbol de trabajo. Al compartir claves con `rcd2` se
instala encima por *sideload* sin borrar datos. Cuando se confirme en el
teléfono, el siguiente RC sale en `user` con estas mismas claves, así que
tampoco exigirá borrar datos. Los detalles de la compilación y lo verificado en
el paquete están en [HANDOFF-307.md](HANDOFF-307.md).
