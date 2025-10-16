## PROMPT – Construcción de un nuevo mapa GV (plantilla)

Objetivo: Generar un mapa interactivo tipo GV (búsqueda, filtros por categoría, overlay de resultados, menú de acciones, haptics) para un nuevo dominio de datos.

Instrucciones (rellena las secciones):

1) Modelo de datos
- Nombre del tipo: <NOMBRE_DEL_TIPO>
- Campos:
  - id (Int): identificador único
  - nombre (String): nombre a mostrar
  - latitude (Double?)
  - longitude (Double?)
  - categoriaId (Int?)
  - categoriaNombre (String?)
  - urlSitio (String?)

2) Fuente de datos
- ¿Usa SwiftData / API / ambos?
- Límite recomendado de resultados por fetch global: <N>
- ¿Se requiere búsqueda por nombre? Sí/No

3) Estilos de categoría
- ¿Existe catálogo de categorías local (Plist/JSON)? Sí/No
- Proveer mapping: categoriaId -> (color, icon)
- Si no hay id, mapping por nombre: categoriaNombre -> (color, icon)

4) UX requerida (marca las que aplican)
- [ ] Búsqueda por nombre con debounce
- [ ] Overlay de resultados ordenados por distancia
- [ ] Filtro multi-selección por categoría (lista dinámica según resultados)
- [ ] Menú de acciones por pin/resultado (Ir, Ruta, Promos, Sitio web, Favoritos)
- [ ] Resaltado del pin seleccionado + haptics
- [ ] Overlays de carga/sin resultados
- [ ] Estilos de mapa (2D/3D/Sat/Híbrido)

5) Parámetros de rendimiento (opcional – si no, usar valores del plist)
- DebounceTime mapa: <seg>
- SearchDebounceTime: <seg>
- SearchMaxResults: <N>
- SearchFetchLimit: <N>
- ThresholdCenterFactor / SpanLat / SpanLon: <0.xx>
- TileCacheTTLSeconds / TileGridBaseDegrees: <seg> / <grados>
- AdaptiveFetch (WideLatDelta, MediumLatDelta, WideLimit, MediumLimit, CloseLimit): <valores>

6) Integraciones
- Acciones al seleccionar (deeplinks adicionales): <describir>
- Telemetría adicional: <eventos>

7) Resultado esperado
- Crear una vista basada en `GV_GreatMap_Template` o una variante concreta.
- Implementar `GVMapEntity` para el modelo.
- Implementar `GVMapDataProvider` para fetch en región y búsqueda.
- Implementar `GVCategoryStyler` para color/ícono por categoría.
- Conectar valores del plist `GV_MisConfiguracionesGenerales.plist`.

Ejemplo de invocación rápida:

"""
Quiero un mapa GV para "Sucursales de Bancos".
Modelo: `BancoSucursal` con id:Int, nombre:String, latitude:Double?, longitude:Double?, categoriaId:Int?, categoriaNombre:String?, urlSitio:String?
Datos: SwiftData con tabla `BancoSucursalModel`, y API de búsqueda.
Categorías: JSON local `CategoriasBancos.json` con color/icon por id.
UX: todo marcado salvo Sitio web.
Performance: SearchMaxResults=20, SearchFetchLimit=800.
Genera código conectando la plantilla y un `DataProvider` adaptado.
"""



