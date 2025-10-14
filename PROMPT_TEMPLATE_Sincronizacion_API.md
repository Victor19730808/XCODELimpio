# 🚀 PROMPT TEMPLATE: Sistema de Sincronización API ↔ Base de Datos Local

## 📋 INSTRUCCIONES PARA EL ASISTENTE

Necesito crear un nuevo sistema de sincronización para **[NOMBRE_ENTIDAD]** siguiendo exactamente la misma arquitectura y patrones de `GV_ep_Establecimientos`.

---

## 🎯 ESPECIFICACIONES DEL NUEVO SISTEMA

### 1. INFORMACIÓN BÁSICA

**Nombre de la Entidad:** `[EJEMPLO: Promociones, Eventos, Usuarios, etc.]`

**Endpoint Base:** `[EJEMPLO: https://api.ejemplo.com/api/evento/1/promociones]`

**Descripción:** `[EJEMPLO: Sistema para sincronizar promociones de establecimientos desde el API a la base de datos local]`

---

### 2. ESTRUCTURA DE DATOS DEL API

**Campos que retorna el endpoint:**

```json
{
  "campo_id": 12345,
  "campo_nombre": "Ejemplo",
  "campo_opcional": "Valor",
  "campo_numerico": 100,
  "campo_fecha": "2025-01-11",
  // ... agregar todos los campos del API
}
```

**Campos obligatorios (no pueden ser null):**
- `campo_id` (Int) - Identificador único
- `campo_nombre` (String)
- `[Listar todos los campos obligatorios]`

**Campos opcionales (pueden ser null):**
- `campo_opcional` (String?)
- `campo_numerico` (Int?)
- `[Listar todos los campos opcionales]`

---

### 3. VALORES POR DEFECTO PARA IMPUTACIÓN

Cuando un campo venga vacío o null desde el API, imputar:

**Para campos String:**
- Valor por defecto: `"vg_strVacio"`

**Para campos Int:**
- Valor por defecto: `-197308081`

**Para campos Double:**
- Valor por defecto: `-197308081.0`

**Para campos Date:**
- Valor por defecto: `Date(timeIntervalSince1970: 0)` // 1 enero 1970

**Para campos Bool:**
- Valor por defecto: `false`

---

### 4. REGLAS DE NEGOCIO ESPECÍFICAS

**Campo único (Primary Key):**
- Campo: `[EJEMPLO: promocion_id]`
- Tipo: `Int`
- Debe ser único en la base de datos

**Relaciones con otras entidades:**
- `[EJEMPLO: establecimiento_id -> GV_modeloCont_Establecimientos]`
- `[EJEMPLO: categoria_id -> GV_Categoria]`

**Validaciones especiales:**
- `[EJEMPLO: La fecha_fin debe ser mayor que fecha_inicio]`
- `[EJEMPLO: El descuento debe estar entre 0 y 100]`

---

### 5. CONFIGURACIÓN DE ENUMERACIONES

**Modo de Carga (ModoCargaBD):**
- `.full` - Borrar todo y cargar nuevo (usar por defecto)
- `.add` - Solo agregar, permite duplicados
- `.inc` - Incremental, actualizar existentes + insertar nuevos

**Orden de Resultados (OrdenResultados):**
- `.asc` - Ascendente por `[campo_id]`
- `.desc` - Descendente por `[campo_id]`

**Tipo de Regreso (TipoRegreso):**
- `.id` - Solo IDs
- `.full` - Todos los campos en formato CSV

---

### 6. FORMATO DE SALIDA CSV (para Get_[Entidad])

**Para `.full`:**
```
Numerador. ID, Campo1, Campo2, Campo3, Campo4
```

**Ejemplo:**
```
1. 12345, Promoción 1, 50%, 2025-01-01, 2025-12-31
2. 12346, Promoción 2, 30%, 2025-02-01, 2025-11-30
```

**Campos a incluir en el CSV:**
1. `[campo_id]`
2. `[campo_nombre]`
3. `[campo_importante_1]`
4. `[campo_importante_2]`
5. `[campo_importante_3]`

---

### 7. ESTRUCTURA DE ARCHIVOS A CREAR

**Carpeta:** `limpioCS/GV_adm_[NombreEntidad]/`

**Archivos:**

1. **`GV_SistemaCompleto_[NombreEntidad].swift`**
   - Modelo SwiftData: `GV_modeloCont_[NombreEntidad]`
   - Clase de sincronización: `GV_ep_[NombreEntidad]`
   - Extensión URLSession (si no existe)
   - Vista de prueba: `GB_test_GV_ep_[NombreEntidad]View`

2. **`GV_VistaSimple_Test_[NombreEntidad].swift`**
   - Vista de administración simplificada
   - Botones para todas las operaciones
   - Panel de resultados

---

## 🔧 MÉTODOS REQUERIDOS

### Métodos Públicos:

1. **`Load_API_Stream_[NombreEntidad]V`**
   - Parámetros: `xEndPoint: String`, `xNo: Int`
   - Retorna: `(resultado: String, codigoError: Int)`
   - Función: Carga JSON desde API con validación

2. **`Load_Stream_BDL`**
   - Parámetros: `xStream: String`, `flagIncremental: ModoCargaBD`
   - Retorna: `(resultado: String, codigoError: Int)`
   - Función: Carga JSON a BD con modo seleccionado
   - Reporte en 4 partes: Resumen, Lista CSV, Duplicados, Errores

3. **`Get_[NombreEntidad]`**
   - Parámetros: `xNo: Int`, `incDec: OrdenResultados`, `cRegresa: TipoRegreso`
   - Retorna: `(resultado: String, codigoError: Int)`
   - Función: Consulta BD con formato CSV simple

4. **`Limpiar_BaseDatos`**
   - Parámetros: Ninguno
   - Retorna: `(resultado: String, codigoError: Int)`
   - Función: Elimina todos los registros

### Métodos Privados:

1. **`crear[NombreEntidad]DesdeJSON`**
   - Crea instancia del modelo desde JSON
   - Valida campo único obligatorio

2. **`actualizar[NombreEntidad]`**
   - Actualiza registro existente con datos JSON

3. **`obtenerFechaFormateada`**
   - Retorna fecha en formato `ddMMyy HH:mm:ss`

---

## 📊 CÓDIGOS DE ERROR

- **`0`** = Éxito total
- **`-1`** = Error fatal (operación falló completamente)
- **`-2`** = Error parcial (algunos registros fallaron, proceso continuó)

**Formato de mensaje de error:**
```
"Descripción del error, 
 número sistema del error (1001, 1002, etc.), 
 número de [campo_id] donde ocurrió el error, 
 fecha y hora (ddMMyy HH:mm:ss),
 nombre de archivo: GV_SistemaCompleto_[NombreEntidad].swift, 
 función: [nombreMetodo]"
```

---

## 🎨 VISTA DE ADMINISTRACIÓN

La vista debe incluir:

### Header:
- Título: "Carga y Consulta"
- Subtítulo: "Sistema de sincronización"
- Contador: "📊 BD: X registros"

### Secciones:

1. **💾 CARGAR BD**
   - Barra de progreso (actualiza cada 1%)
   - Campo de texto para número de registros
   - Botón "Cargar X [Entidad]" o "Cargar TODOS"

2. **🔧 ADMINISTRACIÓN**
   - **📡 API:** Botones Raw, Valid
   - **💾 BDL:** Botones Full, Add, Inc
   - **🔍 QUERIES:** Botones para todas las combinaciones
     - ASC IDs (5)
     - DESC IDs (5)
     - ASC Full (10)
     - DESC Full (10)
   - **⚙️ ADMIN:** Botones Limpiar BD, Limpiar UI

3. **📊 RESULTADOS**
   - Panel con scroll horizontal
   - Resultados individuales con botón de cierre
   - Formato: Título + Código + Estado + Datos

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [ ] Crear carpeta `GV_adm_[NombreEntidad]`
- [ ] Definir modelo SwiftData con todos los campos del API
- [ ] Implementar clase `GV_ep_[NombreEntidad]` con todos los métodos
- [ ] Crear enumeraciones (ModoCargaBD, OrdenResultados, TipoRegreso)
- [ ] Implementar detección de duplicados en `Load_Stream_BDL`
- [ ] Implementar reporte en 4 partes (Resumen, CSV, Duplicados, Errores)
- [ ] Crear vista de prueba básica
- [ ] Crear vista de administración simplificada
- [ ] Agregar modelo al `modelContainer` en `limpioCSApp.swift`
- [ ] Probar todas las combinaciones de parámetros
- [ ] Verificar que funcione en iPad (layout optimizado)
- [ ] Generar documentación HTML

---

## 🔍 PATRONES A SEGUIR

### 1. Nomenclatura:
- Modelos: `GV_modeloCont_[NombreEntidad]`
- Clase sync: `GV_ep_[NombreEntidad]`
- Vista test: `GB_test_GV_ep_[NombreEntidad]View`
- Vista admin: `GV_VistaSimple_Test_[NombreEntidad]`

### 2. Estructura de métodos:
```swift
func NombreMetodo(parametros) -> (resultado: String, codigoError: Int) {
    let fechaInicio = obtenerFechaFormateada()
    
    do {
        // Lógica principal
        let fechaFin = obtenerFechaFormateada()
        return (mensajeExito, 0)
    } catch {
        return (mensajeError, -1)
    }
}
```

### 3. Logging:
```swift
print("🚀 INICIANDO [OPERACION]...")
print("📡 RESULTADO: Código \(codigo)")
print("✅ [OPERACION] completada")
print("❌ Error: \(descripcion)")
```

### 4. Formato de reportes:
```
✅ [TITULO]
═══════════════════
Inicio: [fecha]
Fin: [fecha]
Registros procesados: X
✅ Insertados: X
🔄 Actualizados: X
❌ Errores: X
```

---

## 📝 EJEMPLO DE USO DEL PROMPT

**Para crear sistema de Promociones:**

```
Necesito crear un sistema de sincronización para PROMOCIONES siguiendo el template.

Endpoint: https://api.ejemplo.com/api/evento/1/promociones

Campos del API:
- promocion_id (Int, único)
- establecimiento_id (Int)
- promocion_titulo (String)
- promocion_descripcion (String?)
- promocion_descuento (Int?)
- promocion_fecha_inicio (String)
- promocion_fecha_fin (String)
- promocion_imagen (String?)
- categoria_id (Int?)

Campo único: promocion_id
CSV format: ID, Título, Descuento, Fecha Inicio, Fecha Fin

Por favor, genera todos los archivos siguiendo exactamente la arquitectura de GV_ep_Establecimientos.
```

---

## 🎯 RESULTADO ESPERADO

Al finalizar, debes tener:

1. ✅ Sistema completo de sincronización funcionando
2. ✅ Vista de administración con todos los botones
3. ✅ Detección de duplicados implementada
4. ✅ Manejo exhaustivo de errores
5. ✅ Formato CSV optimizado para rendimiento
6. ✅ Documentación HTML generada
7. ✅ Compilación exitosa sin errores
8. ✅ Probado en simulador iPad

---

## 🚨 ADVERTENCIAS IMPORTANTES

1. **NO modificar la arquitectura base** - Seguir exactamente el patrón de `GV_ep_Establecimientos`
2. **NO usar `@Query` en vistas** - Usar `FetchDescriptor` en la clase de sincronización
3. **NO olvidar agregar modelo al `modelContainer`** en `limpioCSApp.swift`
4. **NO hardcodear valores** - Usar parámetros y configuraciones
5. **NO omitir la detección de duplicados** - Es crítica para integridad de datos
6. **SÍ usar formato CSV simple** - Para mejor rendimiento en `Get_[Entidad]`
7. **SÍ incluir numerador** - En todas las salidas de consultas
8. **SÍ actualizar progreso cada 1%** - En operaciones largas

---

## 📚 REFERENCIAS

**Archivo base:** `limpioCS/GV_adm_Establecimientos/GV_SistemaCompleto_Establecimientos.swift`

**Vista base:** `limpioCS/GV_adm_Establecimientos/GV_VistaSimple_Test.swift`

**Documentación:** `DOCUMENTACION_GV_ep_Establecimientos.html`

---

## 🎉 VENTAJAS DE ESTE PATRÓN

✅ **Reutilizable** - Fácil de adaptar a cualquier entidad
✅ **Robusto** - Manejo exhaustivo de errores
✅ **Eficiente** - Formato CSV optimizado
✅ **Completo** - Incluye todas las operaciones CRUD
✅ **Documentado** - HTML profesional generado
✅ **Testeable** - Vista de administración incluida
✅ **Escalable** - Soporta grandes volúmenes de datos
✅ **Mantenible** - Código limpio y organizado

---

## 📞 SOPORTE

Si encuentras algún problema o necesitas aclaraciones:

1. Revisar la documentación HTML de `GV_ep_Establecimientos`
2. Comparar con el archivo fuente original
3. Verificar que todos los campos del API estén mapeados
4. Confirmar que el modelo esté en el `modelContainer`
5. Probar cada método individualmente en la vista de administración

---

**¡Listo para crear tu próximo sistema de sincronización! 🚀**

---

*Template creado: Enero 2025 | Basado en GV_ep_Establecimientos v1.0.0*

