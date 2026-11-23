# Descarga e instalación

Un único ZIP por build, sin variantes: LineageOS limpio, sin servicios de Google
preinstalados. La publicación principal es la release
[`amethyst-23.2-rcd1`](https://github.com/Daxandere/android_device_xiaomi_amethyst/releases/tag/amethyst-23.2-rcd1)
en GitHub, con las notas del build y los dos archivos que caben bajo el límite
de 2 GiB por asset. El servidor de builds queda como espejo.

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
| `rcd1` | `1795395067` | arranque, cámara, pantalla, batería |

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
