//
//  GV_SCR_vg_EstablecimientosListaView.swift
//  limpioCS
//
//  Migrado: 2025-01-10
//  Sistema: GV (Temas + Headers + Menús + ScreenTypes)
//

import SwiftUI
import SwiftData
import CoreLocation
import UIKit

// MARK: - Sistema de Caché de Distancias
/// Caché inteligente que NO modifica estado durante renders
class DistanceCache {
    var cache: [Int: Double] = [:]
    var lastUserLocation: CLLocationCoordinate2D?
    var invalidationThreshold: Double = 100.0 // metros
    
    /// Obtiene distancia con caché automático
    func getDistance(
        forEstablecimientoId id: Int,
        userLocation: CLLocationCoordinate2D?,
        estLocation: CLLocationCoordinate2D?,
        calculator: () -> Double
    ) -> Double {
        // Verificar si necesitamos invalidar el caché
        if let userLoc = userLocation {
            checkAndInvalidateCache(newUserLocation: userLoc)
        }
        
        // Buscar en caché
        if let cached = cache[id] {
            return cached
        }
        
        // Calcular y cachear
        let distance = calculator()
        cache[id] = distance
        return distance
    }
    
    /// Invalida caché si el usuario se movió >100m
    func checkAndInvalidateCache(newUserLocation: CLLocationCoordinate2D) {
        guard let lastLoc = lastUserLocation else {
            lastUserLocation = newUserLocation
            return
        }
        
        let location1 = CLLocation(latitude: lastLoc.latitude, longitude: lastLoc.longitude)
        let location2 = CLLocation(latitude: newUserLocation.latitude, longitude: newUserLocation.longitude)
        let distance = location1.distance(from: location2)
        
        if distance > invalidationThreshold {
            cache.removeAll()
            lastUserLocation = newUserLocation
        }
    }
    
    /// Limpia el caché manualmente
    func clear() {
        cache.removeAll()
        lastUserLocation = nil
    }
}

struct GV_SCR_vg_EstablecimientosListaView: View {
    // MARK: - Configuración del Sistema GV
    private let screenType: ScreenType = .general
    private let myHeader: GV_HeaderType = .tipo2
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    private let categoriaManager = GV_CategoriaManager.shared
    private let config = GV_ConfiguracionesGenerales.shared
    
    // MARK: - Estados
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var showFavoritesOnly = false
    @State private var categoriasSeleccionadas: Set<Int> = []
    @State private var selectedEst: GV_modeloCont_Establecimientos? = nil
    @State private var showActions = false
    @State private var searchDebounceTask: Task<Void, Never>? = nil
    @State private var showCategorySheet = false
    
    // MARK: - Paginación
    @State private var itemsToShow = 50
    @State private var isLoadingMore = false
    
    // MARK: - Caché de distancias (State con clase simple)
    @State private var distanceCache = DistanceCache()
    
    @Query private var all: [GV_modeloCont_Establecimientos]
    
    // MARK: - Managers
    @ObservedObject private var favoritosManager = GV_FavoritosManager.shared
    @EnvironmentObject private var locationService: LocationService
    
    // MARK: - Data completa (sin paginar)
    private var allFilteredData: [GV_modeloCont_Establecimientos] {
        // Favoritos
        var resultado = showFavoritesOnly ? all.filter { favoritosManager.isFavorite(establecimientoId: $0.establecimiento_id) } : all
        // Filtro por categorías (por ID resuelto)
        if !categoriasSeleccionadas.isEmpty {
            resultado = resultado.filter { est in
                if let id = categoriaIdResuelta(for: est) { return categoriasSeleccionadas.contains(id) }
                return false
            }
        }
        // Búsqueda por nombre con debounce
        let minChars = max(1, config.lista_SearchMinChars)
        let term = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if term.count >= minChars {
            let lower = term.lowercased()
            resultado = resultado.filter { $0.establecimiento_nombre.lowercased().contains(lower) }
        }
        
        // Ordenar por distancia usando caché externo (no modifica @State)
        let userCoord: CLLocationCoordinate2D? = {
            guard let lat = locationService.latitude, let lon = locationService.longitude else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }()
        
        let sortedData = resultado.sorted { est1, est2 in
            let distancia1 = obtenerDistanciaConCache(establecimiento: est1, userLocation: userCoord)
            let distancia2 = obtenerDistanciaConCache(establecimiento: est2, userLocation: userCoord)
            return distancia1 < distancia2
        }
        
        return sortedData
    }
    
    // MARK: - Data paginada (lo que realmente se muestra)
    private var data: [GV_modeloCont_Establecimientos] {
        let totalData = allFilteredData
        let cap = config.lista_SearchMaxResults
        let maxItems = min(cap, itemsToShow, totalData.count)
        return Array(totalData.prefix(maxItems))
    }
    
    // MARK: - Info de paginación
    private var hasMoreItems: Bool { false }
    
    private var totalItemsCount: Int {
        allFilteredData.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header con menú - TODO EN UNA SOLA LÍNEA! 🎯
            myHeader.headerViewWithMenu("Participantes", nil, .principal)
            
            // Contenido principal con tema aplicado
            VStack(spacing: 0) {
                // Barra de búsqueda y controles
                VStack(spacing: themeManager.spacing) {
                    HStack(spacing: 12) {
                        // Barra de búsqueda
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(themeManager.textSecondary)
                            
                            TextField("Buscar por nombre o categoría...", text: $searchText)
                                .textFieldStyle(.plain)
                                .foregroundColor(themeManager.textPrimary)
                                .onChange(of: searchText) { _, newValue in
                                    // Debounce controlado por plist
                                    itemsToShow = config.mapa_SearchMaxResults
                                    searchDebounceTask?.cancel()
                                    searchDebounceTask = Task {
                                        try? await Task.sleep(nanoseconds: UInt64(config.lista_SearchDebounceTime * 1_000_000_000))
                                        guard !Task.isCancelled else { return }
                                        await MainActor.run { debouncedSearchText = newValue }
                                    }
                                }
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                    debouncedSearchText = ""
                                    categoriasSeleccionadas.removeAll()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(themeManager.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                                .fill(themeManager.cardBackground)
                                .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 2)
                        )
                        
                        // Filtro por categorías (abre sheet persistente)
                        Button { showCategorySheet = true } label: {
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
                        
                        // Botón para obtener ubicación
                        Button {
                            locationService.start()
                        } label: {
                            Image(systemName: (locationService.latitude != nil && locationService.longitude != nil) ? "checkmark.circle.fill" : "location.circle.fill")
                                .font(themeManager.title)
                                .foregroundColor((locationService.latitude != nil && locationService.longitude != nil) ? themeManager.success : themeManager.textSecondary)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(themeManager.cardBackground)
                                        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 2)
                                )
                        }
                        
                        // Toggle de favoritos (corazón)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showFavoritesOnly.toggle()
                                // Reset paginación cuando cambia filtro
                                itemsToShow = config.lista_SearchMaxResults
                            }
                        } label: {
                            Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                                .font(themeManager.title)
                                .foregroundColor(showFavoritesOnly ? .red : themeManager.textSecondary)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(themeManager.cardBackground)
                                        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 2)
                                )
                        }
                    }
                }
                .padding(.horizontal, themeManager.paddingMedium)
                .padding(.top, themeManager.paddingMedium)
                .padding(.bottom, themeManager.spacing)
                .background(themeManager.background)
                
                // Indicador de estado de ubicación (mostrar solo cuando no está disponible)
                if locationService.latitude == nil || locationService.longitude == nil {
                    HStack {
                        Image(systemName: "location.slash.circle.fill")
                            .foregroundColor(themeManager.warning)
                        Text("Obteniendo ubicación...")
                            .font(.caption)
                            .foregroundColor(themeManager.warning)
                        Spacer()
                    }
                    .padding(.horizontal, themeManager.paddingMedium)
                    .padding(.bottom, 8)
                }
                
                // Lista de participantes
                Group {
                    if data.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: searchText.isEmpty ? 
                                (showFavoritesOnly ? "star" : "building.2") :
                                "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(themeManager.textSecondary.opacity(0.3))
                            
                            VStack(spacing: 8) {
                                Text(searchText.isEmpty ? 
                                    (showFavoritesOnly ? "Aún no tienes favoritos" : "Sin registros") :
                                    "Sin resultados")
                                    .font(themeManager.title)
                                    .foregroundColor(themeManager.textPrimary)
                                
                                Text(searchText.isEmpty ? 
                                    (showFavoritesOnly ? "Marca participantes con la estrella para verlos aquí." : "Aún no hay participantes en la base local.") :
                                    "Intenta con otros términos de búsqueda.")
                                    .font(themeManager.body)
                                    .foregroundColor(themeManager.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: config.lista_RowSpacing) {
                                ForEach(Array(data.enumerated()), id: \.element.id) { index, est in
                                    Button {
                                        selectedEst = est
                                        showActions = true
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 8) {
                                                if let id = categoriaIdResuelta(for: est), let cat = categoriaManager.categoria(byId: id) {
                                                    Image(systemName: cat.icono)
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .padding(6)
                                                        .background(cat.color)
                                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                                } else {
                                                    let color = Color(hex: config.lista_NoCategoryColorHex) ?? .gray
                                                    Image(systemName: config.lista_NoCategoryIcon)
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .padding(6)
                                                        .background(color)
                                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                                }
                                                Text(est.establecimiento_nombre)
                                                    .font(themeManager.body)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(themeManager.textPrimary)
                                                Spacer()
                                                if let d = distanciaDesdeUsuario(para: est) {
                                                    Text(String(format: "%.1f km", d)).font(.caption).foregroundColor(themeManager.textSecondary)
                                                }
                                                if favoritosManager.isFavorite(establecimientoId: est.establecimiento_id) {
                                                    Image(systemName: "heart.fill").foregroundColor(.red).font(.caption)
                                                }
                                            }
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(themeManager.cardBackground)
                                        .cornerRadius(themeManager.cornerRadius)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, themeManager.paddingMedium)
                                    .onAppear {
                                        // Cargar más items cuando llegue cerca del final
                                        if index == data.count - 5 && hasMoreItems && !isLoadingMore {
                                            loadMoreItems()
                                        }
                                    }
                                }
                                
                                // Indicador de carga al final
                                if hasMoreItems {
                                    HStack(spacing: 12) {
                                        if isLoadingMore {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        }
                                        
                                        Text(isLoadingMore ? "Cargando más..." : "Mostrando \(data.count) de \(totalItemsCount)")
                                            .font(.caption)
                                            .foregroundColor(themeManager.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                }
                            }
                            .padding(.vertical, themeManager.spacing)
                        }
                    }
                }
            }
        }
        .background(themeManager.background)
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
        .navigationBarHidden(true)
        .overlay(
            GV_ActionOverlay(
                isPresented: $showActions,
                showWebsite: (selectedEst?.establecimiento_url?.isEmpty == false),
                isFavorite: selectedEst.map { favoritosManager.isFavorite(establecimientoId: $0.establecimiento_id) } ?? false,
                onGo: { if let est = selectedEst { irA(est) } },
                onRoute: { if let est = selectedEst { rutaA(est) } },
                onPromos: { /* navegación externa si aplica */ },
                onToggleFavorite: { if let est = selectedEst { favoritosManager.toggleFavorite(establecimientoId: est.establecimiento_id); hapticSuccess() } },
                onWebsite: { if let est = selectedEst { abrirSitioWeb(est) } }
            )
        )
        .sheet(isPresented: $showCategorySheet) { categoriaSheet }
        .onAppear {
            // Homologar con SearchMaxResults del mapa
            itemsToShow = config.lista_SearchMaxResults
            distanceCache.invalidationThreshold = config.lista_DistanceCacheInvalidationMeters
        }
    }
    
    // MARK: - Paginación Functions
    
    /// Carga más items progresivamente
    private func loadMoreItems() {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        
        // Simular un pequeño delay para UX suave
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                itemsToShow += 50
                isLoadingMore = false
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Obtiene distancia usando el sistema de caché externo (DistanceCache)
    private func obtenerDistanciaConCache(
        establecimiento: GV_modeloCont_Establecimientos,
        userLocation: CLLocationCoordinate2D?
    ) -> Double {
        let estLocation: CLLocationCoordinate2D? = {
            guard let lat = establecimiento.direccion_latitud,
                  let lon = establecimiento.direccion_longitud else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }()
        
        return distanceCache.getDistance(
            forEstablecimientoId: establecimiento.establecimiento_id,
            userLocation: userLocation,
            estLocation: estLocation
        ) {
            // Closure que calcula la distancia solo si no está en caché
            calcularDistanciaHaversine(userLocation: userLocation, estLocation: estLocation)
        }
    }
    
    /// Calcula la distancia usando fórmula de Haversine
    private func calcularDistanciaHaversine(
        userLocation: CLLocationCoordinate2D?,
        estLocation: CLLocationCoordinate2D?
    ) -> Double {
        guard let userLoc = userLocation,
              let estLoc = estLocation else {
            return Double.infinity
        }
        
        let earthRadius: Double = 6371 // km
        
        let lat1Rad = userLoc.latitude * .pi / 180
        let lon1Rad = userLoc.longitude * .pi / 180
        let lat2Rad = estLoc.latitude * .pi / 180
        let lon2Rad = estLoc.longitude * .pi / 180
        
        let dLat = lat2Rad - lat1Rad
        let dLon = lon2Rad - lon1Rad
        
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
    
    // Overlay ahora es componente reutilizable GV_ActionOverlay

    // MARK: - Sheet de categorías persistente
    private var categoriaSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section("Categorías") {
                        ForEach(categoriasDisponiblesList(), id: \.id) { cat in
                            let seleccionado = categoriasSeleccionadas.contains(cat.categoria_id)
                            HStack {
                                Image(systemName: cat.icono)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(cat.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Text(cat.categoria_nombre)
                                    .foregroundColor(cat.color)
                                Spacer()
                                Image(systemName: seleccionado ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(seleccionado ? themeManager.accent : themeManager.textSecondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if seleccionado { categoriasSeleccionadas.remove(cat.categoria_id) }
                                else { categoriasSeleccionadas.insert(cat.categoria_id) }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Filtros")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Limpiar") { categoriasSeleccionadas.removeAll() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") { showCategorySheet = false }
                }
            }
        }
    }

    // MARK: - Filtros dinámicos por categoría
    private func categoriasDisponiblesList() -> [GV_Categoria] {
        let minChars = max(1, config.lista_SearchMinChars)
        let term = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let fuente: [GV_modeloCont_Establecimientos]
        if term.count >= minChars {
            fuente = all.filter { $0.establecimiento_nombre.lowercased().contains(term) }
        } else {
            fuente = all
        }
        var ids: Set<Int> = []
        for est in fuente { if let id = categoriaIdResuelta(for: est) { ids.insert(id) } }
        return ids.compactMap { categoriaManager.categoria(byId: $0) }.sorted { $0.categoria_nombre < $1.categoria_nombre }
    }

    private func categoriaIdResuelta(for est: GV_modeloCont_Establecimientos) -> Int? {
        if let id = est.categoria_id, categoriaManager.categoria(byId: id) != nil { return id }
        if let nombre = est.categoria_nombre, let cat = categoriaManager.categoria(byNombre: nombre) { return cat.categoria_id }
        return nil
    }

    private func distanciaDesdeUsuario(para est: GV_modeloCont_Establecimientos) -> Double? {
        guard let userLat = locationService.latitude, let userLon = locationService.longitude,
              let lat = est.direccion_latitud, let lon = est.direccion_longitud else { return nil }
        let user = CLLocation(latitude: userLat, longitude: userLon)
        let dest = CLLocation(latitude: lat, longitude: lon)
        return user.distance(from: dest) / 1000.0
    }

    // MARK: - Acciones
    private func irA(_ est: GV_modeloCont_Establecimientos) {
        hapticSelection()
        // Comportamiento mínimo: abrir ruta como “Ir a”
        rutaA(est)
    }
    private func rutaA(_ est: GV_modeloCont_Establecimientos) {
        guard let lat = est.direccion_latitud, let lon = est.direccion_longitud,
              let url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d") else { return }
        UIApplication.shared.open(url)
    }
    private func abrirSitioWeb(_ est: GV_modeloCont_Establecimientos) {
        guard let s = est.establecimiento_url, let url = URL(string: s) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Haptics
    private func hapticSelection() { let g = UISelectionFeedbackGenerator(); g.prepare(); g.selectionChanged() }
    private func hapticSuccess() { let g = UINotificationFeedbackGenerator(); g.prepare(); g.notificationOccurred(.success) }
}

#Preview {
    NavigationStack {
        GV_SCR_vg_EstablecimientosListaView()
            .environmentObject(LocationService())
    }
}
