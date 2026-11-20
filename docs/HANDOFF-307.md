# Relevo de amethyst con HyperOS Global 307

Actualizado el 20 de noviembre de 2026. Dispositivo de pruebas Redmi Note 14 Pro+ 5G Global, modelo `24115RA8EG`, producto Fastboot `amethyst`, bootloader desbloqueado. Base HyperOS `OS3.0.307.0.WOPMIXM` y LineageOS 23.2.

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

El error de cámara se observó en archivos grabados. En la cámara trasera dominaba el cian y en la frontal aparecían zonas naranja y azul. El nodo `VideoEIS2PreviewEIS2Offline_IPE14` reportó un crop de `2400x1800` sobre una entrada de `1920x1440`. El ajuste de Freebuff retira `6@30` y `6@60` de `vsquality`, dejando `5@30|8@30|8@60|3001@24`.

En el Redmi, ADB leyó `ro.boot.camera.config=1`, `ro.boot.hwc=GL` y `ro.product.mod_device=amethyst_global`. El perfil `odm/etc/camera/mihal_overlap/proj_overlap_config_1.json` apunta a `camxoverridesettings_global.txt`. En `k308-eisfix`, solo se modificó el archivo genérico. El Global todavía contiene `6@30|6@60` y el log conserva el pipeline EIS2. El cambio siguiente apunta al perfil seleccionado. Hay que verificar el color y la estabilización con los archivos del nuevo build.

El operador confirmó color correcto a 1080p en **la cámara trasera y la frontal** al apagar **Habilitar estabilización de vídeo** en Aperture. Con este ajuste se puede seguir grabando a 1080p. La prueba del perfil Global se hizo con el interruptor activado.

La prueba del candidato Global confirmó que quitar `6@30|6@60` de ambos archivos CamX tampoco evita EIS2 offline cuando Aperture solicita estabilización. Los dos MP4 de la prueba se verificaron como H.264, `1920x1080`, a unos 30 fps. El log registró `ControlVideoStabilizationMode 1 EISMode:1 hasVideo:1` y, para ambos sensores, el mismo error de `VideoEIS2PreviewEIS2Offline_IPE14` con crop de `2400x1800` sobre `1920x1440`. Se corroboró la corrupción del color en un fotograma extraído del MP4 trasero. 720p y 4K quedan como controles para el siguiente cambio.

## Ramas, código y dependencias

- `lineage-23.2` incorpora el ajuste de bootconfig y fingerprint a Global 307, la limpieza de duplicados de audio, las instrucciones de recovery dedicado y las etiquetas SELinux de StrongBox y Weaver. Los commits de código son `c5c6f40`, `27de9b2` y `8c0d868`. [Commits del device tree](https://github.com/Daxandere/android_device_xiaomi_amethyst/commits/lineage-23.2/).
- `amethyst-307-strongbox-init` añade lectura de `boot_status_prop` y acceso a SystemSuspend para el HAL Thales. La rama conserva el commit `910983cc26d241a8b0cafb841795360efd70fb99`. Las denegaciones registradas coincidían con permisos presentes en la política stock, y queda por registrar el resultado específico de inscripción y desbloqueo con huella. [Cambio de StrongBox](https://github.com/Daxandere/android_device_xiaomi_amethyst/commit/910983cc26d241a8b0cafb841795360efd70fb99).
- `amethyst-307-eisfix` aplica el ajuste de Freebuff a partir de `910983c`. Usa juntos el device tree `beb1475f3b531f3c4c73802a497cb9b45b30fba9` y el vendor `b04d587808bf036a92cf00934c03ff6f16f13f53`. La rama del vendor quita del makefile la copia duplicada del archivo CamX. El fichero corregido se instala desde el device tree en `odm/etc/camera/camxoverridesettings.txt`. [Device para EIS](https://github.com/Daxandere/android_device_xiaomi_amethyst/tree/amethyst-307-eisfix), [vendor para EIS](https://github.com/Daxandere/proprietary_vendor_xiaomi_amethyst/tree/amethyst-307-eisfix).
- `amethyst-307-eisfix-global` incorpora el ajuste del perfil elegido por el Redmi Global. Usa juntos el device tree `358111a0bbba110f40e0266b721a24019932aa17` y el vendor `e5f565023760393a4909a787b75ef319de012225`. Las dos copias de `camxoverridesettings*.txt` se instalan desde el device tree. La prueba de grabación en hardware sigue pendiente. [Device para EIS Global](https://github.com/Daxandere/android_device_xiaomi_amethyst/tree/amethyst-307-eisfix-global), [vendor para EIS Global](https://github.com/Daxandere/proprietary_vendor_xiaomi_amethyst/tree/amethyst-307-eisfix-global).
- El vendor base sin el cambio de cámara es `57a9cc5a8c99f02f1b7d69a9b0dbe55e94c156e2`. Se reprodujeron las 17 diferencias auditadas de blobs mediante `FIX_SONAME`. El servicio Gatekeeper de Qualcomm, `libqtigatekeeper.so`, `libQSEEComAPI.so` y su RC coincidían con stock. [Vendor base](https://github.com/Daxandere/proprietary_vendor_xiaomi_amethyst/commit/57a9cc5a8c99f02f1b7d69a9b0dbe55e94c156e2).

## Reproducir el build

El manifiesto local habitual fija ramas y el manifiesto de cada compilación generado con `repo manifest -r` fija las revisiones exactas. Para el candidato Global selecciona su par de commits tras sincronizar. Los repositorios principales del build que arrancó fueron los siguientes. [Manifiestos locales](https://github.com/Daxandere/local_manifests).

| Proyecto | Revisión |
| --- | --- |
| `device/xiaomi/amethyst-kernel` | `f118e1dbd36c0446ad9f2d20f4690618d3ccb816` para los headers |
| `hardware/xiaomi` | `57621c3dece8d7dfa33ee92c6ba346cb58db95d8` |
| `bootable/recovery` | `acd99f7c48e0229eaedd40aa3e2adcbabe2dc283` |
| `system/update_engine` | `fc83053aa2a71885ba8615da9946033adf3462ce` |

1. Monta el kit de Global 307 con kernel `6.1.138-android14-11-g0c3d559bcd85-ab14529422`, DTBs, DTBO y módulos de `vendor_boot`, `system_dlkm` y `vendor_dlkm`. Verifica el manifiesto SHA-256 y aplica el parche de staging de `BoardConfig.mk`. El checkout de headers conserva su ruta original. El hash del kernel del kit es `97b2c53022e8c0bd0b279c4c592a196126a6eb0a93647c2957b39dcd5f2dc1c9`.
2. Usa el directorio `out` habitual. Los intentos con un `OUT_DIR` alterno fallaron en `libipanat` por la ubicación de `linux/msm_ipa.h`. El parche temporal de host de Freebuff quedó respaldado y se revirtió para la variante con el kit 307.
3. Compila `m libipanat` antes de `m bacon`. Comprueba VINTF, AVB con la clave de prueba de la compilación, el listado de particiones del payload y los SHA-256 del ZIP y del recovery extraído de ese mismo payload. Comprueba también las etiquetas de StrongBox y Weaver y el contenido de CamX dentro de ODM.
4. El kernel de `k308-eisfix` tiene hash `6144d19de9c1f1915819b53fcb05424ee283a2f6b0dea725f4a05c1934974d61`, igual al prebuilt 6.1.118 del checkout. El DTB de `vendor_boot` y el DTBO difieren de los del kit 307. El recovery descargable de `k308-eisfix` también difiere del recovery de su payload. El equipo inició Android tras el reinicio manual desde Fastboot.

| Archivo verificado del candidato Global | SHA-256 |
| --- | --- |
| `lineage-23.2-20261120-UNOFFICIAL-k307-eisfix-global-amethyst.zip` | `f0cbd77588da1d9673611d15c16ac74616af5cdd092225a083c762151abf13b2` |
| `recovery.img` extraído de ese payload | `dbd9ff29478d45c2b2e2b04684e69c20fad75c9de59a89824fb4a1b2761954f9` |

## Próxima prueba en el Redmi

1. Comprueba pantalla y conexión USB. Usa `adb devices -l` y `fastboot devices -l`. Si Fastboot enumera el dispositivo, registra `product`, `unlocked`, `current-slot`, `slot-successful:a`, `slot-successful:b`, `slot-retry-count:a`, `slot-retry-count:b` y `snapshot-update-status`. Una transferencia ADB exitosa se corrobora con `/tmp/recovery.log`, `status: 0` y el slot de destino.
2. Si arranca recovery tras el fallo, habilita ADB desde su menú avanzado. Copia `/tmp/recovery.log`, `/sys/fs/pstore` cuando haya registros y `/dev/block/by-name/oops` a la máquina de diagnóstico. En `oops`, busca el registro cuyo identificador de build y modo `normal` correspondan al intento. El registro anterior del fallo de `keystore2` estaba en `Boot_Index 1407`.
3. Si hace falta restablecer la base, el procedimiento de instalación limpia acordado para este teléfono es MiFlash **Clean all** con la imagen Global 307 exacta y el bootloader desbloqueado. Verifica que HyperOS llegue a Android. Usa el ZIP candidato verificado y recovery de su payload. El operador confirma los borrados y las escrituras en el dispositivo. Consulta los datos de slot y las consecuencias del fallback de Virtual A/B antes de intentar volver a otra ranura. [Guía de instalación](FLASH.md).
4. Confirma `ro.lineage.version`, `ro.boot.slot_suffix`, `sys.boot_completed=1` y un segundo arranque. Registra si Fastboot marca la ranura como exitosa cuando se consulte. Para huella, valida la confirmación del PIN, que empieza la captura y que una huella registrada puede desbloquear después del primer desbloqueo con PIN tras un reinicio. Si hay un fallo, guarda logs de Gatekeeper, Weaver, StrongBox y huella.
5. Para el siguiente experimento, comprueba si desactivar solo `is3rdEISV2Enabled` en ambos perfiles cambia el pipeline cuando la app solicita EIS. El flag tiene alcance más amplio que 1080p. Prueba 1080p30 en ambas cámaras y conserva 720p y 4K como controles. Si el objetivo es mantener EIS a 1080p, compara el crop, el tamaño de entrada y el formato en IPE14 con los de una grabación 1080p de HyperOS 307. Conserva los MP4 originales y los logs de CamX de cada caso.

La cuenta del servidor, los registros sin filtrar, el kit de firmware y las rutas del PC se entregan por el canal privado del operador.
