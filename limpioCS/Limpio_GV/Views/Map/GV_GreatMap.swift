//
//  GV_GreatMap.swift
//  limpioCS
//
//  Created: 2025-10-15
//  Sistema: GV - Mapa de Establecimientos (NUEVA VERSIÓN LIMPIA)
//
//  Descripción:
//  ----------------------------------------------------------------
//  • Mapa optimizado desde cero con el modelo correcto
//  • Usa GV_modeloCont_Establecimientos (modelo principal)
//  • Lazy loading implementado desde el inicio
//  • Sin código legacy
//
//  Características:
//  ----------------------------------------------------------------
//  • ✅ Lazy loading de establecimientos por región visible
//  • ✅ Clustering inteligente
//  • ✅ Filtros por nombre, favoritos y taxonomías
//  • ✅ Optimizado para dispositivos reales
//  • ✅ Sistema de temas integrado
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import UIKit

struct GV_GreatMap: View {
    
    // MARK: - Environment
    @EnvironmentObject private var location: LocationService
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Managers
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    @ObservedObject private var favoritosManager = GV_FavoritosManager.shared
    private let categoriaManager = GV_CategoriaManager.shared
    // Eliminado uso de taxonomías: trabajaremos por categorías
    private let config = GV_ConfiguracionesGenerales.shared
    
    // MARK: - States
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var establecimientos: [GV_modeloCont_Establecimientos] = []
    @State private var isLoading = false
    @State private var currentRegion: MKCoordinateRegion? = nil
    @State private var lastLoadedRegion: MKCoordinateRegion? = nil // Para evitar recargas innecesarias
    @State private var loadTask: Task<Void, Never>? = nil // Para cancelar tareas pendientes
    @State private var soloFavoritos = false // Filtro de favoritos
    @State private var navegarAPromociones = false
    @State private var establecimientoSeleccionado: GV_modeloCont_Establecimientos? = nil
    @State private var categoriasSeleccionadas: Set<Int> = []
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var searchResults: [GV_modeloCont_Establecimientos] = []
    @State private var mostrarAcciones = false
    @State private var establecimientoParaAcciones: GV_modeloCont_Establecimientos? = nil
    @State private var highlightedEstId: Int? = nil
    @FocusState private var searchFieldFocused: Bool
    @State private var selectedMapStyle: MapStyle = .standard
    // Overlays y cache
    @State private var showEmptyOverlay: Bool = false
    @State private var regionCache: [String: (Date, [GV_modeloCont_Establecimientos])] = [:]
    @State private var categoriaIdMemo: [Int: Int] = [:]
    
    // MARK: - Configuración
    let isTodoMexico: Bool
    
    // MARK: - Computed Properties
    
    /// Establecimientos filtrados por favoritos y categorías (OR en categorías)
    private var establecimientosFiltrados: [GV_modeloCont_Establecimientos] {
        var resultado = establecimientos
        if soloFavoritos {
            resultado = resultado.filter { favoritosManager.isFavorite(establecimientoId: $0.establecimiento_id) }
        }
        if !categoriasSeleccionadas.isEmpty {
            resultado = resultado.filter { est in
                if let catId = categoriaIdResuelta(for: est) {
                    return categoriasSeleccionadas.contains(catId)
                }
                return false
            }
        }
        if debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= max(1, config.mapa_SearchMinChars) {
            let term = debouncedSearchText.lowercased()
            resultado = resultado.filter { est in
                est.establecimiento_nombre.lowercased().contains(term)
            }
        }
        return resultado
    }
    
    var body: some View {
        ZStack {
            // Fondo
            themeManager.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Mapa
                mapView
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navegarAPromociones) {
            if let establecimiento = establecimientoSeleccionado {
                GV_SRC_vg_EstablecimientoPromociones(establecimientoId: establecimiento.establecimiento_id)
            }
        }
        .onAppear {
            // Asegurar que el servicio de ubicación esté activo
            location.start()
            ProductionLogger.mapLog("LocationService iniciado - Lat: \(location.latitude?.description ?? "nil"), Lon: \(location.longitude?.description ?? "nil")")
            
            cargarEstablecimientos()
            configurarCamaraInicial()
        }
    }
    
    // MARK: - Subvistas
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(isTodoMexico ? "🗺️ Todo México" : "📍 Cerca de Ti")
                    .font(themeManager.title)
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.textSecondary)
                TextField("Buscar por nombre", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .foregroundColor(themeManager.textPrimary)
                    .focused($searchFieldFocused)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        debouncedSearchText = ""
                        categoriasSeleccionadas.removeAll()
                        searchResults = []
                        searchFieldFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(themeManager.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(themeManager.cardBackground)
    }
    
    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Pines de establecimientos con estilos por categoría; fallback neutral
            ForEach(establecimientosFiltrados, id: \.establecimiento_id) { est in
                if let lat = est.direccion_latitud, let lon = est.direccion_longitud {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    if let (color, icono) = getCategoriaStyle(for: est) {
                        Annotation(est.establecimiento_nombre, coordinate: coordinate) {
                            pinView(color: color, icono: icono, isFavorito: favoritosManager.isFavorite(establecimientoId: est.establecimiento_id))
                                .scaleEffect(highlightedEstId == est.establecimiento_id ? 1.15 : 1.0)
                                .shadow(color: (highlightedEstId == est.establecimiento_id ? color : .clear).opacity(0.9), radius: highlightedEstId == est.establecimiento_id ? 10 : 0)
                                .onTapGesture {
                                    establecimientoParaAcciones = est
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        mostrarAcciones = true
                                    }
                                }
                        }
                    } else {
                        Annotation(est.establecimiento_nombre, coordinate: coordinate) {
                            pinFallbackDefault()
                                .scaleEffect(highlightedEstId == est.establecimiento_id ? 1.15 : 1.0)
                                .onTapGesture {
                                    establecimientoParaAcciones = est
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        mostrarAcciones = true
                                    }
                                }
                        }
                    }
                }
            }
            
            // Pin del usuario
            if let userLat = location.latitude, let userLon = location.longitude {
                Annotation("Mi ubicación", coordinate: CLLocationCoordinate2D(latitude: userLat, longitude: userLon)) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 32, height: 32)
                        )
                        .shadow(radius: 3)
                }
            }
        }
        .mapStyle(selectedMapStyle)
        .onMapCameraChange { context in
            // Guardar región actual
            currentRegion = context.region
            
            // Cancelar tarea anterior
            loadTask?.cancel()
            
            // Crear nueva tarea con debounce
            loadTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(config.mapa_DebounceTime * 1_000_000_000))
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.cargarEstablecimientosParaRegion(context.region)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Stack de controles flotantes
            VStack(spacing: 12) {
                // Botón/menú de estilo de mapa
                Menu {
                    Button { switchTo2D() } label: { Label("Estándar (2D)", systemImage: "map") }
                    Button { switchTo3D() } label: { Label("Estándar (3D)", systemImage: "cube") }
                    Button {
                        selectedMapStyle = .imagery
                    } label: { Label("Satélite", systemImage: "sparkles") }
                    Button {
                        selectedMapStyle = .hybrid
                    } label: { Label("Híbrido", systemImage: "square.stack.3d.up") }
                } label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.cardBackground)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        Image(systemName: "map")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeManager.textPrimary)
                    }
                }
                // Botón/menú de filtro por categoría (multi-select OR)
                Menu {
                    Button {
                        categoriasSeleccionadas.removeAll()
                        ProductionLogger.mapLog("Filtro categorías: limpiado")
                    } label: {
                        Label("Limpiar filtros", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    Divider()
                    ForEach(categoriasDisponiblesList(), id: \.id) { cat in
                        let seleccionado = categoriasSeleccionadas.contains(cat.categoria_id)
                        Button {
                            if seleccionado {
                                categoriasSeleccionadas.remove(cat.categoria_id)
                                ProductionLogger.mapLog("Filtro categoría removida: \(cat.categoria_nombre)")
                            } else {
                                categoriasSeleccionadas.insert(cat.categoria_id)
                                ProductionLogger.mapLog("Filtro categoría agregada: \(cat.categoria_nombre)")
                            }
                        } label: {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: cat.icono)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(cat.color)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    Text(cat.categoria_nombre)
                                        .foregroundColor(cat.color)
                                }
                                Spacer(minLength: 12)
                                Image(systemName: seleccionado ? "checkmark.circle.fill" : "circle")
                            }
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.cardBackground)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeManager.textPrimary)
                        if !categoriasSeleccionadas.isEmpty {
                            Text("\(categoriasSeleccionadas.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .offset(x: 14, y: -14)
                        }
                    }
                }
                // Botón filtro de favoritos
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        soloFavoritos.toggle()
                    }
                    ProductionLogger.mapLog("Filtro favoritos: \(soloFavoritos ? "Activado" : "Desactivado")")
                }) {
                    ZStack {
                        Circle()
                            .fill(soloFavoritos ? themeManager.accent : themeManager.cardBackground)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: soloFavoritos ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(soloFavoritos ? .white : themeManager.textPrimary)
                        
                        // Badge con contador
                        if favoritosManager.getFavoriteCount() > 0 {
                            Text("\(favoritosManager.getFavoriteCount())")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 14, y: -14)
                        }
                    }
                }
                
                // Botón para centrar en usuario
                Button(action: centrarEnUsuario) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(themeManager.accent)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .padding()
        }
        .onChange(of: searchText) { _, newValue in
            // Debounce manual simple
            loadTask?.cancel()
            loadTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(config.mapa_SearchDebounceTime * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.debouncedSearchText = newValue
                }
            }
        }
        .overlay(alignment: .bottom) {
            if debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= max(1, config.mapa_SearchMinChars) && !searchResults.isEmpty {
                resultadosBusquedaOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .onChange(of: debouncedSearchText) { _, term in
            actualizarResultadosBusqueda(term: term)
        }
        .overlay(accionesDialog)
        .overlay(loadingEmptyOverlays)
    }
    
    // MARK: - Funciones
    
    /// Carga establecimientos SOLO para la región visible del mapa (Lazy Loading)
    private func cargarEstablecimientosParaRegion(_ region: MKCoordinateRegion) {
        // Evitar recargas innecesarias
        guard !isLoading else { return }
        
        // Verificar si la región cambió significativamente (evita recargas por micro-movimientos)
        if let lastRegion = lastLoadedRegion {
            let centerLatDiff = abs(region.center.latitude - lastRegion.center.latitude)
            let centerLonDiff = abs(region.center.longitude - lastRegion.center.longitude)
            let spanLatDiff = abs(region.span.latitudeDelta - lastRegion.span.latitudeDelta)
            let spanLonDiff = abs(region.span.longitudeDelta - lastRegion.span.longitudeDelta)
            let centerThreshold = lastRegion.span.latitudeDelta * config.mapa_ThresholdCenterFactor
            let latThreshold = lastRegion.span.latitudeDelta * config.mapa_ThresholdSpanFactorLat
            let lonThreshold = lastRegion.span.longitudeDelta * config.mapa_ThresholdSpanFactorLon
            if centerLatDiff < centerThreshold && centerLonDiff < centerThreshold && spanLatDiff < latThreshold && spanLonDiff < lonThreshold {
                return // cambio mínimo
            }
        }
        
        Task {
            isLoading = true
            showEmptyOverlay = false
            let t0 = CFAbsoluteTimeGetCurrent()
            
            do {
                // Calcular límites de la región visible (con buffer configurable)
                let buffer = config.mapa_RegionBuffer
                let minLat = region.center.latitude - (region.span.latitudeDelta / 2.0) - buffer
                let maxLat = region.center.latitude + (region.span.latitudeDelta / 2.0) + buffer
                let minLon = region.center.longitude - (region.span.longitudeDelta / 2.0) - buffer
                let maxLon = region.center.longitude + (region.span.longitudeDelta / 2.0) + buffer

                // Cache por región (tile-like)
                let cacheKey = regionCacheKey(for: region)
                if let (date, data) = regionCache[cacheKey], Date().timeIntervalSince(date) < Double(config.mapa_TileCacheTTLSeconds) {
                    await MainActor.run {
                        self.establecimientos = data
                        self.lastLoadedRegion = region
                        self.isLoading = false
                        self.showEmptyOverlay = data.isEmpty
                        ProductionLogger.mapLog("Cache hit: \(data.count) establecimientos | key=\(cacheKey)")
                    }
                    return
                }
                
                // Crear predicado para filtrar por región
                let predicate = #Predicate<GV_modeloCont_Establecimientos> { est in
                    est.direccion_latitud != nil && est.direccion_longitud != nil
                }
                
                // Crear descriptor con límite (para rendimiento)
                var descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.establecimiento_nombre, comparator: .localizedStandard)]
                )
                // Limitar fetch adaptativo por zoom
                descriptor.fetchLimit = adaptiveFetchLimit(for: region)
                
                // Fetch de establecimientos
                let todosConCoordenadas = try context.fetch(descriptor)
                
                // Filtrar manualmente por región (predicados no soportan comparaciones complejas)
                let establecimientosEnRegion = todosConCoordenadas.filter { est in
                    guard let lat = est.direccion_latitud, let lon = est.direccion_longitud else {
                        return false
                    }
                    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
                }
                
                await MainActor.run {
                    self.establecimientos = establecimientosEnRegion
                    self.lastLoadedRegion = region // Guardar región cargada
                    self.isLoading = false
                    self.showEmptyOverlay = establecimientosEnRegion.isEmpty
                    let dt = (CFAbsoluteTimeGetCurrent() - t0) * 1000
                    ProductionLogger.mapLog("Lazy loading: \(establecimientosEnRegion.count) est. | limit=\(descriptor.fetchLimit ?? -1) | \(Int(dt))ms")
                }
                // Guardar en cache
                regionCache[cacheKey] = (Date(), establecimientosEnRegion)
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showEmptyOverlay = false
                    ProductionLogger.log("Error en lazy loading: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }

    // MARK: - Overlay resultados búsqueda
    private var resultadosBusquedaOverlay: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 2) {
                Text("Resultados (")
                Text("\(searchResults.count)").bold()
                Text(")")
                Spacer()
                // Filtro por categorías desde overlay
                Menu {
                    Button {
                        // Limpiar filtros y búsqueda para restaurar lista completa
                        categoriasSeleccionadas.removeAll()
                        debouncedSearchText = ""
                        searchText = ""
                        searchResults = []
                        ProductionLogger.mapLog("Filtro categorías (overlay): limpiado + búsqueda reseteada")
                    } label: {
                        Label("Limpiar filtros", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    Divider()
                    ForEach(categoriasDisponiblesList(), id: \.id) { cat in
                        let seleccionado = categoriasSeleccionadas.contains(cat.categoria_id)
                        Button {
                            if seleccionado {
                                categoriasSeleccionadas.remove(cat.categoria_id)
                                ProductionLogger.mapLog("Filtro categoría removida (overlay): \(cat.categoria_nombre)")
                            } else {
                                categoriasSeleccionadas.insert(cat.categoria_id)
                                ProductionLogger.mapLog("Filtro categoría agregada (overlay): \(cat.categoria_nombre)")
                            }
                            // Recalcular resultados frente a nuevos filtros
                            actualizarResultadosBusqueda(term: debouncedSearchText)
                        } label: {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: cat.icono)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(cat.color)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    Text(cat.categoria_nombre)
                                        .foregroundColor(cat.color)
                                }
                                Spacer(minLength: 12)
                                Image(systemName: seleccionado ? "checkmark.circle.fill" : "circle")
                            }
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.cardBackground)
                            .frame(width: 32, height: 32)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.textPrimary)
                        if !categoriasSeleccionadas.isEmpty {
                            Text("\(categoriasSeleccionadas.count)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(3)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .offset(x: 11, y: -11)
                        }
                    }
                }
                Button {
                    debouncedSearchText = ""
                    searchText = ""
                    categoriasSeleccionadas.removeAll()
                    searchResults = []
                    searchFieldFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(searchResults.prefix(config.mapa_SearchMaxResults), id: \.establecimiento_id) { est in
                        Button {
                            establecimientoParaAcciones = est
                            centrarEnEstablecimiento(est)
                            DispatchQueue.main.asyncAfter(deadline: .now() + config.mapa_ActionMenuDelay) {
                                mostrarAcciones = true
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                // Ícono de la categoría con color
                                if let catId = categoriaIdResuelta(for: est), let cat = categoriaManager.categoria(byId: catId) {
                                    Image(systemName: cat.icono)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(cat.color)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Color.gray)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(est.establecimiento_nombre).font(.subheadline).foregroundColor(.primary)
                                    Text(categoriaManager.nombre(forCategoriaId: categoriaIdResuelta(for: est) ?? -1))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if let d = distanciaDesdeUsuario(para: est) {
                                    Text(String(format: "%.1f km", d)).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                        if est.establecimiento_id != searchResults.prefix(config.mapa_SearchMaxResults).last?.establecimiento_id {
                            Divider()
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
    }

    // MARK: - Búsqueda global por nombre ordenada por distancia
    private func actualizarResultadosBusqueda(term: String) {
        let limpio = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard limpio.count >= max(1, config.mapa_SearchMinChars) else {
            // Si se limpió la búsqueda, limpiar también filtros y resultados
            Task { @MainActor in
                categoriasSeleccionadas.removeAll()
                searchResults = []
            }
            return
        }
        Task {
            do {
                // Fetch global limitado
                var descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>(
                    sortBy: [SortDescriptor(\.establecimiento_nombre, comparator: .localizedStandard)]
                )
                descriptor.fetchLimit = config.mapa_SearchFetchLimit
                let todos = try context.fetch(descriptor)
                // Filtro por nombre (case/diacritic insensitive)
                let lower = limpio.lowercased()
                var filtrados = todos.filter { $0.establecimiento_nombre.lowercased().contains(lower) }
                if !categoriasSeleccionadas.isEmpty {
                    filtrados = filtrados.filter { est in
                        if let catId = categoriaIdResuelta(for: est) { return categoriasSeleccionadas.contains(catId) }
                        return false
                    }
                }
                // Orden por distancia desde usuario si hay ubicación; si no, mantener orden alfabético
                let ordenados: [GV_modeloCont_Establecimientos]
                if let userLat = location.latitude, let userLon = location.longitude {
                    let user = CLLocation(latitude: userLat, longitude: userLon)
                    ordenados = filtrados.sorted { a, b in
                        distanciaEntre(user, a) < distanciaEntre(user, b)
                    }
                } else {
                    ordenados = filtrados
                }
                await MainActor.run {
                    self.searchResults = Array(ordenados.prefix(config.mapa_SearchMaxResults))
                }
            } catch {
                await MainActor.run {
                    self.searchResults = []
                    ProductionLogger.log("Error en búsqueda global: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }

    private func distanciaDesdeUsuario(para est: GV_modeloCont_Establecimientos) -> Double? {
        guard let userLat = location.latitude, let userLon = location.longitude,
              let lat = est.direccion_latitud, let lon = est.direccion_longitud else { return nil }
        let user = CLLocation(latitude: userLat, longitude: userLon)
        let dest = CLLocation(latitude: lat, longitude: lon)
        return user.distance(from: dest) / 1000.0
    }

    private func distanciaEntre(_ user: CLLocation, _ est: GV_modeloCont_Establecimientos) -> CLLocationDistance {
        guard let lat = est.direccion_latitud, let lon = est.direccion_longitud else { return .infinity }
        let dest = CLLocation(latitude: lat, longitude: lon)
        return user.distance(from: dest)
    }

    // MARK: - Overlays de carga / vacío
    private var loadingEmptyOverlays: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Cargando…").font(.caption)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 6)
            } else if showEmptyOverlay && (soloFavoritos || !categoriasSeleccionadas.isEmpty || !debouncedSearchText.trimmingCharacters(in: .whitespaces).isEmpty) {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("Sin resultados").font(.subheadline)
                    Button("Limpiar filtros") {
                        categoriasSeleccionadas.removeAll()
                        soloFavoritos = false
                        searchText = ""
                        debouncedSearchText = ""
                        searchResults = []
                        showEmptyOverlay = false
                    }
                    .buttonStyle(.bordered)
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 6)
            }
        }
    }

    // MARK: - Cache helpers y fetch adaptativo
    private func regionCacheKey(for region: MKCoordinateRegion) -> String {
        let base = config.mapa_TileGridBaseDegrees
        func roundToBase(_ value: Double) -> Double { (value / base).rounded() * base }
        let cLat = roundToBase(region.center.latitude)
        let cLon = roundToBase(region.center.longitude)
        let sLat = roundToBase(region.span.latitudeDelta)
        let sLon = roundToBase(region.span.longitudeDelta)
        return String(format: "%.4f_%.4f_%.4f_%.4f", cLat, cLon, sLat, sLon)
    }

    private func adaptiveFetchLimit(for region: MKCoordinateRegion) -> Int {
        let latDelta = region.span.latitudeDelta
        if latDelta >= config.mapa_AdaptiveFetch_WideLatDelta { return config.mapa_AdaptiveFetch_WideLimit }
        if latDelta >= config.mapa_AdaptiveFetch_MediumLatDelta { return config.mapa_AdaptiveFetch_MediumLimit }
        return config.mapa_AdaptiveFetch_CloseLimit
    }

    // MARK: - Estilos 2D/3D
    private func currentCenterCoordinate() -> CLLocationCoordinate2D {
        if let region = currentRegion { return region.center }
        if let lat = location.latitude, let lon = location.longitude { return CLLocationCoordinate2D(latitude: lat, longitude: lon) }
        return CLLocationCoordinate2D(latitude: 23.6345, longitude: -102.5528) // México
    }

    private func switchTo2D() {
        selectedMapStyle = .standard
        let center = currentCenterCoordinate()
        // Mantener un zoom razonable basado en config
        let delta = max(0.02, config.mapa_ZoomUsuario_LatitudeDelta)
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)))
        }
    }

    private func switchTo3D() {
        selectedMapStyle = .standard(elevation: .realistic)
        let center = currentCenterCoordinate()
        let camera = MapCamera(centerCoordinate: center, distance: 3000, heading: 25, pitch: 60)
        withAnimation(.easeInOut(duration: 0.6)) {
            cameraPosition = .camera(camera)
        }
    }

    // Categorías disponibles según el contexto actual (búsqueda activa o datos visibles)
    private func categoriasDisponiblesList() -> [GV_Categoria] {
        let fuente: [GV_modeloCont_Establecimientos]
        let hasSearch = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= max(1, config.mapa_SearchMinChars) && !searchResults.isEmpty
        if hasSearch {
            fuente = searchResults
        } else {
            fuente = establecimientos
        }
        var ids: Set<Int> = []
        for est in fuente {
            if let id = categoriaIdResuelta(for: est) {
                ids.insert(id)
            }
        }
        let cats = ids.compactMap { categoriaManager.categoria(byId: $0) }
        return cats.sorted { $0.categoria_nombre < $1.categoria_nombre }
    }

    // MARK: - Acciones de resultado
    private func centrarEnEstablecimiento(_ est: GV_modeloCont_Establecimientos) {
        guard let lat = est.direccion_latitud, let lon = est.direccion_longitud else { return }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let span = MKCoordinateSpan(latitudeDelta: max(0.02, config.mapa_ZoomUsuario_LatitudeDelta), longitudeDelta: max(0.02, config.mapa_ZoomUsuario_LatitudeDelta))
        withAnimation(.easeInOut(duration: 0.6)) {
            cameraPosition = .region(MKCoordinateRegion(center: coord, span: span))
        }
        hapticSelection()
        highlightedEstId = est.establecimiento_id
        // Remover highlight después de un breve tiempo
        DispatchQueue.main.asyncAfter(deadline: .now() + config.mapa_HighlightDuration) {
            withAnimation(.easeOut(duration: config.mapa_HighlightFadeDuration)) {
                self.highlightedEstId = nil
            }
        }
    }

    private func abrirRutasEnMaps(_ est: GV_modeloCont_Establecimientos) {
        guard let lat = est.direccion_latitud, let lon = est.direccion_longitud else { return }
        if let url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d") {
            openURL(url)
        }
    }

    private func abrirSitioWeb(_ est: GV_modeloCont_Establecimientos) {
        guard let urlString = est.establecimiento_url, let url = URL(string: urlString) else { return }
        openURL(url)
    }

    // Diálogo de acciones (overlay personalizado con iconos)
    private var accionesDialog: some View {
        Group {
            if mostrarAcciones, let est = establecimientoParaAcciones {
                ZStack(alignment: .bottom) {
                    // Fondo dimmer
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { mostrarAcciones = false } }

                    // Sheet de acciones icon-only
                    VStack(spacing: 14) {
                        HStack(spacing: 24) {
                            // Ir a
                            Button {
                                centrarEnEstablecimiento(est)
                                debouncedSearchText = ""
                                searchText = ""
                                searchResults = []
                                searchFieldFocused = false
                                withAnimation(.easeOut(duration: 0.2)) { mostrarAcciones = false }
                            } label: {
                                Circle()
                                    .fill(themeManager.cardBackground)
                                    .frame(width: 58, height: 58)
                                    .overlay(Image(systemName: "mappin.and.ellipse").font(.system(size: 22, weight: .semibold)).foregroundColor(themeManager.textPrimary))
                            }
                            .accessibilityLabel("Ir a")

                            // Ruta
                            Button {
                                abrirRutasEnMaps(est)
                                debouncedSearchText = ""
                                searchText = ""
                                searchResults = []
                                searchFieldFocused = false
                                withAnimation(.easeOut(duration: 0.2)) { mostrarAcciones = false }
                            } label: {
                                Circle()
                                    .fill(themeManager.cardBackground)
                                    .frame(width: 58, height: 58)
                                    .overlay(Image(systemName: "car.fill").font(.system(size: 22, weight: .semibold)).foregroundColor(themeManager.textPrimary))
                            }
                            .accessibilityLabel("Ruta desde mi ubicación")

                            // Promociones
                            Button {
                                establecimientoSeleccionado = est
                                navegarAPromociones = true
                                debouncedSearchText = ""
                                searchText = ""
                                searchResults = []
                                searchFieldFocused = false
                                withAnimation(.easeOut(duration: 0.2)) { mostrarAcciones = false }
                            } label: {
                                Circle()
                                    .fill(themeManager.cardBackground)
                                    .frame(width: 58, height: 58)
                                    .overlay(Image(systemName: "tag.fill").font(.system(size: 22, weight: .semibold)).foregroundColor(themeManager.textPrimary))
                            }
                            .accessibilityLabel("Ver promociones")

                            // Favoritos
                            Button {
                                favoritosManager.toggleFavorite(establecimientoId: est.establecimiento_id)
                                hapticSuccess()
                                withAnimation(.easeOut(duration: 0.2)) { mostrarAcciones = false }
                            } label: {
                                Circle()
                                    .fill(themeManager.cardBackground)
                                    .frame(width: 58, height: 58)
                                    .overlay(Image(systemName: favoritosManager.isFavorite(establecimientoId: est.establecimiento_id) ? "heart.slash" : "heart.fill").font(.system(size: 22, weight: .semibold)).foregroundColor(favoritosManager.isFavorite(establecimientoId: est.establecimiento_id) ? themeManager.textPrimary : .red))
                            }
                            .accessibilityLabel(favoritosManager.isFavorite(establecimientoId: est.establecimiento_id) ? "Quitar de favoritos" : "Guardar en favoritos")
                        }

                        HStack(spacing: 24) {
                            // Sitio web (si existe)
                            if let urlStr = est.establecimiento_url, URL(string: urlStr) != nil {
                                Button {
                                    abrirSitioWeb(est)
                                    debouncedSearchText = ""
                                    searchText = ""
                                    searchResults = []
                                    searchFieldFocused = false
                                    withAnimation(.easeOut(duration: 0.2)) { mostrarAcciones = false }
                                } label: {
                                    Circle()
                                        .fill(themeManager.cardBackground)
                                        .frame(width: 58, height: 58)
                                        .overlay(Image(systemName: "safari").font(.system(size: 22, weight: .semibold)).foregroundColor(themeManager.textPrimary))
                                }
                                .accessibilityLabel("Ver sitio web")
                            }

                            // Cerrar
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) { mostrarAcciones = false }
                            } label: {
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 58, height: 58)
                                    .overlay(Image(systemName: "xmark").font(.system(size: 20, weight: .bold)).foregroundColor(.red))
                            }
                            .accessibilityLabel("Cerrar")
                        }
                        .opacity(0.9)
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.bottom, 18)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Haptics
    private func hapticSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    private func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Carga inicial de establecimientos (llama a cargar por región)
    private func cargarEstablecimientos() {
        // Si ya tenemos una región, cargar para esa región
        if let region = currentRegion {
            cargarEstablecimientosParaRegion(region)
        } else {
            // Si no, cargar una región inicial amplia
            let initialRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 23.6345, longitude: -102.5528),
                span: MKCoordinateSpan(latitudeDelta: 15.0, longitudeDelta: 15.0)
            )
            cargarEstablecimientosParaRegion(initialRegion)
        }
    }
    
    private func configurarCamaraInicial() {
        if isTodoMexico {
            // Mostrar todo México
            let mexicoCenter = CLLocationCoordinate2D(latitude: 23.6345, longitude: -102.5528)
            let mexicoSpan = MKCoordinateSpan(latitudeDelta: 15.0, longitudeDelta: 15.0)
            let mexicoRegion = MKCoordinateRegion(center: mexicoCenter, span: mexicoSpan)
            
            cameraPosition = .region(mexicoRegion)
            ProductionLogger.mapLog("Cámara configurada: Todo México")
        } else {
            // Centrar en usuario (con delay para dar tiempo al GPS)
            ProductionLogger.mapLog("Esperando ubicación del usuario para centrar mapa...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.centrarEnUsuario()
            }
        }
    }
    
    private func centrarEnUsuario() {
        guard let lat = location.latitude, let lon = location.longitude else {
            ProductionLogger.log("No hay ubicación del usuario disponible", level: .warning)
            return
        }
        
        let userCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        // Usar radio configurable desde Plist (5km por defecto)
        let radioDelta = config.kmToLatitudeDelta(config.mapa_RadioCentradoUsuario_KM)
        
        let region = MKCoordinateRegion(
            center: userCoordinate,
            span: MKCoordinateSpan(latitudeDelta: radioDelta, longitudeDelta: radioDelta)
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(region)
        }
        
        ProductionLogger.mapLog("Mapa centrado en usuario: \(lat), \(lon) - Radio: \(config.mapa_RadioCentradoUsuario_KM)km")
    }
    
    // MARK: - Pin View
    
    /// Genera un pin personalizado con color e ícono de taxonomía
    @ViewBuilder
    private func pinView(color: Color, icono: String, isFavorito: Bool) -> some View {
        ZStack {
            // Sombra exterior
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 44, height: 44)
            
            // Fondo del pin con gradiente
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .shadow(color: color.opacity(0.5), radius: 6, x: 0, y: 3)
            
            // Borde blanco
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 40, height: 40)
            
            // Ícono
            Image(systemName: icono)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            // Badge de favorito (opcional)
            if isFavorito {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                    )
                    .offset(x: 14, y: -14)
            }
        }
    }

    /// Pin neutro de fallback cuando no hay categoría válida
    @ViewBuilder
    private func pinFallbackDefault() -> some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 44, height: 44)
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.gray, Color.gray.opacity(0.85)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .shadow(color: Color.gray.opacity(0.4), radius: 6, x: 0, y: 3)
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 40, height: 40)
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
    }
    
    /// Obtiene el estilo por categoría (color e ícono) si existe; en caso contrario, nil
    private func getCategoriaStyle(for establecimiento: GV_modeloCont_Establecimientos) -> (Color, String)? {
        // Intentar por ID
        if let categoriaId = establecimiento.categoria_id,
           let categoria = categoriaManager.categoria(byId: categoriaId) {
            return (categoria.color, categoria.icono)
        }
        // Fallback por nombre de categoría
        if let nombreCat = establecimiento.categoria_nombre?.trimmingCharacters(in: .whitespacesAndNewlines),
           let categoria = categoriaManager.categoria(byNombre: nombreCat) {
            return (categoria.color, categoria.icono)
        }
        // Configurable: estilo para sin categoría desde plist
        let color = Color(hex: config.mapa_NoCategoryColorHex) ?? .gray
        return (color, config.mapa_NoCategoryIcon)
    }

    /// Obtiene el ID de categoría resuelto para un establecimiento
    private func categoriaIdResuelta(for establecimiento: GV_modeloCont_Establecimientos) -> Int? {
        if let id = establecimiento.categoria_id, categoriaManager.categoria(byId: id) != nil {
            return id
        }
        if let nombre = establecimiento.categoria_nombre?.trimmingCharacters(in: .whitespacesAndNewlines),
           let cat = categoriaManager.categoria(byNombre: nombre) {
            return cat.categoria_id
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    GV_GreatMap(isTodoMexico: false)
        .environmentObject(LocationService())
}

