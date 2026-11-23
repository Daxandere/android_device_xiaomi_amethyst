# Variante con microG y Aurora Store

El árbol produce dos ROMs con el mismo código:

| Variante | Etiqueta de build | Contenido |
|---|---|---|
| Vanilla (RC) | `rcd1` | LineageOS sin servicios de Google |
| microG | `rcd1-microg` | Lo mismo + microG Services, microG Companion, GsfProxy y Aurora Store preinstalados |

No son dos ramas ni dos árboles: es el mismo `device/xiaomi/amethyst` con
`WITH_MICROG=true`, así que cualquier corrección vale para las dos.

## Qué se instala

| Paquete | Versión | Ruta en la imagen | Origen |
|---|---|---|---|
| `com.google.android.gms` (microG Services) | 0.3.18.252432 | `/product/priv-app/MicrogGmsCore` | [microG GmsCore](https://github.com/microg/GmsCore/releases/tag/v0.3.18.252432) |
| `com.android.vending` (microG Companion) | 0.3.18.40226 | `/product/priv-app/MicrogCompanion` | misma release |
| `com.google.android.gsf` (GsfProxy) | v0.1.0 | `/product/app/MicrogGsfProxy` | [microG GsfProxy](https://github.com/microg/GsfProxy/releases/tag/v0.1.0) |
| `com.aurora.store` (Aurora Store) | 4.8.4 (76) | `/product/app/AuroraStore` | [Aurora OSS, build oficial firmado](https://gitlab.com/AuroraOSS/AuroraStore/-/releases/4.8.4) |

Con ellos van los XML de permisos en `/product/etc/{permissions,default-permissions,sysconfig}`:
sin el `privapp-permissions` de `com.google.android.gms`, microG no puede sostener
`FAKE_PACKAGE_SIGNATURE` ni ser proveedor de ubicación.

## Compilar

Los APK no están en git: microG Services pesa ~108 MB y GitHub rechaza archivos
de más de 100 MB. El script los descarga de la release oficial y verifica el
SHA-256 antes de dejarlos en `microg/prebuilts/`.

```bash
cd $DEVICE
git checkout amethyst-23.2-rc1
./microg/fetch-prebuilts.sh
cd $SRC
. build/envsetup.sh
WITH_MICROG=true TARGET_UNOFFICIAL_BUILD_ID=rcd1-microg breakfast amethyst userdebug
WITH_MICROG=true TARGET_UNOFFICIAL_BUILD_ID=rcd1-microg m -j32 bacon
```

La variante de compilación es `userdebug` a propósito (ver
[Por qué este build es *debuggable*](#por-qué-este-build-es-debuggable)); el
build vanilla sale `user` y las dos van firmadas con las claves propias, como
describe [SIGNING.md](SIGNING.md).

`WITH_MICROG` tiene que estar en el entorno de las dos órdenes: la configuración
de producto se lee en `breakfast` y se vuelve a leer en `m`.

El resultado es `out/target/product/amethyst/lineage-23.2-<fecha>-UNOFFICIAL-rcd1-microg-amethyst.zip`.
Sin `WITH_MICROG=true` el build es idéntico al RC vanilla: los módulos de
`microg/Android.bp` ni siquiera se incluyen en el producto.

### Build de referencia

Compilado el 23 de noviembre de 2026 sobre `amethyst-23.2-rc1` (`9c41cc2`),
incremental `1795399981`:

| Dato | Valor |
|---|---|
| ZIP | `lineage-23.2-20261123-UNOFFICIAL-rcd1-microg-amethyst.zip`, 2 173 371 156 B |
| SHA-256 | `6bbbe660d0c3209766122b072ad5346831968563f0b75d12101762f28080ea07` |
| `recovery.img` | SHA-256 `8df725bb8ba4dc3386c1f1fb9c04d17990b98eea80957f0a197d24cb554fa6e9` |
| `ro.debuggable` / `ro.adb.secure` | `1` / `1` |
| Instalado y probado en el teléfono | sí, 23 de noviembre de 2026 |

Comprobado en `out/target/product/amethyst/`: los cuatro APK están en
`product/priv-app/MicrogGmsCore`, `product/priv-app/MicrogCompanion`,
`product/app/MicrogGsfProxy` y `product/app/AuroraStore`, y los cinco XML en
`product/etc/{permissions,default-permissions,sysconfig}` con su extensión
`.xml`.

### Verificación en el teléfono

Instalado con *sideload* sobre datos borrados y arrancado en el slot `_a`:

| Comprobación | Resultado |
|---|---|
| Build | `ro.build.type=userdebug`, `ro.debuggable=1`, `ro.adb.secure=1`, incremental `1795399981` |
| Paquetes | los cuatro se cargan desde `/product` (`MicrogGmsCore.apk`, `MicrogCompanion.apk`, `MicrogGsfProxy.apk`, `AuroraStore.apk`) con las versiones de la tabla de arriba |
| Permisos de runtime | concedidos de fábrica por los XML: ubicación fina y gruesa, ubicación en segundo plano, contactos, SMS, estado del teléfono, cámara, notificaciones, almacenamiento |
| microG Self-Check | todas las filas en verde: *System spoofs signature*, firmas de Services/Companion y GsfProxy, permisos de ubicación, almacenamiento, contactos, SMS, notificaciones y batería |
| Servicios de sistema | GmsCore registrado como proveedor de ubicación (`FusedLocationProviderService`, `NetworkLocationProviderService`, `GeocodeProviderService`) |
| Registro de dispositivo | activado; el *check-in* completa y emite `androidId`, `securityToken` y `versionInfo` |
| Cloud Messaging | activado (`gcm_enable_mcs_service=true`) |
| Aurora Store | arranca en su asistente de bienvenida y ofrece sesión anónima o cuenta |

La única casilla que no sale verde de fábrica es **«This app can appear on top
of other apps»**: `SYSTEM_ALERT_WINDOW` es un *app-op*, no un permiso de
runtime, así que ni `default-permissions` ni `privapp-permissions` lo conceden.
Se resuelve con un toque en el propio Self-Check o por ADB:

```bash
adb shell appops set com.google.android.gms SYSTEM_ALERT_WINDOW allow
```

El registro de dispositivo y Cloud Messaging vienen **apagados** a propósito: son
decisiones del usuario (ver [Primer arranque](#primer-arranque)). En el
dispositivo de referencia se activaron a mano para esta prueba.

### Tamaño y GitHub

El ZIP pasa de 2 GiB (2 147 483 648 B), el máximo por archivo de una release de
GitHub, así que no se puede subir como asset único. La causa no es microG en sí
sino Soong: `android_app_import` instala el APK con todas sus entradas sin
comprimir, y `MicrogGmsCore.apk` pasa de 108 MB a 265 MB (lleva libs `x86` y
`x86_64` de OpenCV y Mapbox que el teléfono no usa). No se recortan: cualquier
modificación del APK invalida la firma oficial de microG y con ella el
signature spoofing. Por eso esta variante se publica en el docroot de `ferrari`
y no como asset de una release: ver [DOWNLOAD.md](DOWNLOAD.md).

## Por qué este build es *debuggable*

El soporte de microG de LineageOS vive en `ComputerEngine.isMicrogSigned()` y
empieza con:

```java
if (!isDebuggable()) {
    return false;
}
```

Es decir, el *signature spoofing* sólo existe si `ro.debuggable=1`. A su vez,
`vendor/lineage/config/common.mk` hace:

```makefile
ifdef WITH_ADB_INSECURE
PRODUCT_SYSTEM_EXT_PROPERTIES += ro.adb.secure=0
else
PRODUCT_SYSTEM_EXT_PROPERTIES += ro.adb.secure=1
PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG := true
endif
```

O sea: la única palanca que ofrece LineageOS para dejar `ro.debuggable=1` en un
build `userdebug` es `WITH_ADB_INSECURE`, que además apaga la autenticación de
ADB.

Despejar `PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG` no funciona desde
`microg/microg.mk`: es una variable de producto de **valor único**, y al
fusionar el DAG de herencias el sistema sólo acepta el valor de una rama cuando
no está vacío (`_expand-inherited-values` en `build/make/core/node_fns.mk`).
Como `common.mk` la pone a `true` y `microg.mk` la dejaría vacía, gana `true`
siempre, sin importar el orden. Por eso se limpia en `lineage_amethyst.mk`,
después de la última herencia, donde ya no compite con nadie.

El resultado es que en la variante microG:

- `adb root` funciona en la variante microG (consecuencia de `ro.debuggable=1`).
- ADB sigue pidiendo autorización al conectar, como en el vanilla.

Por eso la variante microG se queda en `userdebug` mientras el build vanilla va
`user`: la puerta `isDebuggable()` está en el framework, no en el árbol del
dispositivo, y un build `user` dejaría el Self-Check sin *System spoofs
signature*. Las firmas no se ven afectadas: las dos variantes usan las mismas
claves propias.

La alternativa limpia sería parchear `isMicrogSigned()` para que mire una
propiedad propia en vez de `isDebuggable()`, pero eso obliga a mantener un parche
sobre `frameworks/base` en cada sincronización. No se hace.

## Primer arranque

1. Instalar la ROM con el procedimiento de [FLASH.md](FLASH.md). Si el teléfono
   ya arrancó sin microG, hay que borrar datos: el paquete `com.google.android.gms`
   no puede aparecer a mitad de vida del sistema.
2. Abrir **microG Settings** y pasar el **Self-Check**. Debe salir todo en verde
   salvo lo que depende de Google (ver abajo). Los permisos y la exención de
   batería ya vienen concedidos por los XML; el Self-Check sirve para confirmarlo.
3. Push: **Google device registration** → activar; **Cloud Messaging** → activar.
   Sin esos dos interruptores no hay notificaciones push (microG los deja
   apagados por defecto y el usuario decide).
4. Ubicación por red: **Location** → menú de tres puntos → *Online Location
   Service* → elegir backend (position.xyz o BeaconDB). El GPS funciona sin esto.

## Aurora Store

Viene instalada como app normal de producto, no privilegiada, para que su propio
actualizador pueda sustituirla por el build oficial firmado. Dos detalles:

- La primera vez que instales algo pedirá **Instalar apps desconocidas** para
  `com.aurora.store`; es un interruptor y no vuelve a preguntar.
- La sesión anónima funciona sin cuenta. Si se inicia sesión con una cuenta de
  Google, la gestiona microG.

Se eligió el APK de GitLab (9 362 660 B) y no el de F-Droid a propósito: F-Droid
firma con su propia clave, y entonces el auto-actualizador de Aurora rechazaría
las actualizaciones por firma distinta.

## Lo que no funciona

- **Play Integrity / SafetyNet**: no hay veredicto de Google. Apps de banca,
  algunos juegos y el DRM de streaming pueden negarse a arrancar.
- **Cuentas de Google**: microG acepta el inicio de sesión, pero Google puede
  bloquear la cuenta o exigir verificación; no es un reemplazo garantizado.
- **Play Store**: no está. Aurora Store cubre la instalación de apps; las compras
  y las apps de pago no.
- **Fotos/Drive/Mapas de Google**: funcionan parcialmente, sin las partes que
  dependen del cliente propietario.

## Diferencias con la variante GApps

La otra opción (ROM vanilla + MindTheGapps en el mismo recovery) usa los
paquetes reales de Google: Play Store completo, Play Integrity parcial y
`vendor/partner_gms` ausente, pero con servicios propietarios y sin control sobre
lo que hacen. La variante microG no incluye nada propietario de Google en la
imagen; sólo la app de Aurora Store, que es GPLv3.
