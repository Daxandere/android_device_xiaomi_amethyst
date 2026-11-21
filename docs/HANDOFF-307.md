# Relevo de amethyst con HyperOS Global 307

Actualizado el 21 de noviembre de 2026. Dispositivo de pruebas Redmi Note 14 Pro+ 5G Global, modelo `24115RA8EG`, producto Fastboot `amethyst`, bootloader desbloqueado. Base HyperOS `OS3.0.307.0.WOPMIXM` y LineageOS 23.2.

## Qué se comprobó

| Build | Evidencia | Estado |
| --- | --- | --- |
| `k307-bootfix` | El sideload terminó bien. El registro persistente de Xiaomi mostró cinco caídas de `keystore2` al faltar el HAL StrongBox. | Volvía a Fastboot tras unos 70 s. |
| `k307-snapshot` | Recovery montó `/metadata`, pero no pudo crear el archivo COW en `/data/gsi/ota`. La guarda del instalador abortó antes de aplicar las imágenes. | Experimento de instalación. |
| `k307-strongbox-clean` | Recovery registró `status: 0`. ADB verificó `sys.boot_completed=1`, slot B y escritorio. | Arranque comprobado. Gatekeeper falló al confirmar el PIN para inscribir huellas. |
| `k307-strongbox-init` | Freebuff registró el sistema en el slot A con SELinux enforcing. En la prueba de cámara funcionaron fotos, 720p y 4K. | La grabación a 1080p tuvo croma corrupto en ambas cámaras. El usuario comunicó buen funcionamiento general. |
| `k308-eisfix` | Tras salir de Fastboot con Encendido, ADB verificó el build, slot B y `sys.boot_completed=1`. El dispositivo ejecuta el kernel 6.1.118. | Persiste el croma corrupto en 1080p y CamX sigue iniciando EIS2 offline. |
| `k307-eisfix` | Reproduce el cambio en el archivo CamX genérico sobre el kit Global 307. | Referencia de compilación para comparar con la variante Global. |
| `k307-eisfix-global` | Sideload con `status: 0`, arranque en el slot A y los dos perfiles CamX verificados en Android. | Persiste el croma corrupto a 1080p30 con EIS activado en la trasera y la frontal. |
| `k307-eis2diag` | Sideload con `status: 0`, arranque en el slot B y `is3rdEISV2Enabled=FALSE` en ambos perfiles. | Color correcto en 1080p30 frontal y trasera y en 720p y 4K traseros. CamX registró `EISMode:0` en los modos revisados. |

El error de cámara se observó en archivos grabados. En la cámara trasera dominaba el cian y en la frontal aparecían zonas naranja y azul. El nodo `VideoEIS2PreviewEIS2Offline_IPE14` reportó un crop de `2400x1800` sobre una entrada de `1920x1440`. El ajuste de Freebuff retira `6@30` y `6@60` de `vsquality`, dejando `5@30|8@30|8@60|3001@24`.

En el Redmi, ADB leyó `ro.boot.camera.config=1`, `ro.boot.hwc=GL` y `ro.product.mod_device=amethyst_global`. El perfil `odm/etc/camera/mihal_overlap/proj_overlap_config_1.json` apunta a `camxoverridesettings_global.txt`. En `k308-eisfix`, solo se modificó el archivo genérico. El Global todavía contiene `6@30|6@60` y el log conserva el pipeline EIS2. El cambio siguiente apunta al perfil seleccionado. Hay que verificar el color y la estabilización con los archivos del nuevo build.

El operador confirmó color correcto a 1080p en **la cámara trasera y la frontal** al apagar **Habilitar estabilización de vídeo** en Aperture. Con este ajuste se puede seguir grabando a 1080p. La prueba del perfil Global se hizo con el interruptor activado.

La prueba del candidato Global confirmó que quitar `6@30|6@60` de ambos archivos CamX tampoco evita EIS2 offline cuando Aperture solicita estabilización. Los dos MP4 de la prueba se verificaron como H.264, `1920x1080`, a unos 30 fps. El log registró `ControlVideoStabilizationMode 1 EISMode:1 hasVideo:1` y, para ambos sensores, el mismo error de `VideoEIS2PreviewEIS2Offline_IPE14` con crop de `2400x1800` sobre `1920x1440`. Se corroboró la corrupción de color en un fotograma extraído del MP4 trasero.

La variante `k307-eis2diag` cambió únicamente `is3rdEISV2Enabled` a `FALSE` en ambos perfiles respecto a `k307-eisfix-global`. Con la estabilización activada en Aperture, los cuatro MP4 revisados con FFmpeg conservaron el color. CamX recibió la solicitud `ControlVideoStabilizationMode 1` y seleccionó `EISMode:0` a `1920x1080`, `1280x720` y `3840x2160`. Durante la captura filtrada tampoco volvió a aparecer el error de crop de EIS2 offline. Esto valida una solución temporal con EIS de CamX inactivo en los modos medidos. Conservar la estabilización a 1080p sigue pendiente.

En HyperOS Global 307 instalado con Clean all, el propietario confirmó color normal en los dos MP4 a 1080p de la Cámara de Xiaomi, uno trasero y uno frontal, con el modo de interfaz a 30 fps. Los archivos son H.264 de `1920x1080`, con tasas medias de 24,08 y 25,81 fps respectivamente. En grabaciones traseras adicionales a `1920x1080`, stock registró `VideoEIS3PreviewEIS2Offline` y el nodo `eisv311`. El registro disponible no enlaza ese nodo con los dos clips iniciales ni muestra un crop equivalente de IPE14 para ambos sensores. La referencia confirma el color de stock. Para reproducir su ruta de estabilización, falta correlacionar el pipeline y el crop con cada grabación a 1080p30.

Un clip frontal adicional de HyperOS, grabado con la cámara 1 activa, dio `1920x1080` y **58,41 fps de media**. Un clip trasero adicional dio `1920x1080` y 30,05 fps. Los registros de EIS3 corresponden a sesiones traseras. La estabilización del clip frontal de casi 60 fps sigue sin verificar.

El propietario grabó dos clips con la trasera (`cameraId=0`) de la Cámara de Xiaomi a 1080p30, uno en **ShootSteady** y otro en **Vídeo normal** con ShootSteady apagado. Ambos MP4 son H.264 de `1920x1080`, a 30,06 y 30,09 fps de media, respectivamente. Tres fotogramas decodificados de cada clip conservaron el color. En ambas sesiones, `cmd media.camera watch` registró `VIDEO_RECORD`, EIS `ON` y OIS `OFF` tanto en la solicitud como en el resultado. CamX registró `VideoEIS3PreviewEIS2Offline` y `com.qti.node.eisv311` para la cámara 0 en ambos modos. Vídeo normal trasero a 1080p30 queda como referencia stock para Aperture. La configuración interna que distingue ShootSteady y la ruta usada por la frontal siguen pendientes. [Especificaciones de Xiaomi](https://www.mi.com/ph/product/redmi-note-14-pro-plus-5g/specs/), [metadatos de Camera2](https://developer.android.com/reference/android/hardware/camera2/CaptureResult#CONTROL_VIDEO_STABILIZATION_MODE).

Los blobs `com.qti.eisv2.so` y `com.qti.eisv3.so` coinciden entre el dump de HyperOS Global 307 y el vendor `e5f5650`. Los nodos `com.qti.node.eisv2.so` y `com.qti.node.eisv3.so` conservan la sección `.text`. En las dependencias ELF, `extract-files.py` cambia `android.hardware.graphics.allocator-V1-ndk.so` por `android.hardware.graphics.allocator-V2-ndk.so` en ambos nodos. Este cambio es verificable por separado de la selección del pipeline. Su relación con el fallo de croma sigue sin comprobarse.

En LineageOS, ambos XML de perfiles de medios del tree declaran los perfiles normales `1080p` a 30 fps y no hay una ampliación de `config_additionalVideoConfigurations` para Aperture. El código de Aperture ofrece ese overlay para añadir FPS por ID de cámara y calidad. Los ajustes `is60fpsDynamicSupported` y `availableFrontMaxResolutions` de CamX no sustituyen esa configuración de la app. Para probar 1080p60 en LineageOS, valida primero la combinación `cameraId=1`, `fhd` y 60 fps, midiendo el MP4 y revisando el color con el workaround de EIS actual. La referencia del clip de stock solo verifica esa combinación en HyperOS. [Configuración de Aperture](https://github.com/LineageOS/android_packages_apps_Aperture/blob/a0b16a6/app/src/main/res/values/config.xml)

### Cámaras traseras de la variante Global

En HyperOS Global 307, el propietario tomó tres fotos en modo Foto, seleccionando 0,6×, 1× y Macro en ese orden. Los eventos de conexión de `com.android.camera` y los metadatos EXIF de cada JPEG identifican los tres módulos de este `24115RA8EG`.

| Selección en Xiaomi | ID abierto | Foto guardada | Distancia focal y apertura |
| --- | --- | --- | --- |
| 0,6×, ultra gran angular | `2` | 2464 × 3280 | 1,65 mm, f/2,2 |
| 1×, principal | `0` | 3060 × 4080 | 6,19 mm, f/1,65 |
| Macro | `3` | 1200 × 1600 | 2,02 mm, f/2,4 |

El HAL también declara el ID lógico `4`, que agrupa los físicos `2` y `0`. En el volcado de stock, la lista pública de la API antigua (API1) contiene `0`, `1` y `3`. Queda por medir qué IDs enumera CameraX para Aperture en LineageOS. La variante india incorpora un teleobjetivo de 2,5× y requiere su propia identificación. [Ficha Global](https://www.mi.com/global/product/redmi-note-14-pro-plus-5g/specs/), [ficha india](https://www.mi.com/in/product/redmi-note-14-pro-plus-5g/specs/).

En la revisión `a0b16a6` de Aperture, el selector `config_enableAuxCameras` vale `false` por defecto. En ese estado `CameraRepository` acepta los IDs internos `0` y `1`. La rama experimental `amethyst-307-aperture-aux` activa el selector y conserva el filtro predeterminado de cámaras lógicas auxiliares. En LineageOS, comprobar qué IDs enumera CameraX, abrir cada lente en modo Foto y verificar la focal del JPEG. Si falta el `2` o el `3`, revisar su exposición en el proveedor de cámara. El selector requiere validación en el Redmi Global. [Rama de prueba](https://github.com/Daxandere/android_device_xiaomi_amethyst/tree/amethyst-307-aperture-aux), [selección de cámaras en Aperture](https://github.com/LineageOS/android_packages_apps_Aperture/blob/a0b16a6bdf9a0f927307adfbcfa3a63cf72dd965/app/src/main/java/org/lineageos/aperture/repositories/CameraRepository.kt).

El 21 de noviembre se compiló `lineage-23.2-20261121-UNOFFICIAL-k307-aux-amethyst.zip` con el tree `3a8d323` y `TARGET_UNOFFICIAL_BUILD_ID=k307-aux`. La OTA declara `amethyst` y A/B. El ZIP y el recovery pasaron la comprobación SHA-256. Lineage Recovery registró el borrado de datos y aplicó la OTA con `status 0`. Ya en la ranura `b`, ADB verificó `sys.boot_completed=1` y que Aperture resuelve `config_enableAuxCameras=true`. El propietario tomó fotos con la principal, el ultra gran angular y el macro. [Commit del overlay](https://github.com/Daxandere/android_device_xiaomi_amethyst/commit/3a8d323ceb2b6152d765b654cfbe75adb27442aa).

Al elegir el macro en Vídeo, Aperture cierra la actividad. Se reprodujo por ADB. CamX registra `cameraId=3`, un máximo de `1600x1200` para el formato solicitado y el rechazo `-22` al configurar vídeo de `1920x1080`. El HAL anuncia un flujo de `1280x720` y un rango AE de `30–30 fps`. El XML multimedia activo anuncia 1080p y 2160p para ese ID. La rama experimental Global limita esos perfiles a 720p30 e incorpora la opción 1080p60 para la frontal (`1`). [Candidato Global `ed5ca6b`](https://github.com/Daxandere/android_device_xiaomi_amethyst/commit/ed5ca6b052746a0598bd66ee09ec607736201fac).

En `k307-aux`, el propietario seleccionó 720p en la principal y luego cambió al macro sin salir de Vídeo. Aperture abrió el ID `3` y guardó un MP4 H.264 de `1280x720`, 6,65 s y 30,24 fps de media. FFmpeg decodificó los 201 fotogramas sin errores.

Se compiló `lineage-23.2-20261121-UNOFFICIAL-k307-aux60-amethyst.zip` desde `ed5ca6b` con `TARGET_UNOFFICIAL_BUILD_ID=k307-aux60`. La OTA declara `amethyst`, A/B y el incremental `1795277115`. El XML empaquetado limita los perfiles del ID `3` a `1280x720` a 30 fps. `idmap2` confirmó que el overlay se asigna al selector de lentes y a la configuración de vídeo adicional de Aperture. El ZIP y el recovery pasaron SHA-256 en el servidor y en el PC.

Lineage Recovery aplicó `k307-aux60` como actualización sobre `k307-aux` y registró `status 0` para el incremental `1795277115`. ADB confirmó el arranque completo en la ranura `a`. En Android, el overlay está activo y Aperture resuelve `config_enableAuxCameras=true` y el perfil adicional `1/fhd/60`.

En la primera prueba frontal de `k307-aux60`, Aperture abrió el ID `1` y durante la sesión `VIDEO_RECORD` Camera2 registró la solicitud y el resultado AE de `60–60 fps`. El MP4 H.264 guardado mide `1920x1080`, 7,31 s y 59,61 fps de media. FFmpeg decodificó los 436 fotogramas sin errores.

Con `k307-aux60`, el propietario pasó de la principal configurada a 1080p al macro sin tocar la resolución. CameraService registró la desconexión del ID `0` y la apertura del ID `3`. Aperture guardó un MP4 H.264 de `1280x720`, 5,76 s y 30,05 fps de media. FFmpeg decodificó los 173 fotogramas sin errores. El cambio automático de resolución funcionó en el Redmi Global probado.

## Ramas, código y dependencias

- `lineage-23.2` integra bootconfig y fingerprint Global 307, políticas de audio y de StrongBox y Weaver, el kernel 6.1.138 y los ajustes de cámara validados en `k307-eis2diag`. El vendor de la misma rama instala una sola copia de cada perfil CamX. [Commits del device tree](https://github.com/Daxandere/android_device_xiaomi_amethyst/commits/lineage-23.2/).
- `amethyst-307-strongbox-init` añadió lectura de `boot_status_prop` y acceso a SystemSuspend para el HAL Thales. El propietario confirmó que la huella funciona incluso con la pantalla apagada en la configuración actual. [Cambio de StrongBox](https://github.com/Daxandere/android_device_xiaomi_amethyst/commit/910983cc26d241a8b0cafb841795360efd70fb99).
- `amethyst-307-eisfix` aplica el ajuste de Freebuff a partir de `910983c`. Usa juntos el device tree `beb1475f3b531f3c4c73802a497cb9b45b30fba9` y el vendor `b04d587808bf036a92cf00934c03ff6f16f13f53`. La rama del vendor quita del makefile la copia duplicada del archivo CamX. El fichero corregido se instala desde el device tree en `odm/etc/camera/camxoverridesettings.txt`. [Device para EIS](https://github.com/Daxandere/android_device_xiaomi_amethyst/tree/amethyst-307-eisfix), [vendor para EIS](https://github.com/Daxandere/proprietary_vendor_xiaomi_amethyst/tree/amethyst-307-eisfix).
- `amethyst-307-eisfix-global` incorpora el ajuste del perfil elegido por el Redmi Global. Usa juntos el device tree `358111a0bbba110f40e0266b721a24019932aa17` y el vendor `e5f565023760393a4909a787b75ef319de012225`. Las dos copias de `camxoverridesettings*.txt` se instalan desde el device tree. Esta rama reproduce el fallo con EIS activado. [Device para EIS Global](https://github.com/Daxandere/android_device_xiaomi_amethyst/tree/amethyst-307-eisfix-global), [vendor para EIS Global](https://github.com/Daxandere/proprietary_vendor_xiaomi_amethyst/tree/amethyst-307-eisfix-global).
- `amethyst-307-eis2diag` usa el device tree `bd3eaeedc3c4f3ec1317d06fe23e833616364264` con el mismo vendor Global `e5f5650`. El manifiesto fijó las demás revisiones del candidato Global. Kernel, DTB y DTBO coincidieron byte por byte. [Cambio diagnóstico](https://github.com/Daxandere/android_device_xiaomi_amethyst/commit/bd3eaeedc3c4f3ec1317d06fe23e833616364264).
- El vendor base sin el cambio de cámara es `57a9cc5a8c99f02f1b7d69a9b0dbe55e94c156e2`. Se reprodujeron las 17 diferencias auditadas de blobs mediante `FIX_SONAME`. El servicio Gatekeeper de Qualcomm, `libqtigatekeeper.so`, `libQSEEComAPI.so` y su RC coincidían con stock. [Vendor base](https://github.com/Daxandere/proprietary_vendor_xiaomi_amethyst/commit/57a9cc5a8c99f02f1b7d69a9b0dbe55e94c156e2).

## Reproducir el build

Clona el manifiesto local en `.repo/local_manifests` después de `repo init` y antes de `repo sync`. El manifiesto selecciona las ramas compatibles del device, vendor y kernel. Tras sincronizar, ejecuta `breakfast amethyst` y `m bacon` con el directorio `out` estándar. Usa `repo manifest -r` para registrar las revisiones exactas de tu compilación. [Guía de compilación](BUILD.md), [manifiesto local](https://github.com/Daxandere/local_manifests).

| Proyecto | Revisión |
| --- | --- |
| `device/xiaomi/amethyst-kernel` | `ac41a99bda91def578cf64371fc83798ed8bdd68`, kit Global 307 y headers de `f118e1d` |
| `hardware/xiaomi` | `57621c3dece8d7dfa33ee92c6ba346cb58db95d8` |
| `bootable/recovery` | `acd99f7c48e0229eaedd40aa3e2adcbabe2dc283` en los builds de prueba |
| `system/update_engine` | `fc83053aa2a71885ba8615da9946033adf3462ce` en los builds de prueba |

- El kernel publicado es `6.1.138-android14-11-g0c3d559bcd85-ab14529422`. Su SHA-256 es `97b2c53022e8c0bd0b279c4c592a196126a6eb0a93647c2957b39dcd5f2dc1c9`. La rama del kernel contiene también el DTBO, los DTBs y módulos de `vendor_boot`, `system_dlkm` y `vendor_dlkm`. [Kit Global 307](https://github.com/Daxandere/android_device_xiaomi_amethyst-kernel/tree/lineage-23.2-global307).
- El build integrado usa ese kit directamente desde `device/xiaomi/amethyst-kernel`. Los parches de staging de `BoardConfig.mk` y del host corresponden al historial de diagnóstico. Para instalar, combina el ZIP con el recovery extraído del mismo payload. [Guía de instalación](FLASH.md).

| Archivo verificado del candidato Global | SHA-256 |
| --- | --- |
| `lineage-23.2-20261120-UNOFFICIAL-k307-eisfix-global-amethyst.zip` | `f0cbd77588da1d9673611d15c16ac74616af5cdd092225a083c762151abf13b2` |
| `recovery.img` extraído de ese payload | `dbd9ff29478d45c2b2e2b04684e69c20fad75c9de59a89824fb4a1b2761954f9` |

| Archivo verificado del build diagnóstico | SHA-256 |
| --- | --- |
| `lineage-23.2-20261120-UNOFFICIAL-k307-eis2diag-amethyst.zip` | `2ddd2887a0d9691cbb0741903b77c148906bea11f9c98de16c512d6a2374a70b` |
| `recovery.img` extraído de ese payload | `3249cecc26b2856bc56f850622b25b6ee2b2a32a7ad028fa235513f2a868fc80` |

## Próxima prueba en el Redmi

1. Comprueba pantalla y conexión USB. Usa `adb devices -l` y `fastboot devices -l`. Si Fastboot enumera el dispositivo, registra `product`, `unlocked`, `current-slot`, `slot-successful:a`, `slot-successful:b`, `slot-retry-count:a`, `slot-retry-count:b` y `snapshot-update-status`. Una transferencia ADB exitosa se corrobora con `/tmp/recovery.log`, `status: 0` y el slot de destino.
2. Si arranca recovery tras el fallo, habilita ADB desde su menú avanzado. Copia `/tmp/recovery.log`, `/sys/fs/pstore` cuando haya registros y `/dev/block/by-name/oops` a la máquina de diagnóstico. En `oops`, busca el registro cuyo identificador de build y modo `normal` correspondan al intento. El registro anterior del fallo de `keystore2` estaba en `Boot_Index 1407`.
3. Si hace falta restablecer la base, el procedimiento de instalación limpia acordado para este teléfono es MiFlash **Clean all** con la imagen Global 307 exacta y el bootloader desbloqueado. Verifica que HyperOS llegue a Android. Usa el ZIP candidato verificado y recovery de su payload. El operador confirma los borrados y las escrituras en el dispositivo. Consulta los datos de slot y las consecuencias del fallback de Virtual A/B antes de intentar volver a otra ranura. [Guía de instalación](FLASH.md).
4. Confirma `ro.lineage.version`, `ro.boot.slot_suffix`, `sys.boot_completed=1` y un segundo arranque. Registra si Fastboot marca la ranura como exitosa cuando se consulte. Para huella, valida la confirmación del PIN, que empieza la captura y que una huella registrada puede desbloquear después del primer desbloqueo con PIN tras un reinicio. Si hay un fallo, guarda logs de Gatekeeper, Weaver, StrongBox y huella.
5. Para recuperar EIS a 1080p, compara el crop, el tamaño de entrada, el stride y el formato en IPE14 con una grabación equivalente de HyperOS 307. Usa `k307-eisfix-global` como referencia que reproduce el fallo y `k307-eis2diag` como control con el color correcto. Registra la solicitud de estabilización, el modo aplicado por CamX y el resultado del MP4 en cada sensor. Usa 720p y 4K como controles al probar cambios.

La cuenta del servidor, los registros sin filtrar, el kit de firmware y las rutas del PC se entregan por el canal privado del operador.
