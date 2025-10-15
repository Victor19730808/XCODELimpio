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

// MARK: - Sistema de Caché de Distancias
/// Caché inteligente que NO modifica estado durante renders
class DistanceCache {
    var cache: [Int: Double] = [:]
    var lastUserLocation: CLLocationCoordinate2D?
    let invalidationThreshold: Double = 100.0 // metros
    
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
    
    // MARK: - Estados
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    
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
        // Filtrar por favoritos si está activado
        let baseData = showFavoritesOnly ? all.filter { favoritosManager.isFavorite(establecimientoId: $0.establecimiento_id) } : all
        
        // Filtrar por búsqueda
        let filteredData: [GV_modeloCont_Establecimientos]
        if searchText.isEmpty {
            filteredData = baseData
        } else {
            filteredData = baseData.filter { est in
                let nombreMatch = est.establecimiento_nombre.localizedCaseInsensitiveContains(searchText)
                let categoriaMatch = est.categoria_nombre?.localizedCaseInsensitiveContains(searchText) == true
                let municipioMatch = est.direccion_municipio?.localizedCaseInsensitiveContains(searchText) == true
                let estadoMatch = est.direccion_estado?.localizedCaseInsensitiveContains(searchText) == true
                return nombreMatch || categoriaMatch || municipioMatch || estadoMatch
            }
        }
        
        // Ordenar por distancia usando caché externo (no modifica @State)
        let userCoord: CLLocationCoordinate2D? = {
            guard let lat = locationService.latitude, let lon = locationService.longitude else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }()
        
        let sortedData = filteredData.sorted { est1, est2 in
            let distancia1 = obtenerDistanciaConCache(establecimiento: est1, userLocation: userCoord)
            let distancia2 = obtenerDistanciaConCache(establecimiento: est2, userLocation: userCoord)
            return distancia1 < distancia2
        }
        
        return sortedData
    }
    
    // MARK: - Data paginada (lo que realmente se muestra)
    private var data: [GV_modeloCont_Establecimientos] {
        let totalData = allFilteredData
        let maxItems = min(itemsToShow, totalData.count)
        return Array(totalData.prefix(maxItems))
    }
    
    // MARK: - Info de paginación
    private var hasMoreItems: Bool {
        allFilteredData.count > itemsToShow
    }
    
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
                                .onChange(of: searchText) { _, _ in
                                    // Reset paginación cuando cambia búsqueda
                                    itemsToShow = 50
                                }
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
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
                        
                        // Botón para obtener ubicación
                        Button {
                            locationService.start()
                        } label: {
                            Image(systemName: "location.circle.fill")
                                .font(themeManager.title)
                                .foregroundColor(locationService.latitude != nil ? themeManager.primary : themeManager.textSecondary)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(themeManager.cardBackground)
                                        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 2)
                                )
                        }
                        
                        // Toggle de favoritos
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showFavoritesOnly.toggle()
                                // Reset paginación cuando cambia filtro
                                itemsToShow = 50
                            }
                        } label: {
                            Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                                .font(themeManager.title)
                                .foregroundColor(showFavoritesOnly ? themeManager.warning : themeManager.textSecondary)
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
                
                // Indicador de estado de ubicación
                if locationService.latitude != nil && locationService.longitude != nil {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(themeManager.success)
                        Text("Ubicación disponible")
                            .font(.caption)
                            .foregroundColor(themeManager.success)
                        Spacer()
                    }
                    .padding(.horizontal, themeManager.paddingMedium)
                    .padding(.bottom, 8)
                } else {
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
                            LazyVStack(spacing: themeManager.spacing) {
                                ForEach(Array(data.enumerated()), id: \.element.id) { index, est in
                                    // Vista simple temporal hasta reconstruir el componente
                                    NavigationLink(destination: GV_SRC_vg_EstablecimientoPromociones(establecimientoId: est.establecimiento_id)) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(est.establecimiento_nombre)
                                                .font(themeManager.body)
                                                .fontWeight(.bold)
                                                .foregroundColor(themeManager.textPrimary)
                                            
                                            HStack(spacing: 12) {
                                                if let estado = est.direccion_estado {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "location.fill")
                                                            .font(.caption)
                                                        Text(estado)
                                                    }
                                                    .font(themeManager.caption)
                                                    .foregroundColor(themeManager.textSecondary)
                                                }
                                                
                                                if let categoria = est.categoria_nombre {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "tag.fill")
                                                            .font(.caption)
                                                        Text(categoria)
                                                    }
                                                    .font(themeManager.caption)
                                                    .foregroundColor(themeManager.textSecondary)
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
}

#Preview {
    NavigationStack {
        GV_SCR_vg_EstablecimientosListaView()
            .environmentObject(LocationService())
    }
}
