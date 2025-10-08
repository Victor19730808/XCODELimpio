//
//  ccp_BDF_MapClustersView.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Cliente: Concanaco ServyTur
//  Performed by: Grupo VAL Human TECH
//
//  Descripción (mapa clusters + filtros + detalle simple):
//  ----------------------------------------------------------------
//  • Clustering nativo de MapKit (agrupa establecimientos cercanos con contador).
//  • Búsqueda global sobre toda la BD local (SIN radio).
//  • Filtros colapsables: Categorías (multi-select con toggles + chips), Nombre, Municipio, Estado.
//  • Sin etiquetas "flotantes" bajo pins/clusters (anti-parpadeo).
//  • Solo se actualizan anotaciones si cambia la lista filtrada (no por pan/zoom).
//  • Botones: Zoom (+/−), "Centrar en mí", "Ver México".
//  • Al tocar un pin individual → Sheet con detalle (SIN favoritos).
//  • Migrado al sistema de temas dinámico
//
//  Requisitos: iOS 17+
//
//  Fecha: 2025-10-03
//  Migrado: 2025-01-10
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

// MARK: - Vista principal

struct ccp_BDF_MapClustersView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared

    // Dependencias
    @EnvironmentObject private var location: LocationService
    @Environment(\.modelContext) private var context

    /// SwiftData: todos los establecimientos locales (ordenados por nombre).
    @Query(sort: [SortDescriptor(\lmpBDF_EstablecimientoLocal.nombre, comparator: .localizedStandard)])
    private var todos: [lmpBDF_EstablecimientoLocal]

    // Filtros (SIN radio)
    @State private var filtroCategorias: Set<String> = []         // multi-select (vacío = todas)
    @State private var filtroNombre: String = ""
    @State private var filtroMunicipio: String = ""
    @State private var filtroEstado: String = ""
    @State private var soloFavoritos = false                      // Filtro para mostrar solo favoritos

    // Mostrar/ocultar filtros
    @State private var mostrarFiltros: Bool = true
    @State private var showCategoriasSheet = false
    
    // Estadísticas
    @State private var showStats = false                        // Mostrar/ocultar panel de estadísticas

    // Estado del mapa
    @State private var region: MKCoordinateRegion? = nil          // región visible (para zoom/recenter)

    // Selección para sheet de detalle
    @State private var seleccionado: lmpBDF_EstablecimientoLocal? = nil

    // Límites y factores de zoom
    private let minDelta: CLLocationDegrees = 0.002  // ~200 m
    private let maxDelta: CLLocationDegrees = 40.0   // país completo
    private let zoomInFactor: Double  = 0.6          // -40%
    private let zoomOutFactor: Double = 1.6          // +60%

    // “Ver México”
    private let mexicoCenter = CLLocationCoordinate2D(latitude: 23.6345, longitude: -102.5528)
    private let mexicoSpan   = MKCoordinateSpan(latitudeDelta: 28.0, longitudeDelta: 35.0)

    // Paleta fija (claves normalizadas)
    private let fixedPaletteNormalized: [String: Color] = [
        "restaurante": .red,
        "deportes": .blue,
        "libreria": .green,
        "moda": .purple,
        "electronica": .orange,
        "supermercado": .teal
    ]

    // Catálogo de categorías únicas (deduplicado por normalización)
    private var categoriasEnBD: [String] {
        let originales = todos
            .compactMap { $0.categoria?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return uniqueOriginalsByNormalized(originales, normalizer: normalizeCategory)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // Aplicar filtros (global, sin radio, incluyendo favoritos)
    private var filtrados: [lmpBDF_EstablecimientoLocal] {
        let categoriasSelNorm = Set(filtroCategorias.map(normalizeCategory))
        let nombre    = normalizeText(filtroNombre)
        let municipio = normalizeText(filtroMunicipio)
        let estado    = normalizeText(filtroEstado)

        return todos.filter { e in
            guard let _ = e.lat, let _ = e.lon else { return false }

            // Filtro de favoritos
            if soloFavoritos && !e.esFavorito { return false }

            if !categoriasSelNorm.isEmpty {
                let catNorm = normalizeCategory(e.categoria)
                if catNorm.isEmpty || !categoriasSelNorm.contains(catNorm) { return false }
            }
            if !nombre.isEmpty && !normalizeText(e.nombre).contains(nombre) { return false }
            if !municipio.isEmpty && !normalizeText(e.municipio).contains(municipio) { return false }
            if !estado.isEmpty && !normalizeText(e.estado).contains(estado) { return false }

            return true
        }
    }
    
    // Estadísticas por categoría de los establecimientos filtrados
    private var estadisticasPorCategoria: [(categoria: String, count: Int, color: Color)] {
        let categorias = Dictionary(grouping: filtrados, by: { normalizeCategory($0.categoria) })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return categorias.map { (categoria, count) in
            let color = colorForCategory(categoria)
            return (categoria: categoria, count: count, color: color)
        }
    }
    
    // Función para obtener color por categoría
    private func colorForCategory(_ raw: String?) -> Color {
        let normalized = normalizeCategory(raw)
        if let color = fixedPaletteNormalized[normalized] {
            return color
        }
        return Color.gray
    }

    var body: some View {
        ZStack {
            // Fondo con gradiente sutil
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.05),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header rojo estilo El Buen Fin
                VStack(spacing: 0) {
                    HStack {
                        // Botón regresar al menú principal
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "house.fill")
                                    .font(.title2)
                                    .foregroundColor(themeManager.currentTheme.colors.cardBackground)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                    )
                            }
                            .padding(.leading, 20)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Título "Mapa de la República" centrado
                        HeaderView(
                            text: "Mapa de la República",
                            type: .main,
                            textColor: themeManager.currentTheme.colors.cardBackground,
                            backgroundColor: .clear
                        )
                        
                        // Menú hamburguesa
                        HStack {
                            Spacer()
                            
                            HamburgerMenuView.themed(
                                viewType: .map,
                                menuActions: [
                                    .themes: { 
                                        // Temas - implementar según necesidad
                                    },
                                    .advancedSearch: { 
                                        // Búsquedas Avanzadas - implementar según necesidad
                                    },
                                    .mySettings: { 
                                        // Mis Configuraciones - implementar según necesidad
                                    }
                                ],
                                themeManager: themeManager
                            )
                            .padding(.trailing, 20)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // Línea divisoria
                    Rectangle()
                        .fill(themeManager.currentTheme.colors.cardBackground.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                }
                .frame(height: 100)
                .background(themeManager.currentTheme.colors.primary)
                
                // Contenido principal
                VStack(spacing: 0) {
                    // Barra de filtros y controles
                    VStack(spacing: 16) {
                        // Fila de controles principales
                        HStack(spacing: 12) {
                            // Botón de categorías
                            Button {
                                showCategoriasSheet = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.title3)
                                        .foregroundColor(themeManager.currentTheme.colors.primary)
                                    
                                    Text(filtroCategorias.isEmpty ? "Todas" : "\(filtroCategorias.count) seleccionadas")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(themeManager.currentTheme.colors.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.currentTheme.colors.cardBackground)
                                        .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                )
                            }
                            
                            // Toggle de favoritos
                            Button { 
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    soloFavoritos.toggle()
                                }
                            } label: {
                                Image(systemName: soloFavoritos ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(soloFavoritos ? themeManager.currentTheme.colors.textOnPrimary : themeManager.currentTheme.colors.primary)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(soloFavoritos ? themeManager.currentTheme.colors.primary : themeManager.currentTheme.colors.cardBackground)
                                            .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                    )
                            }
                            .accessibilityLabel(soloFavoritos ? "Mostrar todos" : "Solo favoritos")
                            
                            // Botón de estadísticas
                            Button { 
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showStats.toggle()
                                }
                            } label: {
                                Image(systemName: showStats ? "chart.bar.fill" : "chart.bar")
                                    .font(.title3)
                                    .foregroundColor(showStats ? themeManager.currentTheme.colors.textOnPrimary : themeManager.currentTheme.colors.primary)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(showStats ? themeManager.currentTheme.colors.primary : themeManager.currentTheme.colors.cardBackground)
                                            .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                    )
                            }
                        }
                        
                        // Campos de búsqueda
                        VStack(spacing: 12) {
                            // Búsqueda por nombre
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(themeManager.currentTheme.colors.textSecondary.opacity(0.6))
                                
                                TextField("Nombre contiene...", text: $filtroNombre)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.currentTheme.colors.cardBackground)
                                    .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                            )
                            
                            // Búsqueda por ubicación
                            HStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "building.2")
                                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary.opacity(0.6))
                                    
                                    TextField("Municipio...", text: $filtroMunicipio)
                                        .textFieldStyle(.plain)
                                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.currentTheme.colors.cardBackground)
                                        .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                )
                                
                                HStack {
                                    Image(systemName: "flag")
                                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary.opacity(0.6))
                                    
                                    TextField("Estado...", text: $filtroEstado)
                                        .textFieldStyle(.plain)
                                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.currentTheme.colors.cardBackground)
                                        .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                )
                            }
                        }
                        
                        // Chips de categorías seleccionadas
                        if !filtroCategorias.isEmpty {
                            WrapChips(items: Array(filtroCategorias).sorted()) { cat in
                                HStack(spacing: 6) {
                                    Text(cat)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(themeManager.currentTheme.colors.primary)
                                    
                                    Button {
                                        filtroCategorias.remove(cat)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(themeManager.currentTheme.colors.textSecondary.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(themeManager.currentTheme.colors.primary.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(themeManager.currentTheme.colors.primary.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        // Panel de estadísticas por categoría
                        if showStats {
                            StatsPanelView(
                                filtrados: filtrados,
                                estadisticasPorCategoria: estadisticasPorCategoria
                            )
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity.combined(with: .scale(scale: 0.95))
                            ))
                        }
                        
                        // Contador de resultados con indicador de favoritos
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mostrando: \(filtrados.count) · En BD: \(todos.count)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(themeManager.currentTheme.colors.textSecondary.opacity(0.7))
                                
                                if soloFavoritos {
                                    let favoritosCount = todos.filter { $0.esFavorito }.count
                                    Text("⭐ \(favoritosCount) favoritos en total")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(themeManager.currentTheme.colors.primary.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .background(themeManager.currentTheme.colors.cardBackground)
                    
                    // Mapa con clusters
                    ClusterMap(
                        items: filtrados,
                        region: $region,
                        colorResolver: { rawCat in
                            let key = normalizeCategory(rawCat)
                            if let ui = fixedUIColor(for: key) { return ui }
                            return hashedUIColor(from: key)
                        },
                        onSelect: { est in
                            self.seleccionado = est
                        }
                    )
                    .overlay(alignment: .topTrailing) {
                        VStack(spacing: 10) {
                            Button { zoomIn() } label: {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.title2.bold())
                                    .foregroundColor(themeManager.currentTheme.colors.cardBackground)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(themeManager.currentTheme.colors.primary)
                                            .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button { zoomOut() } label: {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.title2.bold())
                                    .foregroundColor(themeManager.currentTheme.colors.textSecondary)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(themeManager.currentTheme.colors.cardBackground)
                                            .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button { zoomToMexico() } label: {
                                Image(systemName: "globe.americas.fill")
                                    .font(.title2.bold())
                                    .foregroundColor(themeManager.currentTheme.colors.textSecondary)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(themeManager.currentTheme.colors.cardBackground)
                                            .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help("Ver toda la República")
                        }
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Button { recenterOnUser() } label: {
                            Image(systemName: "location.circle.fill")
                                .font(.title2)
                                .foregroundColor(themeManager.currentTheme.colors.cardBackground)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(themeManager.currentTheme.colors.primary)
                                        .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                    .frame(minHeight: 320)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let lat = location.latitude, let lon = location.longitude {
                region = MKCoordinateRegion(center: .init(latitude: lat, longitude: lon),
                                            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
            } else {
                zoomToMexico()
            }
        }
        .sheet(item: $seleccionado) { est in
            EstablecimientoDetalleSheetSimple(est: est)
                .environment(\.modelContext, context)
                .presentationDetents([.fraction(0.35), .medium])
        }
        .sheet(isPresented: $showCategoriasSheet) {
            CategoriaToggleSheet(
                categorias: categoriasEnBD,
                seleccion: $filtroCategorias
            )
        }
    }

    // MARK: - Normalización/utilidades

    private func normalizeText(_ raw: String?) -> String {
        (raw ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }
    private func normalizeCategory(_ raw: String?) -> String { normalizeText(raw) }

    private func uniqueOriginalsByNormalized(_ values: [String], normalizer: (String?) -> String) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for v in values {
            let key = normalizer(v)
            if key.isEmpty { continue }
            if !seen.contains(key) {
                seen.insert(key)
                result.append(v)
            }
        }
        return result
    }

    // Convertidores Color → UIColor
    private func fixedUIColor(for normalizedKey: String) -> UIColor? {
        if let c = fixedPaletteNormalized[normalizedKey] {
            return UIColor(c)
        }
        return nil
    }
    private func hashedUIColor(from text: String) -> UIColor {
        guard !text.isEmpty else { return UIColor.gray }
        var hasher = Hasher(); hasher.combine(text)
        let hue = CGFloat(abs(hasher.finalize() % 360)) / 360.0
        return UIColor(hue: hue, saturation: 0.65, brightness: 0.85, alpha: 1)
    }

    // MARK: - Zoom & recenter

    private func zoomIn() {
        guard var r = region else { return }
        r.span.latitudeDelta  = max(minDelta, r.span.latitudeDelta  * zoomInFactor)
        r.span.longitudeDelta = max(minDelta, r.span.longitudeDelta * zoomInFactor)
        withAnimation { region = r }
    }

    private func zoomOut() {
        guard var r = region else { return }
        r.span.latitudeDelta  = min(maxDelta, r.span.latitudeDelta  * zoomOutFactor)
        r.span.longitudeDelta = min(maxDelta, r.span.longitudeDelta * zoomOutFactor)
        withAnimation { region = r }
    }

    private func zoomToMexico() {
        let r = MKCoordinateRegion(center: mexicoCenter, span: mexicoSpan)
        withAnimation { region = r }
    }

    private func recenterOnUser() {
        guard let lat = location.latitude, let lon = location.longitude else { return }
        var r = region ?? MKCoordinateRegion(center: .init(latitude: lat, longitude: lon),
                                             span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        r.center = .init(latitude: lat, longitude: lon)
        withAnimation { region = r }
    }
}

//
// MARK: - SHEET: Detalle simple (sin favoritos)
//



//
// MARK: - SHEET: Multi-selección de categorías con toggles
//

private struct CategoriaToggleSheet: View {
    let categorias: [String]
    @Binding var seleccion: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Todas las categorías", isOn: Binding(
                        get: { seleccion.isEmpty },
                        set: { isOn in if isOn { seleccion.removeAll() } }
                    ))
                }

                Section("Selecciona una o varias") {
                    ForEach(categorias, id: \.self) { cat in
                        Toggle(isOn: Binding(
                            get: { seleccion.contains(cat) },
                            set: { val in
                                if val { seleccion.insert(cat) }
                                else { seleccion.remove(cat) }
                            }
                        )) { Text(cat) }
                    }
                }
            }
            .navigationTitle("Categorías")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Limpiar") { seleccion.removeAll() } // vuelve a "Todas"
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        seleccion = Set(categorias)
                    } label: {
                        Label("Seleccionar todas", systemImage: "checkmark.circle.badge.plus")
                    }
                }
            }
        }
    }
}

//
// MARK: - UIViewRepresentable con MKMapView y clustering (anti-parpadeo)
//

struct ClusterMap: UIViewRepresentable {
    let items: [lmpBDF_EstablecimientoLocal]
    @Binding var region: MKCoordinateRegion?

    /// Resuelve el color (UIColor) en función de la categoría (raw string).
    let colorResolver: (String?) -> UIColor

    /// Callback cuando el usuario toca un pin individual.
    let onSelect: (lmpBDF_EstablecimientoLocal) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.pointOfInterestFilter = .excludingAll
        map.isRotateEnabled = true
        map.isPitchEnabled = true

        map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "pin")
        map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "cluster")

        if let region { map.setRegion(region, animated: false) }

        context.coordinator.setAnnotations(on: map, items: items)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        if let region { map.setRegion(region, animated: false) }
        context.coordinator.updateAnnotationsIfNeeded(on: map, newItems: items)

        let newRegion = map.region
        let needsRegionUpdate =
            region?.center.latitude != newRegion.center.latitude ||
            region?.center.longitude != newRegion.center.longitude ||
            region?.span.latitudeDelta != newRegion.span.latitudeDelta ||
            region?.span.longitudeDelta != newRegion.span.longitudeDelta
        if needsRegionUpdate {
            DispatchQueue.main.async { region = newRegion }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, colorResolver: colorResolver, onSelect: onSelect)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private let parent: ClusterMap
        private let colorResolver: (String?) -> UIColor
        private let onSelect: (lmpBDF_EstablecimientoLocal) -> Void
        private var currentIDs: Set<Int> = []

        init(parent: ClusterMap,
             colorResolver: @escaping (String?) -> UIColor,
             onSelect: @escaping (lmpBDF_EstablecimientoLocal) -> Void) {
            self.parent = parent
            self.colorResolver = colorResolver
            self.onSelect = onSelect
        }

        func setAnnotations(on map: MKMapView, items: [lmpBDF_EstablecimientoLocal]) {
            let anns = buildAnnotations(from: items)
            currentIDs = Set(anns.map { $0.estabID })
            map.addAnnotations(anns)
        }

        func updateAnnotationsIfNeeded(on map: MKMapView, newItems: [lmpBDF_EstablecimientoLocal]) {
            let newAnns = buildAnnotations(from: newItems)
            let newIDs  = Set(newAnns.map { $0.estabID })
            guard newIDs != currentIDs else { return }

            let toRemove = map.annotations.compactMap { ann -> MKAnnotation? in
                if let a = ann as? EstabAnnotation, !newIDs.contains(a.estabID) { return a }
                return nil
            }
            if !toRemove.isEmpty { map.removeAnnotations(toRemove) }

            let existingIDs = Set(map.annotations.compactMap { ($0 as? EstabAnnotation)?.estabID })
            let missing = newAnns.filter { !existingIDs.contains($0.estabID) }
            if !missing.isEmpty { map.addAnnotations(missing) }

            currentIDs = newIDs
        }

        private func buildAnnotations(from items: [lmpBDF_EstablecimientoLocal]) -> [EstabAnnotation] {
            items.compactMap { e in
                guard let lat = e.lat, let lon = e.lon else { return nil }
                return EstabAnnotation(
                    estabID: Int(e.id),
                    title: e.nombre,
                    subtitle: e.categoria ?? "",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    categoryRaw: e.categoria,
                    source: e
                )
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if let cluster = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "cluster", for: annotation) as! MKMarkerAnnotationView
                view.displayPriority = .defaultHigh
                view.markerTintColor = UIColor.systemIndigo
                view.glyphText = "\(cluster.memberAnnotations.count)"
                view.titleVisibility = .hidden
                view.subtitleVisibility = .hidden
                view.canShowCallout = false
                view.animatesWhenAdded = false
                return view
            }

            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "pin", for: annotation) as! MKMarkerAnnotationView
            if let estabAnn = annotation as? EstabAnnotation {
                view.clusteringIdentifier = "estab"
                view.markerTintColor = colorResolver(estabAnn.categoryRaw)
                view.titleVisibility = .hidden
                view.subtitleVisibility = .hidden
                view.canShowCallout = true
                view.animatesWhenAdded = false
            }
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // CLUSTER → auto-zoom a sus miembros
            if let cluster = view.annotation as? MKClusterAnnotation {
                mapView.showAnnotations(cluster.memberAnnotations, animated: true)
                return
            }
            // PIN individual → notificar selección al parent para abrir sheet
            if let estabAnn = view.annotation as? EstabAnnotation {
                onSelect(estabAnn.source)
            }
        }
    }
}

//
// MARK: - Modelo de anotación
//

final class EstabAnnotation: NSObject, MKAnnotation {
    let estabID: Int
    let titleText: String
    let subtitleText: String
    let categoryRaw: String?
    let source: lmpBDF_EstablecimientoLocal   // referencia al modelo original

    dynamic var coordinate: CLLocationCoordinate2D
    var title: String? { titleText }
    var subtitle: String? { subtitleText }

    init(estabID: Int,
         title: String,
         subtitle: String,
         coordinate: CLLocationCoordinate2D,
         categoryRaw: String?,
         source: lmpBDF_EstablecimientoLocal) {
        self.estabID = estabID
        self.titleText = title
        self.subtitleText = subtitle
        self.coordinate = coordinate
        self.categoryRaw = categoryRaw
        self.source = source
        super.init()
    }
}

//
// MARK: - Helper UI (chips multilínea)
//

private struct WrapChips<ItemView: View>: View {
    let items: [String]
    let chip: (String) -> ItemView
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in generateContent(in: geometry) }
            .frame(height: totalHeight)
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                chip(item)
                    .padding(.trailing, 6)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > g.size.width) { width = 0; height -= d.height }
                        let result = width
                        if item == items.last { width = 0 } else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { d in
                        let result = height
                        if item == items.last { height = 0 }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo -> Color in
            DispatchQueue.main.async { binding.wrappedValue = geo.size.height }
            return .clear
        }
    }
}

//
// MARK: - Utilidades
//

private func uniqueOriginalsByNormalized(_ values: [String], normalizer: (String?) -> String) -> [String] {
    var seen: Set<String> = []
    var result: [String] = []
    for v in values {
        let key = normalizer(v)
        if key.isEmpty { continue }
        if !seen.contains(key) {
            seen.insert(key)
            result.append(v)
        }
    }
    return result
}

private func normalizeText(_ raw: String?) -> String {
    (raw ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(options: .diacriticInsensitive, locale: .current)
        .lowercased()
}
private func normalizeCategory(_ raw: String?) -> String { normalizeText(raw) }

