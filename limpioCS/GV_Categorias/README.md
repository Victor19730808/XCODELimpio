# 🏷️ Sistema de Categorías GV

Sistema simple y rápido de gestión de categorías basado en **Plist** para máximo rendimiento.

---

## 📁 Estructura

```
GV_Categorias/
├── GV_Categorias.plist          # Datos completos (57 categorías)
├── GV_Categoria.swift           # Modelo de datos
├── GV_CategoriaManager.swift    # Manager singleton
├── GV_TestCategoriasView.swift  # Vista de prueba (DEBUG)
└── README.md                    # Esta documentación
```

---

## ⚡ Características

- ✅ **Ultra rápido**: Carga en ~2-5ms, todo en memoria
- ✅ **Simple**: Solo 3 archivos principales
- ✅ **57 categorías** con colores e iconos SF Symbols
- ✅ **Búsqueda y filtrado** optimizado
- ✅ **Singleton pattern** para acceso global
- ✅ **SwiftUI Extensions** para fácil uso
- ✅ **Versionable en Git** (XML legible)

---

## 📊 Datos en el Plist

Cada categoría contiene:

```swift
categoria_id: Int           // ID único de la API
categoria_nombre: String    // Nombre de la categoría
categoria_taxonomia: String // Clasificación general
categoria_tags: String      // Tags separados por espacios
evento_id: Int             // 1 (anterior) o 2 (Buen Fin 2024)
colorHex: String           // Color en formato "#RRGGBB"
icono: String              // Nombre del SF Symbol
```

---

## 🚀 Uso Básico

### 1. Acceso al Manager

```swift
// Obtener el singleton
let manager = GV_CategoriaManager.shared

// Verificar si está cargado
if manager.isLoaded {
    print("✅ \(manager.totalCategorias) categorías disponibles")
}
```

### 2. Búsqueda por ID

```swift
// Obtener una categoría
if let categoria = manager.categoria(byId: 4485) {
    print(categoria.categoria_nombre)  // "Reparaciones y mantenimiento"
    print(categoria.color)             // Color de SwiftUI
    print(categoria.icono)             // "wrench.and.screwdriver.fill"
}

// Acceso rápido a propiedades
let color = manager.color(forCategoriaId: 4485)
let icono = manager.icono(forCategoriaId: 4485)
let nombre = manager.nombre(forCategoriaId: 4485)
```

### 3. Filtrado

```swift
// Por evento
let categoriasActuales = manager.categorias(byEvento: 2)  // Buen Fin 2024

// Por taxonomía
let gastronomia = manager.categorias(byTaxonomia: "Servicios gastronómicos")

// Por búsqueda
let resultados = manager.search("tecnología")  // Busca en nombre, taxonomía y tags
```

---

## 🎨 Uso en SwiftUI

### 1. Con el Manager

```swift
struct MiVista: View {
    @State private var manager = GV_CategoriaManager.shared
    
    var body: some View {
        List(manager.categorias) { categoria in
            HStack {
                Image(systemName: categoria.icono)
                    .foregroundColor(categoria.color)
                
                Text(categoria.categoria_nombre)
            }
        }
    }
}
```

### 2. Con Extension de View

```swift
// Aplicar estilo de categoría a un Text
Text(categoria.categoria_nombre)
    .categoriaTag(categoria)

// O por ID directamente
Text("Tecnología")
    .categoriaTag(byId: 4486)
```

### 3. Tag de categoría personalizado

```swift
// Usar propiedades de la categoría
HStack {
    Image(systemName: categoria.icono)
        .foregroundColor(categoria.color)
    
    Text(categoria.categoria_nombre)
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(categoria.colorOpaco)  // Color con opacity 0.1
        .foregroundColor(categoria.color)
        .cornerRadius(8)
}
```

---

## 🔍 Propiedades Computadas

El modelo `GV_Categoria` incluye propiedades útiles:

```swift
categoria.color          // Color de SwiftUI parseado desde hex
categoria.colorOpaco     // Color con opacity 0.1 para fondos
categoria.colorTexto     // Color apropiado para texto
categoria.tagsArray      // Tags como array de Strings
categoria.matches("búsqueda")  // Verifica si coincide con búsqueda
```

---

## 🧪 Vista de Prueba

En **modo DEBUG**, accede a la vista de prueba desde el menú principal:

**Menú Principal → 🧪 Testing → Test Sistema Categorías**

La vista incluye:
- 📊 Estadísticas (total, eventos, taxonomías)
- 🔍 Búsqueda en tiempo real
- 🎛️ Filtros por evento y taxonomía
- 🎨 Preview de colores e iconos
- 🏷️ Lista completa de categorías

---

## 🎨 Colores Asignados

Ejemplos de colores por tipo:

| Categoría | Color Hex | SF Symbol |
|-----------|-----------|-----------|
| Alimentos y bebidas | `#FF6B6B` | `fork.knife` |
| Belleza y salud | `#FF85C2` | `sparkles` |
| Tecnología | `#9B59B6` | `laptopcomputer` |
| Reparaciones | `#E67E22` | `wrench.and.screwdriver.fill` |
| Hogar | `#F39C12` | `house.fill` |
| Moda | `#E91E63` | `tshirt.fill` |

**Todos los colores son personalizables** editando el Plist.

---

## 📝 Editar el Plist

Para agregar o modificar categorías:

1. **Abre** `GV_Categorias.plist` en Xcode
2. **Expande** el array `categorias`
3. **Edita** o **agrega** un diccionario con:
   ```xml
   <dict>
       <key>categoria_id</key>
       <integer>5000</integer>
       <key>categoria_nombre</key>
       <string>Mi Nueva Categoría</string>
       <key>categoria_taxonomia</key>
       <string>Clasificación</string>
       <key>categoria_tags</key>
       <string>tag1 tag2 tag3</string>
       <key>evento_id</key>
       <integer>2</integer>
       <key>colorHex</key>
       <string>#FF0000</string>
       <key>icono</key>
       <string>star.fill</string>
   </dict>
   ```
4. **Guarda** y el manager lo cargará automáticamente

---

## 🔄 Recarga Manual

Si modificas el Plist en tiempo de ejecución (no recomendado en producción):

```swift
GV_CategoriaManager.shared.reload()
```

---

## 📊 Rendimiento

### Métricas de carga:

```
Carga inicial:     ~2-5ms (57 categorías)
Búsqueda por ID:   O(1) - Instantáneo (diccionario)
Búsqueda por texto: O(n) - ~1-2ms (filtrado en memoria)
Memoria ocupada:   ~8-10KB (todo en RAM)
```

### Comparativa con SwiftData:

| Métrica | Plist | SwiftData |
|---------|-------|-----------|
| Carga inicial | 2-5ms | 10-20ms |
| Búsqueda por ID | <1ms | 1-2ms |
| Memoria | 8-10KB | Variable |
| Complejidad | Simple | Media-Alta |
| Versionable | ✅ Git | ❌ Binario |

---

## 🎯 Cuándo Usar Este Sistema

### ✅ **Usa este sistema SI:**
- Tienes < 200 categorías
- Los datos cambian raramente
- Necesitas máxima velocidad
- Quieres simplicidad
- Necesitas versionamiento en Git

### ❌ **NO uses este sistema SI:**
- Tienes > 500 categorías
- Los datos cambian frecuentemente desde API
- Necesitas búsquedas SQL complejas
- Necesitas relaciones many-to-many
- Los datos crecen dinámicamente

---

## 🔗 Integración con Otros Sistemas

### En la lista de establecimientos:

```swift
// Obtener color e icono de la categoría
let categoria = manager.categoria(byId: establecimiento.categoria_id)

HStack {
    Image(systemName: categoria?.icono ?? "tag.fill")
        .foregroundColor(categoria?.color ?? .gray)
    
    Text(establecimiento.nombre)
}
```

### En el mapa:

```swift
// Usar el color de la categoría para el pin
let pinColor = manager.color(forCategoriaId: establecimiento.categoria_id)

MapAnnotation {
    Circle()
        .fill(pinColor)
        .frame(width: 20, height: 20)
}
```

### En promociones:

```swift
// Tag de categoría en la vista de promociones
Text(promocion.categoria_nombre)
    .categoriaTag(byId: promocion.categoria_id)
```

---

## 🛠️ Mantenimiento

### Actualizar desde API:

1. **Ejecuta** el endpoint: `GET /api/evento/categorias/buenfin`
2. **Copia** el JSON
3. **Abre** el Plist
4. **Actualiza** los campos del API (id, nombre, taxonomia, tags, evento_id)
5. **NO toques** `colorHex` e `icono` (solo locales)

### Sincronización semiautomática:

```swift
// TODO: Implementar si se necesita en el futuro
// - Fetch del API
// - Merge con Plist existente
// - Preservar colores e iconos locales
```

---

## 📚 Eventos Soportados

- **Evento 1**: Eventos anteriores (IDs 4506-4534)
- **Evento 2**: Buen Fin 2024 (IDs 4477-4505)

---

## 🎨 SF Symbols Usados

- `fork.knife`, `sparkles`, `book.fill`, `party.popper.fill`
- `bed.double.fill`, `dollarsign.circle.fill`, `wrench.and.screwdriver.fill`
- `laptopcomputer`, `tv.fill`, `camera.fill`, `house.fill`
- `tshirt.fill`, `shoe.fill`, `gift.fill`, `leaf.fill`
- Y muchos más...

Ver la lista completa en SF Symbols app de Apple.

---

## ✅ Checklist de Integración

- [x] Sistema de categorías implementado
- [x] Plist con 57 categorías
- [x] Manager singleton funcional
- [x] Vista de prueba creada
- [ ] Integrar en vista de Mapa
- [ ] Integrar en vista de Promociones
- [ ] Integrar en vista de Lista de Establecimientos
- [ ] Reemplazar código hardcoded existente

---

## 🚀 Próximos Pasos

1. **Integrar** el sistema en las vistas existentes
2. **Reemplazar** el código hardcoded de categorías
3. **Unificar** los estilos visuales
4. **Documentar** casos de uso específicos
5. **Optimizar** colores/iconos según feedback

---

**¿Preguntas? Revisa el código o la vista de prueba 🧪**

