# Descarga e instalación del RC

Un solo árbol, dos ZIP del mismo código. Se diferencian sólo en los paquetes
que llevan dentro; comportamiento, cámara, pantalla y batería son idénticos.

La publicación principal es la release
[`amethyst-23.2-rcd1`](https://github.com/Daxandere/android_device_xiaomi_amethyst/releases/tag/amethyst-23.2-rcd1)
en GitHub, con las notas del build y los dos archivos que caben bajo el límite
de 2 GiB por asset. El servidor de builds queda como espejo de las dos
variantes.

| Variante | ZIP | Tamaño | SHA-256 |
|---|---|---|---|
| Vanilla | [GitHub](https://github.com/Daxandere/android_device_xiaomi_amethyst/releases/download/amethyst-23.2-rcd1/lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip) · [espejo](https://ferrari.serverhive.in/daxandere/rc1/lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip) | 2 083 623 970 B | `676c8c068716ccc0daa9489778533273cd31b9b4c76534ef0cad9210231016b7` |
| microG + Aurora Store | [`lineage-23.2-20261123-UNOFFICIAL-rcd1-microg-amethyst.zip`](https://ferrari.serverhive.in/daxandere/rc1-microg/lineage-23.2-20261123-UNOFFICIAL-rcd1-microg-amethyst.zip) | 2 173 371 156 B | `6bbbe660d0c3209766122b072ad5346831968563f0b75d12101762f28080ea07` |

MindTheGapps para Android 16 arm64 (opcional, se flashea después del ROM) es el
segundo asset de esa release:
[`MindTheGapps-16.0.0-arm64-20261023_034858.zip`](https://github.com/Daxandere/android_device_xiaomi_amethyst/releases/download/amethyst-23.2-rcd1/MindTheGapps-16.0.0-arm64-20261023_034858.zip),
523 923 293 B, SHA-256
`6929593937cd85541228e4e5db9cbb5455338bf33c75eabf610de632ac155810`.

Recovery del RC (idéntica para las dos variantes):
[`recovery-rcd1-microg.img`](https://ferrari.serverhive.in/daxandere/rc1-microg/recovery-rcd1-microg.img),
104 857 600 B, SHA-256
`8df725bb8ba4dc3386c1f1fb9c04d17990b98eea80957f0a197d24cb554fa6e9`.

Cada carpeta publica además un `SHA256SUMS.txt` con esos valores.

## Elegir variante

- **Vanilla**: LineageOS limpio, sin servicios de Google ni microG. Es el build
  de referencia para todo lo demás.
- **microG**: lo mismo más microG Services, microG Companion, GsfProxy y Aurora
  Store preinstalados, con *signature spoofing* activo porque el build es
  `debuggable`. Detalles, límites y por qué se hace así en [MICROG.md](MICROG.md).

## Requisitos

- HyperOS Global `OS3.0.307.0.WOPMIXM` (HyperOS 3.0, Android 16) o posterior de
  la misma región, instalado antes de flashear. Comprobalo con
  `adb shell getprop ro.build.version.incremental`, que tiene que devolver
  `OS3.0.307.0.WOPMIXM`, o en *Ajustes → Acerca del teléfono → versión de
  HyperOS*. Regiones y versiones admitidas: [FIRMWARE.md](FIRMWARE.md).
- Bootloader desbloqueado y recovery de LineageOS para `amethyst`; el del RC
  sirve para las dos variantes.

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

- **microG**: obligatorio. `com.google.android.gms` no puede aparecer a mitad de
  vida del sistema; si el teléfono ya arrancó sin él, hay que borrar datos antes
  del primer arranque de esta variante.
- **Vanilla**: no hace falta si vienes de un build de esta misma rama; conviene
  si vienes de otra ROM o quieres el estado de fábrica.

Con el teléfono en el bootloader:

```bash
fastboot -w                                   # borra userdata y metadata
fastboot reboot
```

## Qué está verificado

Las dos variantes salen del mismo árbol y se probaron en el teléfono
(Redmi Note 14 Pro+ 5G Global, `amethyst`) el 23 de noviembre de 2026:

| Build | Incremental | Probado |
|---|---|---|
| Vanilla `rcd1` | `1795395067` | arranque, cámara, pantalla, batería |
| microG `rcd1-microg` | `1795399981` | instalación limpia, Self-Check completo, registro de dispositivo, Cloud Messaging, Aurora Store |

La lista completa de comprobaciones de la variante microG está en
[MICROG.md](MICROG.md#verificación-en-el-teléfono).

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

| Variante | ZIP | Tamaño | SHA-256 | Variante de build |
|---|---|---|---|---|
| Vanilla | [`lineage-23.2-20261123-UNOFFICIAL-rcd2-amethyst.zip`](https://ferrari.serverhive.in/daxandere/rcd2/lineage-23.2-20261123-UNOFFICIAL-rcd2-amethyst.zip) | 2 076 253 458 B | `cf1ce5567f7edb7437bb4350caf2b8b33fd0f8b49af5771210c0028fb0c29e00` | `user` |
| microG + Aurora Store | [`lineage-23.2-20261123-UNOFFICIAL-rcd2-microg-amethyst.zip`](https://ferrari.serverhive.in/daxandere/rcd2-microg/lineage-23.2-20261123-UNOFFICIAL-rcd2-microg-amethyst.zip) | 2 173 379 812 B | `6b07619d46d3a83e4407af95d077bdd0f25e3c7acc9f1fe6f0683ce0ab4d61e4` | `userdebug` |

Recovery de cada variante, extraído de su propio `payload.bin`:

| Variante | Recovery | Tamaño | SHA-256 |
|---|---|---|---|
| Vanilla | [`recovery-rcd2.img`](https://ferrari.serverhive.in/daxandere/rcd2/recovery-rcd2.img) | 104 857 600 B | `70b350323435f1f627f81708d1eb631e8f3048083ce0719fd46d2d6f709ccb8a` |
| microG | [`recovery-rcd2-microg.img`](https://ferrari.serverhive.in/daxandere/rcd2-microg/recovery-rcd2-microg.img) | 109 051 904 B | `d120a5fd035d01977b70253bbde35de7a500c7f0e2dbf8ccaaf6fe4068d91344` |

Las dos carpetas publican su `SHA256SUMS.txt`. La variante microG sigue en
`userdebug` porque el *signature spoofing* de LineageOS exige
`ro.debuggable=1` ([MICROG.md](MICROG.md)); el vanilla es `user` y no expone
root.

Cambiar de las claves de prueba a las propias cambia el certificado de
plataforma: para pasar de `rcd1` a `rcd2` hay que flashear el recovery nuevo y
borrar datos, como describe [SIGNING.md](SIGNING.md#4-moving-an-installed-phone-to-the-new-keys).

Estos ZIP están compilados y verificados por firma, pero **no se han flasheado
todavía** en el teléfono; el build probado sigue siendo `rcd1`.
