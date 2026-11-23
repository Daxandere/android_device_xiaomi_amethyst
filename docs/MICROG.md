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
git -C $SRC/frameworks/base am \
  $SRC/device/xiaomi/amethyst/tools/patches/microg-user-spoofing.patch
. build/envsetup.sh
WITH_MICROG=true TARGET_UNOFFICIAL_BUILD_ID=rcd2-microg breakfast amethyst user
WITH_MICROG=true TARGET_UNOFFICIAL_BUILD_ID=rcd2-microg m -j32 bacon
```

Las dos variantes se compilan igual: `user`, sin root y con `ro.debuggable=0`,
y firmadas con las claves propias como describe [SIGNING.md](SIGNING.md). La
diferencia es sólo `WITH_MICROG`. El `git am` del parche se hace una vez por
árbol (o después de cada `repo sync` que toque `frameworks/base`); el parche
vive en `tools/patches/microg-user-spoofing.patch`.

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

## Signature spoofing en un build `user`

El soporte de microG de LineageOS vive en `ComputerEngine.isMicrogSigned()` y
empezaba con:

```java
if (!isDebuggable()) {
    return false;
}
```

Es decir, el *signature spoofing* sólo existía con `ro.debuggable=1`, que en
LineageOS sólo se consigue compilando `userdebug`. Por eso las primeras
variantes microG salían `userdebug`.

Desde la variante `rcd2-microg` se compila `user` con un parche sobre
`frameworks/base` que quita esa puerta y deja intactas las dos condiciones que
importan:

```java
// Allowlist the following apps:
// * com.android.vending - microG Companion
// * com.google.android.gms - microG Services
...
return Signature.areExactMatch(
        p.getSigningDetails(), new Signature[]{MICROG_REAL_SIGNATURE});
```

O sea: sólo los dos paquetes de microG y sólo si están firmados con el
certificado real de microG pueden recibir la firma falsa de Google, y la única
firma que se puede falsificar es `MICROG_FAKE_SIGNATURE`. Un build `user` de
LineageOS ya no permite instalar nada como `com.google.android.gms` sin la clave
de microG, así que la superficie es la misma que en `userdebug` sin la puerta.

| Dato | Valor |
|---|---|
| Parche | `device/xiaomi/amethyst/tools/patches/microg-user-spoofing.patch` |
| Commit en `frameworks/base` | `2bff5998bcc5` (*Allow the microG fake signature on release builds*) |
| Aplicar | `git -C $SRC/frameworks/base am $SRC/device/xiaomi/amethyst/tools/patches/microg-user-spoofing.patch` |

El parche toca un solo fichero (`services/core/java/com/android/server/pm/ComputerEngine.java`)
y no depende de ninguna propiedad, así que sobrevive a `repo sync` mientras el
commit siga en el árbol; si un `sync` reescribe `frameworks/base`, se reaplica
con `git am`.

Consecuencias en el teléfono: `ro.build.type=user`, `ro.debuggable=0`, `adb root`
ya no existe (tampoco en la variante microG) y las apps no pueden leer `/data`
ni ejecutar `su`. El Self-Check sigue dando *System spoofs signature* en verde
porque la comprobación es la firma falsa, no `ro.debuggable`.

El *allowlist* de permisos privilegiados se comprobó antes de cambiar de
variante: `privapp-permissions-com.google.android.gms.xml` y
`privapp-permissions-com.android.vending.xml` cubren todos los permisos
`signature|privileged` que piden `GmsCore.apk` (14) y `FakeStore.apk` (3). En un
build `user` esos XML se aplican en modo *enforce*, así que un permiso sin
allowlist habría dejado el sistema sin arrancar.

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
