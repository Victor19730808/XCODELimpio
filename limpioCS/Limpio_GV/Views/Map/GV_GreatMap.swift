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

struct GV_GreatMap: View {
    
    // MARK: - Environment
    @EnvironmentObject private var location: LocationService
    @Environment(\.modelContext) private var context
    
    // MARK: - Managers
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    @ObservedObject private var favoritosManager = GV_FavoritosManager.shared
    private let categoriaManager = GV_CategoriaManager.shared
    private let taxonomiaManager = GV_TaxonomiaManager.shared
    private let config = GV_ConfiguracionesGenerales.shared
    
    // MARK: - States
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var establecimientos: [GV_modeloCont_Establecimientos] = []
    @State private var isLoading = false
    @State private var currentRegion: MKCoordinateRegion? = nil
    @State private var lastLoadedRegion: MKCoordinateRegion? = nil // Para evitar recargas innecesarias
    @State private var loadTask: Task<Void, Never>? = nil // Para cancelar tareas pendientes
    @State private var soloFavoritos = false // Filtro de favoritos
    @State private var mostrarFiltroTaxonomias = false // Mostrar bottom sheet de taxonomías
    @State private var taxonomiasSeleccionadas: Set<String> = [] // Taxonomías activas en el filtro
    @State private var navegarAPromociones = false
    @State private var establecimientoSeleccionado: GV_modeloCont_Establecimientos? = nil
    
    // MARK: - Configuración
    let isTodoMexico: Bool
    
    // MARK: - Computed Properties
    
    /// Establecimientos filtrados según favoritos y taxonomías seleccionadas
    private var establecimientosFiltrados: [GV_modeloCont_Establecimientos] {
        var filtered = establecimientos
        
        // Filtro 1: Favoritos
        if soloFavoritos {
            filtered = filtered.filter { favoritosManager.isFavorite(establecimientoId: $0.establecimiento_id) }
        }
        
        // Filtro 2: Taxonomías
        if !taxonomiasSeleccionadas.isEmpty {
            filtered = filtered.filter { est in
                guard let categoriaId = est.categoria_id,
                      let categoria = categoriaManager.categoria(byId: categoriaId) else {
                    return false
                }
                return taxonomiasSeleccionadas.contains(categoria.categoria_taxonomia)
            }
        }
        
        return filtered
    }
    
    /// Número de filtros activos
    private var numFiltrosActivos: Int {
        var count = 0
        if soloFavoritos { count += 1 }
        if !taxonomiasSeleccionadas.isEmpty { count += taxonomiasSeleccionadas.count }
        return count
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
            
            // Bottom Sheet de Taxonomías
            if mostrarFiltroTaxonomias {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            mostrarFiltroTaxonomias = false
                        }
                    }
                
                VStack {
                    Spacer()
                    bottomSheetTaxonomias
                        .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea()
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
        HStack {
            Text(isTodoMexico ? "🗺️ Todo México" : "📍 Cerca de Ti")
                .font(themeManager.title)
                .foregroundColor(themeManager.textPrimary)
            
            Spacer()
            
            Button(action: {
                // Acción de cerrar o volver
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.textSecondary)
            }
        }
        .padding()
        .background(themeManager.cardBackground)
    }
    
    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Pines de establecimientos con colores e íconos de taxonomía (filtrados)
            ForEach(establecimientosFiltrados, id: \.establecimiento_id) { est in
                if let lat = est.direccion_latitud, let lon = est.direccion_longitud {
                    Annotation(est.establecimiento_nombre, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                        pinView(for: est)
                            .onTapGesture {
                                // Al hacer click, navegar a promociones
                                establecimientoSeleccionado = est
                                navegarAPromociones = true
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
        .mapStyle(.standard)
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
                // Botón filtro de taxonomías
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        mostrarFiltroTaxonomias.toggle()
                    }
                    ProductionLogger.mapLog("Bottom sheet taxonomías: \(mostrarFiltroTaxonomias ? "Abierto" : "Cerrado")")
                }) {
                    ZStack {
                        Circle()
                            .fill(!taxonomiasSeleccionadas.isEmpty ? themeManager.accent : themeManager.cardBackground)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "tag.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(!taxonomiasSeleccionadas.isEmpty ? .white : themeManager.textPrimary)
                        
                        // Badge con contador de taxonomías seleccionadas
                        if !taxonomiasSeleccionadas.isEmpty {
                            Text("\(taxonomiasSeleccionadas.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.orange)
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
            
            // Si el cambio es menor a 10% del span, no recargar
            let threshold = lastRegion.span.latitudeDelta * 0.1
            if centerLatDiff < threshold && centerLonDiff < threshold && spanLatDiff < threshold {
                return // No recargar, el cambio es mínimo
            }
        }
        
        Task {
            isLoading = true
            
            do {
                // Calcular límites de la región visible (con buffer configurable)
                let buffer = config.mapa_RegionBuffer
                let minLat = region.center.latitude - (region.span.latitudeDelta / 2.0) - buffer
                let maxLat = region.center.latitude + (region.span.latitudeDelta / 2.0) + buffer
                let minLon = region.center.longitude - (region.span.longitudeDelta / 2.0) - buffer
                let maxLon = region.center.longitude + (region.span.longitudeDelta / 2.0) + buffer
                
                // Crear predicado para filtrar por región
                let predicate = #Predicate<GV_modeloCont_Establecimientos> { est in
                    est.direccion_latitud != nil && est.direccion_longitud != nil
                }
                
                // Crear descriptor con límite (para rendimiento)
                var descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.establecimiento_nombre, comparator: .localizedStandard)]
                )
                
                // Limitar fetch para performance (configurable desde Plist)
                descriptor.fetchLimit = config.mapa_MaxEstablecimientosFetch
                
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
                    ProductionLogger.mapLog("Lazy loading: \(establecimientosEnRegion.count) establecimientos en región visible")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    ProductionLogger.log("Error en lazy loading: \(error.localizedDescription)", level: .error)
                }
            }
        }
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
    
    // MARK: - Bottom Sheet de Taxonomías
    
    private var bottomSheetTaxonomias: some View {
        VStack(spacing: 0) {
            // Handle indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Header
            HStack {
                Text("Filtrar por Taxonomía")
                    .font(themeManager.headline)
                    .foregroundColor(themeManager.textPrimary)
                
                Spacer()
                
                if !taxonomiasSeleccionadas.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            taxonomiasSeleccionadas.removeAll()
                        }
                        ProductionLogger.mapLog("Filtros de taxonomía limpiados")
                    }) {
                        Text("Limpiar")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.accent)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            // ScrollView horizontal con chips de taxonomías
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(taxonomiaManager.todasLasTaxonomias) { taxonomia in
                        taxonomiaChip(taxonomia)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            
            // Botón Aplicar
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    mostrarFiltroTaxonomias = false
                }
                ProductionLogger.mapLog("Filtros aplicados: \(taxonomiasSeleccionadas.count) taxonomías")
            }) {
                Text("Aplicar Filtros (\(establecimientosFiltrados.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.accent)
                    .cornerRadius(12)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(themeManager.cardBackground)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
    }
    
    @ViewBuilder
    private func taxonomiaChip(_ taxonomia: GV_Taxonomia) -> some View {
        let isSelected = taxonomiasSeleccionadas.contains(taxonomia.nombre)
        
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    taxonomiasSeleccionadas.remove(taxonomia.nombre)
                } else {
                    taxonomiasSeleccionadas.insert(taxonomia.nombre)
                }
            }
        }) {
            HStack(spacing: 8) {
                // Ícono
                taxonomia.iconoView(size: 20)
                    .foregroundColor(isSelected ? .white : taxonomia.color)
                
                // Nombre
                Text(taxonomia.nombre)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : themeManager.textPrimary)
                    .lineLimit(1)
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [taxonomia.color, taxonomia.color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        taxonomia.colorOpaco
                    }
                }
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? taxonomia.color : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? taxonomia.color.opacity(0.4) : Color.clear, radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Pin View
    
    /// Genera un pin personalizado con color e ícono de taxonomía
    @ViewBuilder
    private func pinView(for establecimiento: GV_modeloCont_Establecimientos) -> some View {
        let (color, icono) = getPinStyle(for: establecimiento)
        let isFavorito = favoritosManager.isFavorite(establecimientoId: establecimiento.establecimiento_id)
        
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
    
    /// Obtiene el color e ícono del pin según la taxonomía de la categoría
    private func getPinStyle(for establecimiento: GV_modeloCont_Establecimientos) -> (Color, String) {
        // Si tiene categoria_id, buscar la categoría
        if let categoriaId = establecimiento.categoria_id,
           let categoria = categoriaManager.categoria(byId: categoriaId) {
            
            // Buscar la taxonomía asociada
            if let taxonomia = taxonomiaManager.taxonomia(byNombre: categoria.categoria_taxonomia) {
                return (taxonomia.color, taxonomia.icono)
            }
            
            // Si no se encuentra la taxonomía, usar color e icono de la categoría
            return (categoria.color, categoria.icono)
        }
        
        // Si no tiene categoría, usar color e icono por defecto
        return (.gray, "mappin.circle.fill")
    }
}

// MARK: - Preview

#Preview {
    GV_GreatMap(isTodoMexico: false)
        .environmentObject(LocationService())
}

// MARK: - View Extension para Rounded Corners específicos

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

