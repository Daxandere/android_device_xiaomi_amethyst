# Ramas del árbol y pendientes

Estado de este documento: rama `amethyst-23.2-rc1` (candidato de publicación 1,
23 de noviembre de 2026). El árbol estable para compilar y probar es esa rama:
une el power HAL `libperfmgr`, los ajustes de pantalla y las correcciones de
cámara. Las ramas de experimentación se conservan tal cual para retomarlas.

## Ramas vivas

| Rama | Último commit | Contenido | Estado |
|---|---|---|---|
| `amethyst-23.2-rc1` | `23b71bf` | `lineage-23.2` + power HAL con boosts + rango de refresco 60–120 Hz por defecto + cámara/EIS + macro 720p + overlay de Aperture | **estable, compilar aquí** |
| `exp/refresh-rate-switches` | `76029f1` | Base del RC: power HAL, rango 60–120 Hz, A/B de jank a 120 Hz | integrada en el RC; se conserva como historial de la medición |
| `exp/perf-hints` | `4a66a91` | Primer intento del boost de GPU al componer blur | absorbida por el RC |
| `build-shade24-power` | `5073da7` | Primer build con barra de 24 dp y `libperfmgr` | superada por el RC |
| `lineage-23.2` (`mine/lineage-23.2`) | `5febb8c` | Base estable anterior, sin power HAL ni RC | sólo como referencia |

## Ramas experimentales de cámara (no borrar)

Se conservan porque son los controles de los dos fallos abiertos y porque el
servidor de compilación no tiene credenciales de GitHub para recrearlas.

| Rama | Último commit | Qué fija | Para qué sirve |
|---|---|---|---|
| `amethyst-307-eisfix` | `beb1475` | Perfil CamX con `is3rdEISV2Enabled=FALSE` y sin entradas de 1080p | Control «sin EIS»: color correcto a 1080p |
| `amethyst-307-eisfix-global` | `358111a` | Lo mismo aplicado al perfil Global | Reproduce el fallo con EIS activado |
| `amethyst-307-eis2diag` | `bd3eaee` | Diagnóstico con EIS2 de terceros desactivado | Control con color correcto a 720p y 4K |
| `amethyst-307-strongbox-init` | `910983c` | Políticas StrongBox y Weaver con acceso a `boot_status_prop` y SystemSuspend | Integrada en `lineage-23.2` |
| `amethyst-307-strongbox` | `8c0d868` | Etiquetas SELinux del HAL Thales | Integrada en `lineage-23.2` |
| `amethyst-307-bootfix` | `27de9b2` | Kit de arranque y firmware Global 307 | Integrada en `lineage-23.2` |
| `amethyst-307-bootfix-validation` | `a10f01f` | Validación del arranque con el kit Global 307 | Integrada en `lineage-23.2` |

### Respaldo remoto `aperture-backup/*`

En `waffle` estos commits existen también como referencias del remoto
`aperture-backup`, es decir, ramas del repositorio de GitHub. Son la única copia
de los experimentos de Aperture fuera de este árbol:

| Rama | Último commit | Contenido |
|---|---|---|
| `amethyst-307-aperture-aux` | `3a8d323` | Overlay que activa el selector de lentes auxiliares |
| `amethyst-307-aperture-aux60-global` | `ed5ca6b` | Macro limitada a 720p y frontal 1080p60 |
| `amethyst-307-aperture-main60-global` | `b211d0c` | Principal trasera 1080p60 |
| `amethyst-307-eis3-global` | `1b4e500` | EIS3 con el EIS2 de terceros desactivado |
| `amethyst-307-eisstock-main60-global` | `a03757d` | Perfiles CamX de stock sobre el build `main60` |

## Cómo retomar una rama

```bash
cd /serverhive5/daxandere/android/lineage-23.2/device/xiaomi/amethyst
git checkout <rama>
cd /serverhive5/daxandere/android/lineage-23.2
breakfast amethyst
TARGET_UNOFFICIAL_BUILD_ID=<etiqueta> m bacon
```

El detalle de cada prueba de hardware está en [HANDOFF-307.md](HANDOFF-307.md)
(cámara, arranque, StrongBox) y en
[DISPLAY-TESTING.md](DISPLAY-TESTING.md) (refresco, blur, nodos de rendimiento).
El arnés de medición de jank vive en `docs/jank/`.

## Compilar el RC

```bash
cd /serverhive5/daxandere/android/lineage-23.2/device/xiaomi/amethyst
git checkout amethyst-23.2-rc1
cd /serverhive5/daxandere/android/lineage-23.2
. build/envsetup.sh
breakfast amethyst
TARGET_UNOFFICIAL_BUILD_ID=rcd1 m -j32 bacon
```

Con el `out/` de un build anterior, la compilación incremental tarda menos de
seis minutos. Produce
`out/target/product/amethyst/lineage-23.2-20261123-UNOFFICIAL-rcd1-amethyst.zip`,
2 083 623 970 B, SHA-256
`676c8c068716ccc0daa9489778533273cd31b9b4c76534ef0cad9210231016b7`, que es el
build probado en el dispositivo (`ro.build.version.incremental=1795395067`). Un
`out/` limpio exige la compilación completa. La etiqueta cambia el nombre del
ZIP, no su contenido.

El rango de arranque ya no se ajusta a mano: `config_defaultPeakRefreshRate`
ships 120, así que un dispositivo recién borrado arranca en 60–120 Hz. No subir
`config_defaultRefreshRate` por encima de 0: ese valor se convierte en un tope de
render a esa frecuencia.

## Pendientes abiertos

### 1. 2160p con el lente 0.7× cierra Aperture

Con el vídeo en 2160p, al pulsar `0.7×` Aperture termina su actividad: el mapa
de flujos del sensor ultra gran angular no tiene `3840x2160` (su mayor 16:9 es
`3200x1800`) y Camera2 rechaza la sesión. Limitar los perfiles del XML
multimedia a 1080p **no** lo arregla: CameraX construye la lista de calidades
con `Recorder.getVideoCapabilities`, no con `/vendor/etc/media_profiles*.xml`.
No se debe volver a aplicar ese límite sin una medición nueva. Hipótesis
pendiente: filtrar los tamaños soportados en Aperture a partir de
`SCALER_STREAM_CONFIGURATION_MAP`, o exponer un mapa de 4K coherente en el HAL.
La reproducción completa está en
[HANDOFF-307.md](HANDOFF-307.md#2160p-con-el-lente-07-cierra-aperture).

### 2. Croma corrupto a 1080p con EIS2

El RC activa el EIS2 de terceros con el perfil de stock, que vuelve a declarar
`6@30` y `6@60` en `vsquality`. Esa combinación **nunca se probó a 1080p**: las
pruebas anteriores corrían con un perfil que no declaraba 1080p mientras el EIS
se forzaba. Primer paso al probar el RC: grabar 1080p30 con la estabilización
activa y revisar el color. Si el croma falla, desactivar la estabilización en
Aperture devuelve el color correcto (EIS sólo a 720p y 4K). Pista abierta: el
`IPE14` mantiene `m_previewDimension` en `1600x1200` durante la sesión de 1080p.

### 3. Boost de blur sin emisor

`configs/power/powerhint.json` incluye la acción `EXPENSIVE_RENDERING`, pero
SurfaceFlinger nunca emite ese hint en este build, así que el boost no se
ejecuta nunca. No hay nada que medir hasta que SF lo emita.

### 4. Arnés de jank

`docs/jank/ab_probe.sh` con `probe.pbtxt` y `pacing_settings.sql` mide la
cadencia de `Choreographer#doFrame*` a 120 Hz. El A/B ya registrado no encontró
diferencia entre el perfil con boosts y sin ellos (1,3 % de frames tardíos en
ambos), por eso el RC conserva los boosts pero no se apoya en esa medición para
justificarlos.
