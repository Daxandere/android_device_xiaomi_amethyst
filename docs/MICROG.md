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
WITH_MICROG=true TARGET_UNOFFICIAL_BUILD_ID=rcd1-microg breakfast amethyst
WITH_MICROG=true TARGET_UNOFFICIAL_BUILD_ID=rcd1-microg m -j32 bacon
```

`WITH_MICROG` tiene que estar en el entorno de las dos órdenes: la configuración
de producto se lee en `breakfast` y se vuelve a leer en `m`.

El resultado es `out/target/product/amethyst/lineage-23.2-<fecha>-UNOFFICIAL-rcd1-microg-amethyst.zip`.
Sin `WITH_MICROG=true` el build es idéntico al RC vanilla: los módulos de
`microg/Android.bp` ni siquiera se incluyen en el producto.

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
