## Documentación de configuración: `GV_MisConfiguracionesGenerales.plist`

Este documento describe cada una de las propiedades disponibles en el plist de configuraciones generales, su propósito, valores recomendados y notas de uso. Todas las claves están organizadas por secciones (Mapa, Ubicación y General).

### Mapa

- **RadioCentradoUsuario_KM**
  - Qué es: Radio en kilómetros para el zoom al centrar el mapa en la ubicación del usuario.
  - Tipo: real (Double)
  - Recomendado: 3.0 – 8.0 (por defecto 5.0)
  - Impacto: Afecta el `latitudeDelta` calculado al centrar en usuario.

- **ZoomUsuario_LatitudeDelta**
  - Qué es: `latitudeDelta` a usar cuando se centra en el usuario si no se usa el radio en km.
  - Tipo: real (Double)
  - Recomendado: 0.02 – 0.08 (por defecto 0.05)
  - Impacto: Controla el nivel de detalle al centrar en usuario.

- **ZoomMexico_LatitudeDelta**
  - Qué es: `latitudeDelta` para mostrar una vista amplia de México.
  - Tipo: real (Double)
  - Recomendado: 12.0 – 18.0 (por defecto 15.0)

- **MaxEstablecimientosVisibles**
  - Qué es: Tope visual aproximado de establecimientos (referencial para UI).
  - Tipo: entero (Int)
  - Recomendado: 100 – 250 (por defecto 150)

- **MaxEstablecimientosFetch**
  - Qué es: Límite base de fetch para lazy loading (puede ser reemplazado por el fetch adaptativo).
  - Tipo: entero (Int)
  - Recomendado: 200 – 400 (por defecto 300)

- **RegionBuffer**
  - Qué es: Buffer en grados alrededor del viewport para precargar puntos cercanos.
  - Tipo: real (Double)
  - Recomendado: 0.02 – 0.10 (por defecto 0.05)
  - Impacto: A mayor buffer, más carga pero menos “pop-in” en bordes.

- **DebounceTime**
  - Qué es: Tiempo de debounce (segundos) para recargas al mover la cámara.
  - Tipo: real (Double)
  - Recomendado: 0.25 – 0.5 (por defecto 0.3)

- **SearchDebounceTime**
  - Qué es: Debounce de la barra de búsqueda (segundos).
  - Tipo: real (Double)
  - Recomendado: 0.3 – 0.5 (por defecto 0.35)

- **SearchMinChars**
  - Qué es: Mínimo de caracteres para activar búsqueda.
  - Tipo: entero (Int)
  - Recomendado: 1–2 (por defecto 1)

- **SearchMaxResults**
  - Qué es: Máximo de resultados a mostrar en el overlay de búsqueda (ordenados por distancia).
  - Tipo: entero (Int)
  - Recomendado: iPhone 20 (por defecto 20), iPad 30.

- **SearchFetchLimit**
  - Qué es: Límite de fetch global para búsqueda por nombre.
  - Tipo: entero (Int)
  - Recomendado: 800 – 1500 (por defecto 1000)
  - Nota: Valores muy altos afectan performance.

- **HighlightDuration**
  - Qué es: Duración (seg.) del resaltado del pin seleccionado antes de desvanecer.
  - Tipo: real (Double)
  - Recomendado: 0.8 – 1.5 (por defecto 1.2)

- **HighlightFadeDuration**
  - Qué es: Duración (seg.) del fade-out del resaltado del pin.
  - Tipo: real (Double)
  - Recomendado: 0.2 – 0.6 (por defecto 0.4)

- **ActionMenuDelay**
  - Qué es: Retardo (seg.) para abrir el menú de acciones después de centrar el mapa.
  - Tipo: real (Double)
  - Recomendado: 0.1 – 0.3 (por defecto 0.2)

- **ThresholdCenterFactor**
  - Qué es: Factor (fracción del `latitudeDelta`) para determinar si el movimiento del centro amerita recarga.
  - Tipo: real (Double)
  - Recomendado: 0.08 – 0.15 (por defecto 0.10)

- **ThresholdSpanFactorLat**
  - Qué es: Umbral para cambios en `latitudeDelta` que disparan recarga.
  - Tipo: real (Double)
  - Recomendado: 0.08 – 0.15 (por defecto 0.10)

- **ThresholdSpanFactorLon**
  - Qué es: Umbral para cambios en `longitudeDelta` que disparan recarga.
  - Tipo: real (Double)
  - Recomendado: 0.08 – 0.15 (por defecto 0.10)

- **TileCacheTTLSeconds**
  - Qué es: Tiempo de vida del caché de región (en segundos) para evitar refetch al panear cerca.
  - Tipo: entero (Int)
  - Recomendado: 120 – 600 (por defecto 300)

- **TileGridBaseDegrees**
  - Qué es: Granularidad del “tile” en grados para la clave de caché (centro/span redondeados a este múltiplo).
  - Tipo: real (Double)
  - Recomendado: 0.10 – 0.30 (por defecto 0.20)
  - Impacto: Cuanto mayor, más cache hits, pero menor precisión por zoom.

- **AdaptiveFetch_WideLatDelta / AdaptiveFetch_MediumLatDelta**
  - Qué es: Umbrales de `latitudeDelta` que separan los modos de zoom (amplio/medio/cercano).
  - Tipo: real (Double)
  - Recomendado: 8–14 (wide), 3–6 (medium)

- **AdaptiveFetch_WideLimit / AdaptiveFetch_MediumLimit / AdaptiveFetch_CloseLimit**
  - Qué es: Límite de fetch según nivel de zoom (ancho/medio/cercano).
  - Tipo: entero (Int)
  - Recomendado: 120 / 220 / 300 (por defecto 120/220/300)
  - Impacto: Reduce carga cuando el zoom es amplio.

- **ClusteringActivado, ClusterRadius, MinClusterSize**
  - Qué es: Parámetros para clustering (actualmente no activo en esta versión del mapa).
  - Nota: Reservado para futura implementación con `MKMapView`.

### Ubicación

- **MinMovimientoMetros**
  - Qué es: Distancia mínima (m) para considerar una actualización de ubicación.
  - Tipo: real (Double)
  - Recomendado: 10 – 50 (por defecto 20)

- **MinIntervaloSegundos**
  - Qué es: Intervalo mínimo (s) entre actualizaciones de ubicación.
  - Tipo: real (Double)
  - Recomendado: 1 – 5 (por defecto 2)

- **TamanoCacheUbicaciones**
  - Qué es: Tamaño del caché de ubicaciones en memoria.
  - Tipo: entero (Int)
  - Recomendado: 50 – 200 (por defecto 100)

### General

- **Version**
  - Qué es: Versión de las configuraciones.
  - Tipo: string

- **ModoDebug**
  - Qué es: Activa logs detallados y mensajes de depuración.
  - Tipo: boolean
  - Recomendado: `false` en producción.

- **Idioma**
  - Qué es: Idioma de la app (por ahora informativo; la UI usa localización del sistema).
  - Tipo: string (`es`, `en`, etc.)

---

### Buenas prácticas para ajustar valores

- Empieza con los valores por defecto y ajusta gradualmente según el rendimiento en dispositivo real.
- Si notas “saltos” de recarga al panear poco, incrementa ligeramente `ThresholdCenterFactor` y los umbrales de span.
- Si la búsqueda se siente pesada, reduce `SearchFetchLimit` o `SearchMaxResults` y aumenta `SearchDebounceTime`.
- Si el mapa carga demasiados puntos con zoom amplio, usa límites más bajos en `AdaptiveFetch_WideLimit` y sube `AdaptiveFetch_WideLatDelta`.
- Ajusta `TileGridBaseDegrees` para balancear precisión vs cache hits; eleva `TileCacheTTLSeconds` si panéas mucho en un área.

### Ejemplo de cambios típicos

```plist
<key>SearchMaxResults</key>
<integer>30</integer>
<key>AdaptiveFetch_WideLimit</key>
<integer>100</integer>
<key>ThresholdCenterFactor</key>
<real>0.12</real>
```

Estos cambios aumentan resultados en iPad, reducen carga en zoom amplio y suavizan recargas por micro-pan.



