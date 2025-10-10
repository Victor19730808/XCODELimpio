//
//  GV_SCR_vg_MapaCercanias.swift
//  limpioCS
//
//  Creado: 2025-01-10
//  Sistema: GV (Temas + Headers + Menús + ScreenTypes)
//  Funcionalidad: Mapa de cercanías - VERSIÓN LIMPIA
//
//  Created by Victor on 2025-01-10.
//  Copyright © 2025 Grupo VAL Human TECH. All rights reserved.
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct GV_SCR_vg_MapaCercanias: View {
    // MARK: - Configuración del Sistema GV
    private let screenType: ScreenType = .general
    private let myHeader: GV_HeaderType = .tipo2
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    // MARK: - Parámetros de configuración
    let isTodoMexico: Bool  // Si es true, inicia en modo "Todo México"
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var location: LocationService
    @Environment(\.modelContext) private var context
    
    // MARK: - SwiftData Query
    @Query(sort: [SortDescriptor(\lmpBDF_EstablecimientoLocal.nombre, comparator: .localizedStandard)])
    private var todosLosEstablecimientos: [lmpBDF_EstablecimientoLocal]
    
    // MARK: - Estado del Mapa
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.6345, longitude: -102.5528), // Centro de México
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedEstablecimiento: lmpBDF_EstablecimientoLocal? = nil
    @State private var selectedCluster: Cluster? = nil
    @State private var isLoading = false
    @State private var didAutocenter = false
    
    // MARK: - Filtros
    @State private var filtroRadioKm: Double = 20  // Cambiado a 20 km por defecto
    @State private var filtroNombre: String = ""
    @State private var soloFavoritos = false
    @State private var mostrarClusters = false  // Toggle para clusters
    @State private var usarColoresPorCategoria = false  // Toggle para colores por categoría
    @State private var categoriaSeleccionada: String? = nil  // Categoría filtrada (nil = todas)
    @State private var mostrarSelectorCategoria = false  // Sheet para seleccionar categoría
    @State private var mostrarQRSheet = false  // Sheet para mostrar código QR
    @State private var qrImage: UIImage? = nil  // Imagen del QR generado
    
    // MARK: - Clustering
    @State private var clusterRadius: Double = 0.01  // Radio para agrupar establecimientos (en grados)
    @State private var clusters: [Cluster] = []  // Clusters almacenados en estado para evitar parpadeos
    
    /// Establecimientos que no están agrupados en clusters
    private var establecimientosNoAgrupados: [lmpBDF_EstablecimientoLocal] {
        guard mostrarClusters else { return establecimientosFiltrados }
        
        let establecimientosEnClusters = Set(clusters.flatMap { $0.establecimientos })
        return establecimientosFiltrados.filter { !establecimientosEnClusters.contains($0) }
    }
    
    /// Obtiene los establecimientos visibles en la región actual del mapa
    private var establecimientosVisibles: [lmpBDF_EstablecimientoLocal] {
        let region = mapRegion
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        
        return establecimientosFiltrados.filter { establecimiento in
            guard let lat = establecimiento.lat, let lon = establecimiento.lon else { return false }
            return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
        }
    }
    
    // MARK: - Estados para vista de México
    @State private var isShowingFullMexico = false
    @State private var radioDisabled = false
    
    // MARK: - Computed Properties
    
    /// Radio actual fijo (0-50 km) basado en el centro de la cámara
    /// El filtro se aplica desde el centro actual del mapa (mapRegion.center)
    private var radioActual: Double {
        return filtroRadioKm
    }
    
    /// Establecimientos filtrados por radio, nombre, favoritos y categoría
    private var establecimientosFiltrados: [lmpBDF_EstablecimientoLocal] {
        return todosLosEstablecimientos.filter { establecimiento in
            // Filtro por favoritos
            if soloFavoritos && !establecimiento.esFavorito {
                return false
            }
            
            // Filtro por nombre
            if !filtroNombre.isEmpty {
                let nombreMatch = establecimiento.nombre.localizedCaseInsensitiveContains(filtroNombre)
                if !nombreMatch {
                    return false
                }
            }
            
            // Filtro por categoría
            if let categoriaFiltro = categoriaSeleccionada {
                if let categoria = establecimiento.categoria?.lowercased() {
                    if !categoria.contains(categoriaFiltro.lowercased()) {
                        return false
                    }
                } else {
                    return false // No tiene categoría
                }
            }
            
            return true
        }
    }
    
    var body: some View {
        ZStack {
            // Fondo con tema
            themeManager.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header con menú - TODO EN UNA SOLA LÍNEA! 🎯
                myHeader.headerViewWithMenu("Mapa de Cercanías", nil, .mapa)
                
                
                // Controles de filtro (simplificados - sin radio)
                FiltrosView(
                    filtroNombre: $filtroNombre,
                    soloFavoritos: $soloFavoritos,
                    mostrarClusters: $mostrarClusters,
                    usarColoresPorCategoria: $usarColoresPorCategoria,
                    categoriaSeleccionada: $categoriaSeleccionada,
                    mostrarSelectorCategoria: $mostrarSelectorCategoria,
                    onGenerarQR: {
                        generarCodigoQR()
                    },
                    themeManager: themeManager
                )
                
                // Mapa principal con iOS 17+ APIs
                ZStack {
                    Map(position: $cameraPosition) {
                        // 🗺️ MAPA CON ANNOTATIONS Y CLUSTERING
                        
                        // Pin para ubicación del usuario (PRIMERO - capa más profunda)
                        if let userLat = location.latitude, let userLon = location.longitude {
                            Annotation(
                                "Mi Ubicación",
                                coordinate: CLLocationCoordinate2D(latitude: userLat, longitude: userLon)
                            ) {
                                UserLocationPinView()
                            }
                            .annotationTitles(.hidden)
                        }
                        
                        if mostrarClusters {
                            // Mostrar clusters cuando está activado
                            ForEach(clusters, id: \.id) { cluster in
                                Annotation(
                                    "\(cluster.establecimientos.count) establecimientos",
                                    coordinate: cluster.center
                                ) {
                                    ClusterPinView(
                                        count: cluster.establecimientos.count,
                                        themeManager: themeManager,
                                        onTap: {
                                            expandCluster(cluster)
                                        }
                                    )
                                }
                                .annotationTitles(.hidden)
                            }
                            
                            // Mostrar establecimientos individuales que no están en clusters
                            // Los captions se muestran automáticamente cuando hay espacio (indicador de clickeabilidad)
                            ForEach(establecimientosNoAgrupados) { establecimiento in
                                Annotation(
                                    establecimiento.nombre,
                                    coordinate: CLLocationCoordinate2D(
                                        latitude: establecimiento.lat ?? 0,
                                        longitude: establecimiento.lon ?? 0
                                    )
                                ) {
                                    PinEstilo2(
                                        establecimiento: establecimiento,
                                        themeManager: themeManager,
                                        usarColoresPorCategoria: usarColoresPorCategoria
                                    )
                                    .onTapGesture {
                                        selectedEstablecimiento = establecimiento
                                        print("🔍 Tapped en establecimiento: \(establecimiento.nombre)")
                                    }
                                }
                                .annotationTitles(.automatic)
                            }
                        } else {
                            // Mostrar establecimientos individuales cuando clusters está desactivado
                            // Los captions se muestran automáticamente cuando hay espacio (indicador de clickeabilidad)
                            ForEach(establecimientosFiltrados) { establecimiento in
                                Annotation(
                                    establecimiento.nombre,
                                    coordinate: CLLocationCoordinate2D(
                                        latitude: establecimiento.lat ?? 0,
                                        longitude: establecimiento.lon ?? 0
                                    )
                                ) {
                                    PinEstilo2(
                                        establecimiento: establecimiento,
                                        themeManager: themeManager,
                                        usarColoresPorCategoria: usarColoresPorCategoria
                                    )
                                    .onTapGesture {
                                        selectedEstablecimiento = establecimiento
                                        print("🔍 Tapped en establecimiento: \(establecimiento.nombre)")
                                    }
                                }
                                .annotationTitles(.automatic)
                            }
                        }
                    }
                    .mapStyle(mostrarClusters ? .standard(elevation: .realistic) : .standard)
                    .mapControls {
                        // 🎛️ CONTROLES DEL MAPA
                        MapUserLocationButton() // Botón "Mi ubicación"
                        MapCompass()            // Brújula
                        MapScaleView()          // Escala
                    }
                    .onMapCameraChange(frequency: .onEnd) { context in
                        // 📡 TRACKING DE CAMBIO DE CÁMARA
                        mapRegion = context.region
                        print("📍 Mapa actualizado - Centro: \(context.region.center), Zoom: \(context.region.span)")
                        
                        // Actualizar clusters cuando cambia el zoom
                        if mostrarClusters {
                            updateClusters()
                        }
                        
                        // Reactivar radio si el usuario movió el mapa desde vista completa de México (DESHABILITADO)
                        // reactivateRadioIfNeeded()
                    }
                    .mapStyle(.standard)
                    
                    // Botones de ubicación y todo México flotantes (alineados y con mismo estilo)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                // Botón "Ver todo México" - mismo estilo que Mi Ubicación
                                Button(action: {
                                    showFullMexico()
                                }) {
                                    Image(systemName: "globe.americas.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(themeManager.accent)
                                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Botón "Mi Ubicación" - mismo estilo
                                Button(action: {
                                    centerOnUserLocation()
                                }) {
                                    Image(systemName: "location.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(themeManager.accent)
                                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                        }
                    }
                    
                    // Loading overlay
                    if isLoading {
                        ZStack {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                            
                            VStack(spacing: themeManager.spacing) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.accent))
                                    .scaleEffect(1.5)
                                
                                Text("Cargando mapa...")
                                    .font(themeManager.body)
                                    .foregroundColor(themeManager.textPrimary)
                            }
                            .padding(themeManager.paddingMedium)
                            .background(
                                RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                                    .fill(themeManager.surface)
                                    .shadow(radius: 10)
                            )
                        }
                    }
                    
                }
            }
        }
        .onAppear {
            // Configuración inicial basada en el contexto
            if isTodoMexico {
                // Modo "Todo México": activar clusters y centrar en México
                mostrarClusters = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showFullMexico()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    updateClusters()
                }
            } else {
                // Modo "Mapa de Cercanías": centrar en ubicación del usuario
                if !didAutocenter {
                    centerOnUserLocation()
                }
            }
        }
        .onChange(of: mostrarClusters) { _, newValue in
            if newValue {
                // Se activaron los clusters - actualizarlos
                updateClusters()
            } else {
                // Se desactivaron los clusters - limpiarlos
                clusters = []
            }
        }
        .sheet(item: $selectedEstablecimiento) { establecimiento in
            // Modal con detalles del establecimiento
            EstablecimientoDetailSheet(
                establecimiento: establecimiento,
                themeManager: themeManager
            )
        }
        .sheet(isPresented: $mostrarSelectorCategoria) {
            // Modal de selector de categoría
            SelectorCategoriaSheet(
                categoriaSeleccionada: $categoriaSeleccionada,
                themeManager: themeManager
            )
        }
        .sheet(isPresented: $mostrarQRSheet) {
            // Modal de código QR
            QRCodeSheet(
                qrImage: qrImage,
                cantidadLugares: establecimientosVisibles.count,
                themeManager: themeManager
            )
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Funciones de Clustering
    
    /// Crea clusters de establecimientos basado en proximidad geográfica
    private func createClusters(from establecimientos: [lmpBDF_EstablecimientoLocal], radius: Double) -> [Cluster] {
        var clusters: [Cluster] = []
        var processedIndices: Set<Int> = []
        
        print("🔍 Creando clusters con radio: \(radius) para \(establecimientos.count) establecimientos")
        
        for (index, establecimiento) in establecimientos.enumerated() {
            guard !processedIndices.contains(index),
                  let lat = establecimiento.lat,
                  let lon = establecimiento.lon else { continue }
            
            var clusterEstablecimientos: [lmpBDF_EstablecimientoLocal] = [establecimiento]
            processedIndices.insert(index)
            
            // Buscar establecimientos cercanos para agrupar
            for (otherIndex, otherEstablecimiento) in establecimientos.enumerated() {
                guard !processedIndices.contains(otherIndex),
                      let otherLat = otherEstablecimiento.lat,
                      let otherLon = otherEstablecimiento.lon else { continue }
                
                let distance = calculateDistance(
                    lat1: lat, lon1: lon,
                    lat2: otherLat, lon2: otherLon
                )
                
                if distance <= radius {
                    clusterEstablecimientos.append(otherEstablecimiento)
                    processedIndices.insert(otherIndex)
                }
            }
            
            // Crear cluster solo si hay más de un establecimiento
            if clusterEstablecimientos.count > 1 {
                let centerLat = clusterEstablecimientos.compactMap { $0.lat }.reduce(0, +) / Double(clusterEstablecimientos.count)
                let centerLon = clusterEstablecimientos.compactMap { $0.lon }.reduce(0, +) / Double(clusterEstablecimientos.count)
                
                let cluster = Cluster(
                    id: UUID(),
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    establecimientos: clusterEstablecimientos
                )
                clusters.append(cluster)
                
                print("✅ Cluster creado con \(clusterEstablecimientos.count) establecimientos en (\(centerLat), \(centerLon))")
            }
        }
        
        print("📊 Total clusters creados: \(clusters.count)")
        return clusters
    }
    
    /// Calcula la distancia entre dos coordenadas (en grados)
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let deltaLat = lat2 - lat1
        let deltaLon = lon2 - lon1
        return sqrt(deltaLat * deltaLat + deltaLon * deltaLon)
    }
    
    // MARK: - Funciones Auxiliares
    
    /// Centra el mapa en la ubicación del usuario
    private func centerOnUserLocation() {
        guard let userLat = location.latitude, let userLon = location.longitude else {
            print("⚠️ No se pudo obtener ubicación del usuario")
            return
        }
        
        let userCoordinate = CLLocationCoordinate2D(latitude: userLat, longitude: userLon)
        let region = MKCoordinateRegion(
            center: userCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045)  // ~5 km de alcance
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(region)
            mapRegion = region
        }
        
        didAutocenter = true
        print("📍 Mapa centrado en usuario: \(userLat), \(userLon) con alcance de ~5 km")
    }
    
    /// Centra el mapa en un establecimiento específico
    private func centerOnEstablecimiento(_ establecimiento: lmpBDF_EstablecimientoLocal) {
        guard let lat = establecimiento.lat, let lon = establecimiento.lon else { return }
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(region)
            mapRegion = region
        }
        
        print("📍 Mapa centrado en: \(establecimiento.nombre)")
    }
    
    /// Centra el mapa en México (función simplificada)
    private func showFullMexico() {
        // Coordenadas del centro de México (Ciudad de México)
        let mexicoCenter = CLLocationCoordinate2D(latitude: 23.6345, longitude: -102.5528)
        let region = MKCoordinateRegion(
            center: mexicoCenter,
            span: MKCoordinateSpan(latitudeDelta: 18.0, longitudeDelta: 18.0) // Span más amplio para mostrar TODO México
        )
        
        withAnimation(.easeInOut(duration: 1.5)) {
            cameraPosition = .region(region)
            mapRegion = region
        }
        
        print("🇲🇽 Mapa centrado en México completo")
    }
    
    /// Calcula el radio de clustering dinámicamente basado en el nivel de zoom
    /// Lógica jerárquica: Estado → Municipio → Colonia → Individual
    private func calculateDynamicClusterRadius() -> Double {
        let span = mapRegion.span.latitudeDelta
        
        // 1° ≈ 111 km en latitud
        
        if span > 10.0 {
            // Vista de TODO México o varios estados
            // Agrupar por ESTADO (~200-300 km)
            return 2.5  // ~275 km - agrupa estados completos o regiones grandes
        } else if span > 3.0 {
            // Vista de un estado completo
            // Agrupar por MUNICIPIO (~50-80 km)
            return 0.7  // ~77 km - agrupa municipios
        } else if span > 0.5 {
            // Vista de un municipio o ciudad grande
            // Agrupar por COLONIA (~5-10 km)
            return 0.08  // ~9 km - agrupa colonias/barrios
        } else {
            // Vista cercana de una colonia
            // PULVERIZAR - mostrar establecimientos individuales
            // Solo agrupa si están en el mismo lugar (< 50 metros)
            return 0.0005  // ~55 metros - solo mismo edificio
        }
    }
    
    /// Actualiza los clusters basándose en el zoom actual
    private func updateClusters() {
        guard mostrarClusters else {
            clusters = []
            return
        }
        
        let dynamicRadius = calculateDynamicClusterRadius()
        let span = mapRegion.span.latitudeDelta
        
        // Determinar nivel de agrupación
        let nivel: String
        if span > 10.0 {
            nivel = "ESTADO"
        } else if span > 3.0 {
            nivel = "MUNICIPIO"
        } else if span > 0.5 {
            nivel = "COLONIA"
        } else {
            nivel = "INDIVIDUAL (pulverizado)"
        }
        
        print("🔄 Actualizando clusters - Nivel: \(nivel) | Radio: \(dynamicRadius)° (~\(Int(dynamicRadius * 111)) km) | Span: \(span)°")
        clusters = createClusters(from: establecimientosFiltrados, radius: dynamicRadius)
        print("📊 Clusters creados: \(clusters.count)")
    }
    
    /// Expande un cluster haciendo zoom y centrando el mapa
    private func expandCluster(_ cluster: Cluster) {
        print("🔍 Expandiendo cluster con \(cluster.establecimientos.count) establecimientos")
        
        // Calcular el área que ocupan los establecimientos del cluster
        let lats = cluster.establecimientos.compactMap { $0.lat }
        let lons = cluster.establecimientos.compactMap { $0.lon }
        
        guard !lats.isEmpty, !lons.isEmpty else { return }
        
        let minLat = lats.min()!
        let maxLat = lats.max()!
        let minLon = lons.min()!
        let maxLon = lons.max()!
        
        // Calcular el span necesario para mostrar todos los establecimientos con margen
        let latSpan = (maxLat - minLat) * 3.0  // 3x para dar buen margen
        let lonSpan = (maxLon - minLon) * 3.0
        
        // Si los establecimientos están muy cerca (misma ubicación), usar un span fijo pequeño
        let calculatedSpan = max(latSpan, lonSpan)
        let finalSpan: Double
        
        if calculatedSpan < 0.0001 {
            // Establecimientos en la misma ubicación - zoom a nivel de calle
            finalSpan = 0.002  // ~200 metros
        } else {
            // Establecimientos separados - mostrar todos con margen
            finalSpan = max(calculatedSpan, 0.005)  // Mínimo 0.005 grados (~500m)
        }
        
        let region = MKCoordinateRegion(
            center: cluster.center,
            span: MKCoordinateSpan(latitudeDelta: finalSpan, longitudeDelta: finalSpan)
        )
        
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(region)
            mapRegion = region
        }
        
        // Actualizar clusters después de la animación
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            updateClusters()
        }
        
        print("🔄 Zoom aplicado con span: \(finalSpan) (calculado: \(calculatedSpan))")
    }
    
    // MARK: - Generación de Código QR
    
    /// Genera un código QR con las ubicaciones visibles en pantalla
    private func generarCodigoQR() {
        let visibles = establecimientosVisibles
        
        guard !visibles.isEmpty else {
            print("⚠️ No hay establecimientos visibles para generar QR")
            return
        }
        
        // Limitar a los primeros 9 para URLs funcionales
        let limitados = Array(visibles.prefix(9))
        
        var urlString = ""
        
        if limitados.count == 1 {
            // Un solo establecimiento - Apple Maps
            if let est = limitados.first, let lat = est.lat, let lon = est.lon {
                let nombre = est.nombre.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Lugar"
                urlString = "https://maps.apple.com/?ll=\(lat),\(lon)&q=\(nombre)"
            }
        } else {
            // Múltiples establecimientos - Google Maps (soporta waypoints)
            // Formato: https://www.google.com/maps/dir/?api=1&destination=lat,lon&waypoints=lat1,lon1|lat2,lon2
            
            if let ultimo = limitados.last, let destLat = ultimo.lat, let destLon = ultimo.lon {
                var waypoints: [String] = []
                
                // Todos menos el último son waypoints
                for est in limitados.dropLast() {
                    if let lat = est.lat, let lon = est.lon {
                        waypoints.append("\(lat),\(lon)")
                    }
                }
                
                let waypointsString = waypoints.joined(separator: "|")
                
                if waypoints.isEmpty {
                    // Solo hay un destino
                    urlString = "https://www.google.com/maps/search/?api=1&query=\(destLat),\(destLon)"
                } else {
                    // Múltiples puntos
                    urlString = "https://www.google.com/maps/dir/?api=1&destination=\(destLat),\(destLon)&waypoints=\(waypointsString)"
                }
            }
        }
        
        print("📱 Generando QR con URL: \(urlString)")
        print("📍 Total de lugares: \(limitados.count)")
        
        // Generar imagen QR
        if let qr = generateQRCode(from: urlString) {
            qrImage = qr
            mostrarQRSheet = true
            print("✅ Código QR generado exitosamente")
        } else {
            print("❌ Error al generar código QR")
        }
    }
    
    /// Genera una imagen de código QR a partir de un string
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // Alta corrección de errores
        
        guard let ciImage = filter.outputImage else { return nil }
        
        // Escalar el QR para que se vea nítido
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Componentes Auxiliares

/// Vista de filtros para el mapa (simplificada - sin radio)
struct FiltrosView: View {
    @Binding var filtroNombre: String
    @Binding var soloFavoritos: Bool
    @Binding var mostrarClusters: Bool
    @Binding var usarColoresPorCategoria: Bool
    @Binding var categoriaSeleccionada: String?
    @Binding var mostrarSelectorCategoria: Bool
    let onGenerarQR: () -> Void
    let themeManager: GV_Temas_Manager
    
    var body: some View {
        VStack(spacing: 8) {
            // Fila superior: Búsqueda
            HStack(spacing: 12) {
                // Campo de búsqueda
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.textSecondary)
                    
                    TextField("Buscar establecimiento...", text: $filtroNombre)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(themeManager.body)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                        .fill(themeManager.surface)
                        .stroke(themeManager.border, lineWidth: themeManager.borderWidth)
                )
            }
            
            // Fila inferior: Botones de acción
            HStack(spacing: 12) {
                // Botón de favoritos con icono de corazón
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        soloFavoritos.toggle()
                    }
                }) {
                    Image(systemName: soloFavoritos ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(soloFavoritos ? themeManager.accent : themeManager.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(soloFavoritos ? themeManager.accent.opacity(0.15) : Color.clear)
                        )
                }
                
                // Botón de clusters
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mostrarClusters.toggle()
                        print("🔄 Clusters \(mostrarClusters ? "ACTIVADOS" : "DESACTIVADOS")")
                    }
                }) {
                    Image(systemName: mostrarClusters ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                        .font(.title2)
                        .foregroundColor(mostrarClusters ? themeManager.accent : themeManager.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(mostrarClusters ? themeManager.accent.opacity(0.15) : Color.clear)
                        )
                }
                
                // Separador vertical
                Rectangle()
                    .fill(themeManager.border)
                    .frame(width: 1, height: 30)
                
                // Botón de color único (turquesa)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        usarColoresPorCategoria = false
                        print("🎨 Modo: Color único (turquesa)")
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.teal)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(!usarColoresPorCategoria ? themeManager.accent.opacity(0.15) : Color.clear)
                    )
                    .overlay(
                        Circle()
                            .stroke(!usarColoresPorCategoria ? themeManager.accent : themeManager.border, lineWidth: 2)
                    )
                }
                
                // Botón de colores por categoría (multicolor) - SIMPLIFICADO
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        usarColoresPorCategoria = true
                        print("🎨 Modo: Colores por categoría")
                    }
                }) {
                    ZStack {
                        // Círculo dividido en 4 colores
                        Circle()
                            .trim(from: 0, to: 0.25)
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(-45))
                        
                        Circle()
                            .trim(from: 0.25, to: 0.5)
                            .fill(Color.green)
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(-45))
                        
                        Circle()
                            .trim(from: 0.5, to: 0.75)
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(-45))
                        
                        Circle()
                            .trim(from: 0.75, to: 1.0)
                            .fill(Color.orange)
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(-45))
                        
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(usarColoresPorCategoria ? themeManager.accent : themeManager.border, lineWidth: 2)
                    )
                }
                
                // Botón de selector de categoría
                Button(action: {
                    mostrarSelectorCategoria = true
                    print("🏷️ Abriendo selector de categoría")
                }) {
                    ZStack {
                        Image(systemName: categoriaSeleccionada != nil ? "tag.fill" : "tag")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(categoriaSeleccionada != nil ? themeManager.accent : themeManager.textSecondary)
                    }
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(categoriaSeleccionada != nil ? themeManager.accent : themeManager.border, lineWidth: 2)
                    )
                }
                
                // Botón de generar código QR
                Button(action: {
                    onGenerarQR()
                    print("📱 Generando código QR de lugares visibles")
                }) {
                    ZStack {
                        Image(systemName: "qrcode")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(themeManager.border, lineWidth: 2)
                    )
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.surface)
        .shadow(color: themeManager.shadow, radius: 2, y: 1)
    }
}

// MARK: - Estilos de Pins

/// 🏷️ ESTILO 2 - BADGE MINIMALISTA (CON COLORES POR CATEGORÍA)
struct PinEstilo2: View {
    let establecimiento: lmpBDF_EstablecimientoLocal
    let themeManager: GV_Temas_Manager
    let usarColoresPorCategoria: Bool
    
    // Función para obtener color según categoría
    private func colorPorCategoria(_ categoria: String?) -> Color {
        guard let cat = categoria?.lowercased() else { return Color.gray }
        
        // Mapeo de categorías a colores (ajusta según tus categorías reales)
        switch cat {
        case let c where c.contains("restaurante") || c.contains("comida") || c.contains("restaurant"):
            return Color.red
        case let c where c.contains("moda") || c.contains("ropa") || c.contains("fashion"):
            return Color.purple
        case let c where c.contains("hogar") || c.contains("mueble") || c.contains("home"):
            return Color.brown
        case let c where c.contains("tecnología") || c.contains("electr") || c.contains("tech"):
            return Color.blue
        case let c where c.contains("salud") || c.contains("farmacia") || c.contains("health"):
            return Color.green
        case let c where c.contains("deporte") || c.contains("sport") || c.contains("gym"):
            return Color.orange
        case let c where c.contains("belleza") || c.contains("estética") || c.contains("beauty"):
            return Color.pink
        case let c where c.contains("entretenimiento") || c.contains("cine") || c.contains("entertainment"):
            return Color.indigo
        case let c where c.contains("educación") || c.contains("librería") || c.contains("education"):
            return Color.cyan
        case let c where c.contains("automotriz") || c.contains("auto") || c.contains("car"):
            return Color.gray
        default:
            return Color.teal  // Color por defecto
        }
    }
    
    // Colores para gradiente
    private var gradientColors: [Color] {
        if establecimiento.esFavorito {
            return [themeManager.accent, themeManager.accent.opacity(0.8)]
        } else if usarColoresPorCategoria {
            let baseColor = colorPorCategoria(establecimiento.categoria)
            return [baseColor, baseColor.opacity(0.8)]
        } else {
            return [Color.teal, Color.teal.opacity(0.8)]
        }
    }
    
    var body: some View {
        ZStack {
            // Círculo con gradiente sutil
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 26, height: 26)  // Aumentado de 20 a 26
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2.5)  // Borde un poco más grueso
                )
                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
            
            // Icono interior
            Image(systemName: establecimiento.esFavorito ? "heart.fill" : "building.2.fill")
                .font(.system(size: 10, weight: .bold))  // Aumentado de 8 a 10
                .foregroundColor(.white)
        }
    }
}


/// Pin personalizado para clusters con contador
struct ClusterPinView: View {
    let count: Int
    let themeManager: GV_Temas_Manager
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            // Círculo exterior con efecto de presión
            Circle()
                .fill(themeManager.accent)
                .frame(width: (count > 9 ? 32 : 28) + (isPressed ? 4 : 0), 
                       height: (count > 9 ? 32 : 28) + (isPressed ? 4 : 0))
                .shadow(color: Color.black.opacity(0.3), radius: isPressed ? 5 : 3, x: 0, y: isPressed ? 3 : 2)
                .scaleEffect(isPressed ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
            
            // Círculo interior con borde
            Circle()
                .fill(Color.white)
                .frame(width: (count > 9 ? 26 : 22) + (isPressed ? 2 : 0), 
                       height: (count > 9 ? 26 : 22) + (isPressed ? 2 : 0))
            
            // Texto del contador
            Text("\(count)")
                .font(.system(size: (count > 9 ? 12 : 14) + (isPressed ? 1 : 0), weight: .bold))
                .foregroundColor(themeManager.accent)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }
    }
}

/// Pin para ubicación del usuario (versión sutil)
struct UserLocationPinView: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Círculo exterior sutil (azul translúcido)
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: isPulsing ? 24 : 20, height: isPulsing ? 24 : 20)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
            
            // Pin principal (azul sólido, pequeño)
            Circle()
                .fill(Color.blue)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

/// Modal con detalles del establecimiento
struct EstablecimientoDetailSheet: View {
    let establecimiento: lmpBDF_EstablecimientoLocal
    let themeManager: GV_Temas_Manager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: themeManager.spacing) {
                    // Header del establecimiento
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(establecimiento.nombre)
                                .font(themeManager.title)
                                .foregroundColor(themeManager.textPrimary)
                            
                            Spacer()
                            
                            if establecimiento.esFavorito {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(themeManager.accent)
                                    .font(.title2)
                            }
                        }
                        
                        // Dirección construida con municipio y estado
                        let direccion = [establecimiento.municipio, establecimiento.estado]
                            .compactMap { $0 }
                            .filter { !$0.isEmpty }
                            .joined(separator: ", ")
                        
                        if !direccion.isEmpty {
                            Text(direccion)
                                .font(themeManager.body)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }
                    .padding(themeManager.paddingMedium)
                    .background(
                        RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                            .fill(themeManager.surface)
                    )
                    
                    // Información adicional disponible
                    if let categoria = establecimiento.categoria, !categoria.isEmpty {
                        InfoRowView(
                            icon: "tag.fill",
                            title: "Categoría",
                            value: categoria,
                            themeManager: themeManager
                        )
                    }
                    
                    if let municipio = establecimiento.municipio, !municipio.isEmpty {
                        InfoRowView(
                            icon: "building.2.fill",
                            title: "Municipio",
                            value: municipio,
                            themeManager: themeManager
                        )
                    }
                    
                    if let estado = establecimiento.estado, !estado.isEmpty {
                        InfoRowView(
                            icon: "map.fill",
                            title: "Estado",
                            value: estado,
                            themeManager: themeManager
                        )
                    }
                    
                    // Coordenadas (para debug)
                    InfoRowView(
                        icon: "location.fill",
                        title: "Coordenadas",
                        value: "\(establecimiento.lat ?? 0), \(establecimiento.lon ?? 0)",
                        themeManager: themeManager
                    )
                    
                    Spacer(minLength: 100)
                }
                .padding(themeManager.paddingMedium)
            }
            .background(themeManager.background)
            .navigationTitle("Detalles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accent)
                }
            }
        }
    }
}

/// Fila de información en el modal de detalles
struct InfoRowView: View {
    let icon: String
    let title: String
    let value: String
    let themeManager: GV_Temas_Manager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(themeManager.accent)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(themeManager.caption)
                    .foregroundColor(themeManager.textSecondary)
                
                Text(value)
                    .font(themeManager.body)
                    .foregroundColor(themeManager.textPrimary)
            }
            
            Spacer()
        }
        .padding(themeManager.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                .fill(themeManager.surface)
        )
    }
}

// MARK: - Código QR Sheet

/// Modal para mostrar código QR generado
struct QRCodeSheet: View {
    let qrImage: UIImage?
    let cantidadLugares: Int
    let themeManager: GV_Temas_Manager
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Título
                    VStack(spacing: 8) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.accent)
                        
                        Text("Código QR Generado")
                            .font(themeManager.title)
                            .foregroundColor(themeManager.textPrimary)
                        
                        Text("\(min(cantidadLugares, 9)) lugares visibles")
                            .font(themeManager.caption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    
                    // Imagen del QR
                    if let image = qrImage {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                                    .fill(Color.white)
                                    .shadow(color: themeManager.shadow, radius: 10)
                            )
                    } else {
                        ProgressView()
                            .frame(width: 250, height: 250)
                    }
                    
                    // Instrucciones
                    VStack(spacing: 8) {
                        Text("Escanea este código para:")
                            .font(themeManager.body)
                            .foregroundColor(themeManager.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(themeManager.accent)
                                Text(cantidadLugares == 1 ? "Abrir en Apple Maps" : "Abrir ruta en Google Maps")
                                    .font(themeManager.caption)
                            }
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(themeManager.accent)
                                Text("Compartir ubicaciones fácilmente")
                                    .font(themeManager.caption)
                            }
                        }
                        .foregroundColor(themeManager.textSecondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                            .fill(themeManager.surface)
                    )
                    
                    // Botón compartir
                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Compartir QR")
                        }
                        .font(themeManager.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                                .fill(themeManager.accent)
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(themeManager.paddingMedium)
            }
            .navigationTitle("Compartir Ubicaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accent)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = qrImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }
}

/// Share Sheet para compartir el código QR
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Selector de Categoría

/// Modal para seleccionar una categoría
struct SelectorCategoriaSheet: View {
    @Binding var categoriaSeleccionada: String?
    let themeManager: GV_Temas_Manager
    @Environment(\.dismiss) private var dismiss
    
    // Lista de categorías disponibles (ordenadas alfabéticamente)
    private let categorias = [
        "Automotriz",
        "Belleza",
        "Deportes",
        "Educación",
        "Entretenimiento",
        "Hogar",
        "Moda",
        "Restaurante",
        "Salud",
        "Tecnología"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        // Opción "Todas las categorías"
                        Button(action: {
                            categoriaSeleccionada = nil
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "square.grid.2x2")
                                    .font(.title2)
                                    .foregroundColor(themeManager.textPrimary)
                                    .frame(width: 30)
                                
                                Text("Todas las categorías")
                                    .font(themeManager.body)
                                    .foregroundColor(themeManager.textPrimary)
                                
                                Spacer()
                                
                                if categoriaSeleccionada == nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(themeManager.accent)
                                }
                            }
                            .padding(themeManager.paddingMedium)
                            .background(
                                RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                                    .fill(categoriaSeleccionada == nil ? themeManager.accent.opacity(0.1) : themeManager.surface)
                            )
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Lista de categorías
                        ForEach(categorias, id: \.self) { categoria in
                            Button(action: {
                                categoriaSeleccionada = categoria
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: iconoParaCategoria(categoria))
                                        .font(.title2)
                                        .foregroundColor(colorParaCategoria(categoria))
                                        .frame(width: 30)
                                    
                                    Text(categoria)
                                        .font(themeManager.body)
                                        .foregroundColor(themeManager.textPrimary)
                                    
                                    Spacer()
                                    
                                    if categoriaSeleccionada == categoria {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(themeManager.accent)
                                    }
                                }
                                .padding(themeManager.paddingMedium)
                                .background(
                                    RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                                        .fill(categoriaSeleccionada == categoria ? themeManager.accent.opacity(0.1) : themeManager.surface)
                                )
                            }
                        }
                    }
                    .padding(themeManager.paddingMedium)
                }
            }
            .navigationTitle("Seleccionar Categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accent)
                }
            }
        }
    }
    
    // Helper para íconos por categoría
    private func iconoParaCategoria(_ categoria: String) -> String {
        switch categoria {
        case "Restaurante": return "fork.knife"
        case "Moda": return "tshirt"
        case "Hogar": return "house"
        case "Tecnología": return "laptopcomputer"
        case "Salud": return "cross.case"
        case "Deportes": return "figure.run"
        case "Belleza": return "sparkles"
        case "Entretenimiento": return "ticket"
        case "Educación": return "book"
        case "Automotriz": return "car"
        default: return "tag"
        }
    }
    
    // Helper para colores por categoría
    private func colorParaCategoria(_ categoria: String) -> Color {
        switch categoria {
        case "Restaurante": return Color.red
        case "Moda": return Color.purple
        case "Hogar": return Color.brown
        case "Tecnología": return Color.blue
        case "Salud": return Color.green
        case "Deportes": return Color.orange
        case "Belleza": return Color.pink
        case "Entretenimiento": return Color.indigo
        case "Educación": return Color.cyan
        case "Automotriz": return Color.gray
        default: return Color.teal
        }
    }
}

// MARK: - Estructura de Cluster

/// Estructura que representa un cluster de establecimientos
struct Cluster: Hashable {
    let id: UUID
    let center: CLLocationCoordinate2D
    let establecimientos: [lmpBDF_EstablecimientoLocal]
    
    // Implementación de Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Cluster, rhs: Cluster) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        GV_SCR_vg_MapaCercanias(isTodoMexico: false)
            .environmentObject(LocationService())
    }
}
