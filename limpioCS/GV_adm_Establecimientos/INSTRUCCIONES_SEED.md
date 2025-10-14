# 🌱 INSTRUCCIONES PARA GENERAR Y USAR EL SEED

## 📋 RESUMEN

El sistema de **Seed** permite incluir datos precargados en la app para que funcione sin conexión desde el primer arranque. Los datos se cargan automáticamente la primera vez que se abre la app.

---

## 🎯 PASO 1: GENERAR EL ARCHIVO JSON SEED

### Opción A: Desde la Vista de Administración (Recomendado)

1. **Abrir la app** en el simulador o dispositivo
2. **Ir a la vista de administración** (`GV_VistaSimple_Test`)
3. **Presionar el botón "Admin Seed"** (verde, con icono de cilindro)
4. **Presionar "Exportar BD Actual a JSON"**
5. **Copiar el JSON generado** (botón "Copiar")
6. **Guardar en un archivo** llamado `establecimientos_seed.json`

### Opción B: Manualmente desde el código

```swift
let seedManager = GV_SeedManager.shared
let (success, json, message) = seedManager.exportarSeedDesdeDB(modelContext: modelContext)

if success {
    // Guardar 'json' en un archivo
    print(json)
}
```

---

## 📦 PASO 2: AGREGAR EL JSON AL BUNDLE

### 2.1 Crear el archivo en Xcode

1. **Click derecho** en la carpeta `GV_adm_Establecimientos`
2. **New File** → **Empty File**
3. **Nombre:** `establecimientos_seed.json`
4. **Pegar el contenido JSON** exportado

### 2.2 Verificar que esté en el Bundle

1. **Seleccionar el archivo** `establecimientos_seed.json` en Xcode
2. **Ir al Inspector** (panel derecho)
3. **Verificar que esté marcado** en "Target Membership" → `limpioCS`
4. **Verificar en Build Phases:**
   - Ir a **Project Settings** → **limpioCS Target** → **Build Phases**
   - Expandir **"Copy Bundle Resources"**
   - **Confirmar** que `establecimientos_seed.json` está en la lista

---

## 🚀 PASO 3: INTEGRAR EN LA APP

### 3.1 Actualizar limpioCSApp.swift

El sistema ya está preparado para detectar automáticamente si es necesario cargar el seed. Solo necesitas decidir cuándo verificarlo:

#### Opción A: Carga automática en el splash screen (Recomendado)

```swift
import SwiftUI
import SwiftData

@main
struct limpioCSApp: App {
    @StateObject private var seedManager = GV_SeedManager.shared
    @State private var showMainApp = false
    
    var body: some Scene {
        WindowGroup {
            if seedManager.checkSeedStatus() && !showMainApp {
                // Mostrar pantalla de carga si necesita seed
                GV_SeedLoadingView(seedManager: seedManager) {
                    showMainApp = true
                }
            } else {
                // Mostrar app normal
                GV_SCR_tp_splash()
            }
        }
        .modelContainer(for: [
            lmpBDF_EstablecimientoLocal.self,
            GV_modeloCont_Establecimientos.self
        ])
    }
}
```

#### Opción B: Carga manual cuando sea necesario

```swift
// En cualquier vista donde tengas acceso al modelContext
@Environment(\.modelContext) private var modelContext
@StateObject private var seedManager = GV_SeedManager.shared

// Llamar cuando quieras cargar el seed
Task {
    let (success, message) = await seedManager.loadSeedIfNeeded(modelContext: modelContext)
    print(message)
}
```

---

## 🔧 PASO 4: CONFIGURACIÓN Y VERSIONADO

### 4.1 Cambiar la versión del seed

Si actualizas los datos y quieres forzar una recarga:

```swift
// En GV_SeedManager.swift, línea ~30
private let currentSeedVersion = "1.0.0"  // Cambiar a "1.0.1", "2.0.0", etc.
```

### 4.2 Cambiar el nombre del archivo

Si quieres usar otro nombre de archivo:

```swift
// En GV_SeedManager.swift, línea ~31
private let seedFileName = "establecimientos_seed"  // Sin extensión .json
```

---

## 📊 PASO 5: VERIFICAR QUE FUNCIONA

### 5.1 Prueba en Simulador

1. **Eliminar la app** del simulador (long press → Delete)
2. **Compilar y ejecutar** de nuevo
3. **Verificar** que aparece la pantalla de carga con progreso
4. **Confirmar** que los datos se cargan correctamente

### 5.2 Verificar en la Vista de Administración

1. **Abrir** `GV_VistaSimple_Test`
2. **Presionar "Admin Seed"**
3. **Verificar el estado:**
   - ✅ Estado: Cargado
   - ✅ Versión actual: 1.0.0
   - ✅ Versión esperada: 1.0.0

### 5.3 Verificar en Logs

Buscar en la consola:
```
🌱 SEED: Iniciando carga de datos precargados...
📦 SEED: Archivo leído - XXXXX bytes
💾 SEED: Resultado de carga:
   Código: 0
✅ Seed cargado exitosamente (v1.0.0)
```

---

## 🔄 ACTUALIZAR EL SEED EN PRODUCCIÓN

### Escenario: Tienes una nueva versión con más datos

1. **Generar nuevo JSON** con los datos actualizados
2. **Reemplazar** `establecimientos_seed.json` en Xcode
3. **Incrementar la versión** en `GV_SeedManager.swift`:
   ```swift
   private let currentSeedVersion = "1.0.1"  // Nueva versión
   ```
4. **Compilar y distribuir** la nueva versión de la app

**Resultado:** Los usuarios que actualicen la app verán que el seed se recarga automáticamente con los nuevos datos.

---

## 🧪 COMANDOS ÚTILES

### Resetear el seed (para testing)

```swift
// Desde cualquier vista
GV_SeedManager.shared.resetSeed()
```

### Obtener información del seed

```swift
let info = GV_SeedManager.shared.getSeedInfo()
print(info)
```

### Exportar seed programáticamente

```swift
let seedManager = GV_SeedManager.shared
let (success, json, message) = seedManager.exportarSeedDesdeDB(modelContext: modelContext)

if success {
    // Guardar 'json' donde necesites
    try? json.write(to: fileURL, atomically: true, encoding: .utf8)
}
```

---

## 📈 ESTADÍSTICAS DEL SEED ACTUAL

**Datos actuales en la BD:**
- **Registros:** 1198 establecimientos
- **Tamaño estimado JSON:** ~800 KB - 1.5 MB (sin comprimir)
- **Tamaño en .ipa:** ~300-500 KB (comprimido)
- **Tiempo de carga:** 2-5 segundos (primera vez)

---

## ⚠️ CONSIDERACIONES IMPORTANTES

### ✅ Ventajas del Seed

- ✅ App funcional sin conexión desde el inicio
- ✅ Mejor experiencia de usuario (no espera descarga)
- ✅ Reduce carga en el servidor
- ✅ Datos disponibles inmediatamente

### ⚠️ Desventajas

- ⚠️ Aumenta el tamaño del .ipa
- ⚠️ Datos pueden quedar desactualizados
- ⚠️ Requiere actualización de la app para nuevos datos

### 💡 Recomendación

**Estrategia híbrida:**
1. **Incluir seed** con datos base (1198 registros)
2. **Primera carga:** Usar seed del bundle
3. **Después:** Sincronizar con API en modo `.inc` (incremental)
4. **Actualizaciones:** Nuevas versiones de la app con seed actualizado

---

## 🐛 TROUBLESHOOTING

### Problema: "Archivo seed no encontrado"

**Solución:**
1. Verificar que el archivo esté en el bundle
2. Verificar el nombre exacto: `establecimientos_seed.json`
3. Verificar que esté marcado en "Target Membership"

### Problema: "Error al leer archivo seed"

**Solución:**
1. Verificar que el JSON sea válido
2. Verificar la codificación (debe ser UTF-8)
3. Verificar que no haya caracteres especiales corruptos

### Problema: "Seed se carga cada vez que abro la app"

**Solución:**
1. Verificar que `UserDefaults` esté funcionando
2. Verificar que la versión no cambie constantemente
3. Revisar logs para ver si hay errores

### Problema: "Duplicados en la base de datos"

**Solución:**
1. El sistema detecta automáticamente duplicados
2. Revisar el reporte de `Load_Stream_BDL`
3. Limpiar la BD y recargar si es necesario

---

## 📚 ARCHIVOS RELACIONADOS

- **`GV_SeedManager.swift`** - Sistema de gestión de seed
- **`GV_VistaSimple_Test.swift`** - Vista de administración
- **`GV_SistemaCompleto_Establecimientos.swift`** - Sistema de sincronización
- **`establecimientos_seed.json`** - Archivo de datos precargados

---

## 🎉 ¡LISTO!

Con estos pasos, tu app tendrá datos precargados y funcionará perfectamente desde el primer arranque, incluso sin conexión a internet.

**Próximos pasos sugeridos:**
1. Generar el JSON con los 1198 registros actuales
2. Agregarlo al bundle
3. Probar en simulador (app limpia)
4. Probar en dispositivo físico
5. Distribuir la app con seed incluido

---

*Documentación generada: Enero 2025 | Sistema GV_SeedManager v1.0.0*

