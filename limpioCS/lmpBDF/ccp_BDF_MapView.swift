//
//  ccp_BDF_MapView.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Cliente: Concanaco ServyTur
//  Performed by: Grupo VAL Human TECH
//
//  Versión: Radio solo desde el **centro del mapa** + **Botones de Zoom** (+/−)
//  --------------------------------------------------------------------------
//  • Radio 1 … 50 km medido SIEMPRE desde el centro de la pantalla.
//  • Filtros: Categorías (multi-select; comparación normalizada) + Búsqueda por nombre.
//  • Mapa: pin de usuario (referencia visual), mira (crosshair) permanente en el centro,
//          colores por categoría (paleta fija + fallback hash), y **botones de zoom**.
//  • Los botones de zoom actúan sobre la región visible (span) sin perder el centro.
//
//  Fecha: 2025-10-02
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct ccp_BDF_MapView: View {
    @Environment(\.dismiss) private var dismiss

    // Dependencias
    @EnvironmentObject private var location: LocationService

    /// Consulta a SwiftData: todos los establecimientos locales ordenados por nombre.
    @Query(sort: [SortDescriptor(\lmpBDF_EstablecimientoLocal.nombre, comparator: .localizedStandard)])
    private var todos: [lmpBDF_EstablecimientoLocal]
    
    // Colores inspirados en El Buen Fin
    private let buenFinRed = Color(red: 0.89, green: 0.12, blue: 0.14) // #E31E24
    private let buenFinWhite = Color.white
    private let buenFinGray = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333

    // Estado UI / Mapa
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selected: lmpBDF_EstablecimientoLocal? = nil
    @State private var mapCenter: CLLocationCoordinate2D? = nil
    @State private var currentRegion: MKCoordinateRegion? = nil   // región visible actual (para zoom)
    @State private var didAutocenter = false

    // Filtros
    @State private var filtroRadioKm: Double = 10               // radio (km) SIEMPRE desde el centro del mapa
    @State private var filtroCategorias: Set<String> = []       // multi-select (vacío = todas)
    @State private var filtroNombre: String = ""
    @State private var showCategoriasSheet = false
    @State private var soloFavoritos = false                    // Filtro para mostrar solo favoritos
    
    // Optimizaciones de performance
    @State private var debounceTimer: Timer?
    @State private var maxMarkersToShow = 200                    // Límite de marcadores para performance
    @State private var colorCache: [String: Color] = [:]        // Cache de colores por categoría
    
    // Estadísticas
    @State private var showStats = false                        // Mostrar/ocultar panel de estadísticas

    // Rango del radio
    private let radioMin: Double = 1
    private let radioMax: Double = 50

    // Límites de zoom (span) — más pequeño = más cerca
    private let minDelta: CLLocationDegrees = 0.002  // ~200 m
    private let maxDelta: CLLocationDegrees = 40.0   // país completo aprox.
    private let zoomInFactor: Double  = 0.6          // cada toque reduce ~40% el área
    private let zoomOutFactor: Double = 1.6          // cada toque aumenta ~60% el área

    // Paleta fija (claves normalizadas)
    private let fixedPaletteNormalized: [String: Color] = [
        "restaurante": .red,
        "deportes": .blue,
        "libreria": .green,
        "moda": .purple,
        "electronica": .orange,
        "supermercado": .teal
    ]
    @State private var reportedUnknowns: Set<String> = []

    // Catálogo de categorías (deduplicado por normalización; muestra el primer original)
    private var categoriasEnBD: [String] {
        let originales = todos
            .compactMap { $0.categoria?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return uniqueOriginalsByNormalized(originales, normalizer: normalizeCategory)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
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

    // Filtro compuesto (categorías, nombre, radio desde el centro del mapa, favoritos) con optimizaciones
    private var filtrados: [lmpBDF_EstablecimientoLocal] {
        let categoriasSelNorm = Set(filtroCategorias.map(normalizeCategory))
        let nombre = filtroNombre.trimmingCharacters(in: .whitespacesAndNewlines)

        let filtered = todos.filter { e in
            guard let lat = e.lat, let lon = e.lon else { return false }

            // Filtro de favoritos
            if soloFavoritos && !e.esFavorito { return false }

            // Categorías (multi-select, normalizadas)
            if !categoriasSelNorm.isEmpty {
                let catNorm = normalizeCategory(e.categoria)
                if catNorm.isEmpty || !categoriasSelNorm.contains(catNorm) { return false }
            }

            // Nombre contiene
            if !nombre.isEmpty && !e.nombre.localizedCaseInsensitiveContains(nombre) { return false }

            // Radio desde centro del mapa (si ya lo tenemos)
            if let center = mapCenter {
                let d = distanceKm(lat1: center.latitude, lon1: center.longitude, lat2: lat, lon2: lon)
                if d > filtroRadioKm { return false }
            }
            return true
        }
        
        // Optimización: Limitar número de marcadores para performance
        if filtered.count > maxMarkersToShow {
            // Ordenar por distancia al centro para mostrar los más cercanos
            if let center = mapCenter {
                return Array(filtered.sorted { e1, e2 in
                    let d1 = distanceKm(lat1: center.latitude, lon1: center.longitude, 
                                      lat2: e1.lat!, lon2: e1.lon!)
                    let d2 = distanceKm(lat1: center.latitude, lon1: center.longitude, 
                                      lat2: e2.lat!, lon2: e2.lon!)
                    return d1 < d2
                }.prefix(maxMarkersToShow))
            } else {
                return Array(filtered.prefix(maxMarkersToShow))
            }
        }
        
        return filtered
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
                                    .foregroundColor(buenFinWhite)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .padding(.leading, 20)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Título "Mapa de Cercanías" centrado
                        Text("Mapa de Cercanías")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(buenFinWhite)
                        
                        // Menú hamburguesa
                        HStack {
                            Spacer()
                            
                            Menu {
                                Button {
                                    // Mis configuraciones
                                } label: {
                                    Label("Mis Configuraciones", systemImage: "gear")
                                }
                                
                                Button {
                                    // Búsquedas Avanzadas
                                } label: {
                                    Label("Búsquedas Avanzadas", systemImage: "magnifyingglass.circle")
                                }
                                
                                Button {
                                    // Admin Datos
                                } label: {
                                    Label("Admin Datos", systemImage: "wrench.and.screwdriver")
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal")
                                    .font(.title2)
                                    .foregroundColor(buenFinWhite)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .padding(.trailing, 20)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // Línea divisoria
                    Rectangle()
                        .fill(buenFinWhite.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                }
                .frame(height: 100)
                .background(buenFinRed)
                
                // Contenido principal
                VStack(spacing: 0) {
                    // Filtros con estilo El Buen Fin
                    VStack(spacing: 16) {
                        // Slider del radio
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Radio: \(Int(filtroRadioKm)) km")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(buenFinGray)
                                
                                Spacer()
                            }
                            
                            Slider(value: $filtroRadioKm, in: radioMin...radioMax, step: 1)
                                .accentColor(buenFinRed)
                                .onChange(of: filtroRadioKm) { _ in
                                    debounceSearch()
                                }
                            
                            if mapCenter == nil {
                                Text("Mueve el mapa para fijar el centro (ancla del radio).")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(buenFinGray.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(buenFinWhite)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        
                        // Categorías, búsqueda y estadísticas en una fila
                        HStack(spacing: 12) {
                            // Botón de categorías
                            Button { showCategoriasSheet = true } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .foregroundColor(buenFinRed)
                                    
                                    Text(filtroCategorias.isEmpty ? "Todas" : "\(filtroCategorias.count) seleccionadas")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(buenFinGray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(buenFinWhite)
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                            
                            // Búsqueda por nombre
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(buenFinGray.opacity(0.6))
                                
                                TextField("Nombre contiene...", text: $filtroNombre)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(buenFinGray)
                                    .onChange(of: filtroNombre) { _ in
                                        debounceSearch()
                                    }
                                
                                if !filtroNombre.isEmpty {
                                    Button {
                                        filtroNombre = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(buenFinGray.opacity(0.6))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(buenFinWhite)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            
                            // Toggle de favoritos
                            Button { 
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    soloFavoritos.toggle()
                                }
                            } label: {
                                Image(systemName: soloFavoritos ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(soloFavoritos ? buenFinWhite : buenFinRed)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(soloFavoritos ? buenFinRed : buenFinWhite)
                                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                                    .foregroundColor(showStats ? buenFinWhite : buenFinRed)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(showStats ? buenFinRed : buenFinWhite)
                                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    )
                            }
                        }
                        
                        // Chips de categorías seleccionadas
                        if !filtroCategorias.isEmpty {
                            WrapChips(items: Array(filtroCategorias).sorted()) { cat in
                                HStack(spacing: 6) {
                                    Text(cat)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(buenFinRed)
                                    
                                    Button { filtroCategorias.remove(cat) } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(buenFinGray.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(buenFinRed.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(buenFinRed.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        // Panel de estadísticas por categoría
                        if showStats {
                            StatsPanelView(
                                filtrados: filtrados,
                                estadisticasPorCategoria: estadisticasPorCategoria,
                                buenFinRed: buenFinRed,
                                buenFinWhite: buenFinWhite,
                                buenFinGray: buenFinGray
                            )
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity.combined(with: .scale(scale: 0.95))
                            ))
                        }
                        
                        // Contador de resultados con indicador de performance y favoritos
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mostrando: \(filtrados.count) · En BD: \(todos.count)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(buenFinGray.opacity(0.7))
                                
                                if soloFavoritos {
                                    let favoritosCount = todos.filter { $0.esFavorito }.count
                                    Text("⭐ \(favoritosCount) favoritos en total")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(buenFinRed.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            if filtrados.count >= maxMarkersToShow {
                                Text("(limitado para performance)")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(buenFinRed.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .background(buenFinWhite)
                    
                    // Mapa
                    Map(position: $cameraPosition, interactionModes: .all) {
                        // Pin de usuario personalizado
                        if let lat = location.latitude, let lon = location.longitude {
                            Annotation("Mi ubicación", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                Image(systemName: "location.fill")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .foregroundStyle(.blue)
                                    .shadow(radius: 3)
                            }
                        }

                        // Establecimientos filtrados
                        ForEach(filtrados) { e in
                            if let lat = e.lat, let lon = e.lon {
                                let color = colorForCategory(e.categoria)
                                Annotation(e.nombre, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                    Button { selected = e } label: {
                                        ZStack {
                                            // Círculo principal con color de categoría
                                            Circle().fill(color).frame(width: 18, height: 18)
                                            
                                            // Borde blanco
                                            Circle().stroke(.white, lineWidth: 2).frame(width: 18, height: 18)
                                            
                                            // Indicador especial para favoritos
                                            if e.esFavorito {
                                                Circle()
                                                    .stroke(.yellow, lineWidth: 3)
                                                    .frame(width: 24, height: 24)
                                                
                                                // Estrella pequeña en el centro
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(.yellow)
                                            }
                                        }
                                        .shadow(radius: e.esFavorito ? 4 : 2)
                                        .scaleEffect(e.esFavorito ? 1.1 : 1.0)
                                    }
                                }
                            }
                        }
                    }
                    // Capturamos el centro y la región del mapa
                    .onMapCameraChange { context in
                        mapCenter = context.region.center
                        currentRegion = context.region
                        adjustMarkerLimit() // Ajustar límite según zoom
                    }
                    .mapControls { MapCompass(); MapPitchToggle(); MapScaleView() }

                    // Mira SIEMPRE visible (el radio se mide desde aquí)
                    .overlay(alignment: .center) {
                        CrosshairOverlay().allowsHitTesting(false)
                    }

                    // Botones de Zoom (+ / −)
                    .overlay(alignment: .topTrailing) {
                        VStack(spacing: 10) {
                            Button {
                                zoomIn()
                            } label: {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.title2.bold())
                                    .foregroundColor(buenFinWhite)
                                    .padding(8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(buenFinRed)

                            Button {
                                zoomOut()
                            } label: {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.title2.bold())
                                    .foregroundColor(buenFinGray)
                                    .padding(8)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                    }

                    // Acciones rápidas (centrar a mi ubicación)
                    .overlay(alignment: .bottomTrailing) {
                        VStack(spacing: 8) {
                            Button { recenter() } label: {
                                Label("Centrar en mí", systemImage: "location.circle.fill").labelStyle(.iconOnly)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(buenFinRed)
                            MapUserLocationButton()
                        }
                        .padding()
                    }
                    .frame(minHeight: 320)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            location.start() // Permite mostrar el pin de usuario y autocentrar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { autoCenterIfPossible() }
            clearCachesIfNeeded() // Limpiar cachés al iniciar
        }
        // Sheet de detalle del establecimiento
        .sheet(item: $selected) { est in
            EstablecimientoDetalleSheetSimple(est: est)
                .presentationDetents([.fraction(0.35), .medium])
        }
        // Sheet de selección de categorías
        .sheet(isPresented: $showCategoriasSheet) {
            CategoriaMultiSelectSheet(
                todasLasCategorias: categoriasEnBD,
                seleccion: $filtroCategorias
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Normalización y utilidades

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

    // Colores por categoría con caché para performance
    private func colorForCategory(_ raw: String?) -> Color {
        let key = normalizeCategory(raw)
        
        // Verificar caché primero
        if let cachedColor = colorCache[key] {
            return cachedColor
        }
        
        let color: Color
        if let fixed = fixedPaletteNormalized[key] {
            color = fixed
        } else {
            if !key.isEmpty && !reportedUnknowns.contains(key) {
                reportedUnknowns.insert(key)
                print("🧩 Categoría sin paleta fija (hash color): '\(raw ?? "")' → normalizada '\(key)'")
            }
            color = hashedColor(from: key)
        }
        
        // Guardar en caché
        colorCache[key] = color
        return color
    }
    private func hashedColor(from text: String) -> Color {
        guard !text.isEmpty else { return .gray }
        var hasher = Hasher(); hasher.combine(text)
        let hue = Double(abs(hasher.finalize() % 360)) / 360.0
        return Color(hue: hue, saturation: 0.65, brightness: 0.85)
    }

    // MARK: - Zoom helpers

    private func zoomIn() {
        guard var region = currentRegion ?? defaultRegionFromCenter() else { return }
        region.span.latitudeDelta  = max(minDelta, region.span.latitudeDelta  * zoomInFactor)
        region.span.longitudeDelta = max(minDelta, region.span.longitudeDelta * zoomInFactor)
        withAnimation { cameraPosition = .region(region) }
        currentRegion = region
    }

    private func zoomOut() {
        guard var region = currentRegion ?? defaultRegionFromCenter() else { return }
        region.span.latitudeDelta  = min(maxDelta, region.span.latitudeDelta  * zoomOutFactor)
        region.span.longitudeDelta = min(maxDelta, region.span.longitudeDelta * zoomOutFactor)
        withAnimation { cameraPosition = .region(region) }
        currentRegion = region
    }

    private func defaultRegionFromCenter() -> MKCoordinateRegion? {
        guard let c = mapCenter else { return nil }
        return MKCoordinateRegion(center: c,
                                  span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
    }

    // MARK: - Mapa: centrado/auto-centrado y distancia

    private func autoCenterIfPossible() {
        guard !didAutocenter else { return }
        if let lat = location.latitude, let lon = location.longitude {
            let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = MKCoordinateRegion(center: center,
                                            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
            cameraPosition = .region(region)
            currentRegion = region
            didAutocenter = true
        }
    }

    private func recenter() {
        if let lat = location.latitude, let lon = location.longitude {
            let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = MKCoordinateRegion(center: center,
                                            span: currentRegion?.span ?? MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
            withAnimation { cameraPosition = .region(region) }
            currentRegion = region
        }
    }

    private func distanceKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
    
    // MARK: - Optimizaciones de Performance
    
    /// Debounce para búsquedas y filtros (evita recálculos excesivos)
    private func debounceSearch() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            // El filtrado se ejecuta automáticamente por la computed property
            // Solo limpiamos el caché de colores si es necesario
            if colorCache.count > 100 {
                colorCache.removeAll()
            }
        }
    }
    
    /// Limpia cachés cuando sea necesario
    private func clearCachesIfNeeded() {
        if colorCache.count > 200 {
            colorCache.removeAll()
        }
    }
    
    /// Ajusta dinámicamente el límite de marcadores según el zoom
    private func adjustMarkerLimit() {
        guard let region = currentRegion else { return }
        
        let span = max(region.span.latitudeDelta, region.span.longitudeDelta)
        
        // Más zoom = más marcadores permitidos
        if span < 0.01 { // Muy cerca
            maxMarkersToShow = 500
        } else if span < 0.1 { // Cerca
            maxMarkersToShow = 300
        } else if span < 1.0 { // Medio
            maxMarkersToShow = 200
        } else { // Lejos
            maxMarkersToShow = 100
        }
    }
}

// MARK: - Overlay: mira en el centro del mapa
/// Crosshair permanente que indica el centro del mapa (ancla del radio).
private struct CrosshairOverlay: View {
    private let buenFinRed = Color(red: 0.89, green: 0.12, blue: 0.14) // #E31E24
    
    var body: some View {
        ZStack {
            Circle().strokeBorder(buenFinRed.opacity(0.6), lineWidth: 2).frame(width: 24, height: 24)
            Circle().fill(buenFinRed.opacity(0.2)).frame(width: 8, height: 8)
        }.shadow(radius: 2)
    }
}

// MARK: - Helper UI: chips con flujo a múltiples líneas
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

// MARK: - Hoja: selección múltiple de categorías
private struct CategoriaMultiSelectSheet: View {
    let todasLasCategorias: [String]
    @Binding var seleccion: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        seleccion.removeAll() // Todas
                    } label: {
                        Label("Todas las categorías", systemImage: seleccion.isEmpty ? "checkmark.circle.fill" : "circle")
                    }
                }
                Section("Selecciona una o varias") {
                    ForEach(todasLasCategorias, id: \.self) { cat in
                        Button {
                            toggle(cat)
                        } label: {
                            HStack {
                                Text(cat)
                                Spacer()
                                Image(systemName: seleccion.contains(cat) ? "checkmark.circle.fill" : "circle")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Categorías")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Limpiar") { seleccion.removeAll() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Listo") { dismiss() } }
            }
        }
    }

    private func toggle(_ cat: String) {
        if seleccion.contains(cat) { seleccion.remove(cat) } else { seleccion.insert(cat) }
    }
}

// MARK: - Vista Separada para Panel de Estadísticas

struct StatsPanelView: View {
    let filtrados: [lmpBDF_EstablecimientoLocal]
    let estadisticasPorCategoria: [(categoria: String, count: Int, color: Color)]
    let buenFinRed: Color
    let buenFinWhite: Color
    let buenFinGray: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Estadísticas por Categoría")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(buenFinGray)
                    
                    Spacer()
                    
                    Text("\(filtrados.count) establecimientos")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(buenFinGray.opacity(0.7))
                }
                
                // Información de favoritos
                let favoritosCount = filtrados.filter { $0.esFavorito }.count
                if favoritosCount > 0 {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        
                        Text("\(favoritosCount) de \(filtrados.count) son favoritos")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(buenFinGray.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(Int(Double(favoritosCount) / Double(filtrados.count) * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(buenFinRed)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.yellow.opacity(0.1))
                    )
                }
            }
            
            if estadisticasPorCategoria.isEmpty {
                Text("No hay datos para mostrar")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(buenFinGray.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(estadisticasPorCategoria.prefix(5), id: \.categoria) { stat in
                        HStack(spacing: 12) {
                            // Indicador de color
                            Circle()
                                .fill(stat.color)
                                .frame(width: 12, height: 12)
                            
                            // Nombre de la categoría
                            Text(stat.categoria.capitalized)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(buenFinGray)
                            
                            Spacer()
                            
                            // Contador
                            Text("\(stat.count)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(buenFinRed)
                            
                            // Barra de progreso
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(stat.color.opacity(0.3))
                                    .frame(width: geometry.size.width * CGFloat(stat.count) / CGFloat(estadisticasPorCategoria.first?.count ?? 1))
                            }
                            .frame(width: 60, height: 4)
                        }
                    }
                    
                    if estadisticasPorCategoria.count > 5 {
                        Text("Y \(estadisticasPorCategoria.count - 5) categorías más...")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(buenFinGray.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(buenFinWhite)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}
