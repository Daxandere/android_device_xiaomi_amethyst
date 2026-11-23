# Descarga e instalación del RC

Un solo árbol, dos ZIP del mismo código. Se diferencian sólo en los paquetes
que llevan dentro; comportamiento, cámara, pantalla y batería son idénticos.

| Variante | ZIP | Tamaño | SHA-256 |
|---|---|---|---|
| Vanilla | [`lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip`](https://ferrari.serverhive.in/daxandere/rc1/lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip) | 2 083 623 970 B | `676c8c068716ccc0daa9489778533273cd31b9b4c76534ef0cad9210231016b7` |
| microG + Aurora Store | [`lineage-23.2-20261123-UNOFFICIAL-rcd1-microg-amethyst.zip`](https://ferrari.serverhive.in/daxandere/rc1-microg/lineage-23.2-20261123-UNOFFICIAL-rcd1-microg-amethyst.zip) | 2 173 371 156 B | `6bbbe660d0c3209766122b072ad5346831968563f0b75d12101762f28080ea07` |

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
