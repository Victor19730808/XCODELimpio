//
//  GV_MapaCercanias_Refactored.swift
//  limpioCS
//
//  Created: 2025-01-10
//  Sistema: GV - Mapa de Cercanías (Versión Refactorizada)
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import CoreImage

struct GV_MapaCercanias_Refactored: View {
    // MARK: - Configuración del Sistema GV
    private let screenType: ScreenType = .general
    private let myHeader: GV_HeaderType = .tipo2
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    @ObservedObject private var favoritosManager = GV_FavoritosManager.shared
    
    // MARK: - Parámetros de configuración
    let isTodoMexico: Bool
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var location: LocationService
    @Environment(\.modelContext) private var context
    
    // MARK: - SwiftData Query
    @Query(sort: [SortDescriptor(\lmpBDF_EstablecimientoLocal.nombre, comparator: .localizedStandard)])
    private var todosLosEstablecimientos: [lmpBDF_EstablecimientoLocal]
    
    // MARK: - Estados del Mapa
    @State private var mapEstado = MapaEstado()
    @State private var mapFiltros = MapaFiltros()
    @State private var mapConfig = MapaConfiguracion()
    
    // MARK: - Managers
    @StateObject private var clusteringManager = GV_MapaClusteringManager()
    
    // MARK: - Estados para Modals
    @State private var mostrarQRSheet = false
    @State private var qrImage: UIImage? = nil
    
    // MARK: - Computed Properties
    
    /// Establecimientos filtrados por criterios
    private var establecimientosFiltrados: [lmpBDF_EstablecimientoLocal] {
        return todosLosEstablecimientos.filter { establecimiento in
            // Filtro por favoritos
            if mapFiltros.soloFavoritos && !favoritosManager.isFavorite(establecimientoId: establecimiento.id) {
                return false
            }
            
            // Filtro por nombre
            if !mapFiltros.nombre.isEmpty {
                let searchTerm = mapFiltros.nombre.lowercased()
                let nombreMatch = establecimiento.nombre.lowercased().contains(searchTerm)
                let categoriaMatch = establecimiento.categoria?.lowercased().contains(searchTerm) ?? false
                
                if !nombreMatch && !categoriaMatch {
                    return false
                }
            }
            
            // Filtro por categoría
            if let categoriaSeleccionada = mapFiltros.categoriaSeleccionada,
               establecimiento.categoria != categoriaSeleccionada {
                return false
            }
            
            return true
        }
    }
    
    /// Establecimientos que no están agrupados en clusters
    private var establecimientosNoAgrupados: [lmpBDF_EstablecimientoLocal] {
        guard mapFiltros.mostrarClusters else { return establecimientosFiltrados }
        return clusteringManager.getEstablecimientosNoAgrupados(from: establecimientosFiltrados)
    }
    
    var body: some View {
        ZStack {
            // Fondo con tema
            themeManager.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header con menú
                myHeader.headerViewWithMenu("Mapa de Cercanías", nil, .mapa)
                
                // Controles de filtro
                GV_MapaFiltros(
                    filtroNombre: $mapFiltros.nombre,
                    soloFavoritos: $mapFiltros.soloFavoritos,
                    mostrarClusters: $mapFiltros.mostrarClusters,
                    usarColoresPorCategoria: $mapFiltros.usarColoresPorCategoria,
                    categoriaSeleccionada: $mapFiltros.categoriaSeleccionada,
                    mostrarSelectorCategoria: .constant(false),
                    onGenerarQR: generarCodigoQR
                )
                .padding(.horizontal, themeManager.paddingMedium)
                .padding(.vertical, 8)
                
                // Mapa principal
                Map(position: $mapEstado.cameraPosition) {
                    // Pines de establecimientos individuales
                    ForEach(establecimientosNoAgrupados, id: \.id) { establecimiento in
                        if let lat = establecimiento.lat, let lon = establecimiento.lon {
                            Annotation(establecimiento.nombre, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                GV_PinEstablecimiento(
                                    establecimiento: establecimiento,
                                    themeManager: themeManager,
                                    favoritosManager: favoritosManager,
                                    usarColoresPorCategoria: mapFiltros.usarColoresPorCategoria
                                )
                                .onTapGesture {
                                    mapEstado.selectedEstablecimiento = establecimiento
                                }
                            }
                        }
                    }
                    
                    // Pines de clusters
                    if mapFiltros.mostrarClusters {
                        ForEach(clusteringManager.clusters, id: \.id) { cluster in
                            Annotation("\(cluster.count) lugares", coordinate: cluster.center) {
                                GV_PinCluster(
                                    count: cluster.count,
                                    themeManager: themeManager,
                                    onTap: {
                                        clusteringManager.expandCluster(cluster)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Pin de ubicación del usuario
                    if let lat = location.latitude, let lon = location.longitude {
                        Annotation("Mi ubicación", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            GV_PinUbicacionUsuario()
                        }
                    }
                }
                .mapStyle(.standard)
                .onMapCameraChange { context in
                    mapEstado.mapRegion = context.region
                    
                    // Actualizar clusters cuando cambie la región
                    if mapFiltros.mostrarClusters {
                        clusteringManager.updateClusters(
                            for: establecimientosFiltrados,
                            visibleRegion: context.region
                        )
                    }
                }
                .onAppear {
                    if isTodoMexico {
                        showFullMexico()
                    } else {
                        centerOnUserLocation()
                    }
                }
                .onChange(of: mapFiltros.mostrarClusters) { _, newValue in
                    if newValue {
                        clusteringManager.updateClusters(
                            for: establecimientosFiltrados,
                            visibleRegion: mapEstado.mapRegion
                        )
                    } else {
                        clusteringManager.clearClusters()
                    }
                }
            }
        }
        .sheet(item: $mapEstado.selectedEstablecimiento) { establecimiento in
            GV_EstablecimientoDetailSheet(
                establecimiento: establecimiento,
                themeManager: themeManager,
                favoritosManager: favoritosManager
            )
        }
        .sheet(isPresented: $mostrarQRSheet) {
            GV_QRCodeSheet(
                qrImage: qrImage,
                cantidadLugares: establecimientosFiltrados.count
            )
        }
        .sheet(isPresented: .constant(false)) { // Placeholder para selector de categorías
            GV_SelectorCategoriaSheet(
                categoriaSeleccionada: $mapFiltros.categoriaSeleccionada
            )
        }
        .background(themeManager.background)
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
        .navigationBarHidden(true)
    }
    
    // MARK: - Funciones
    
    /// Centra el mapa en la ubicación del usuario
    private func centerOnUserLocation() {
        guard let lat = location.latitude, let lon = location.longitude else { return }
        
        let userCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        mapEstado.cameraPosition = .camera(
            MapCamera(
                centerCoordinate: userCoordinate,
                distance: 1000,
                heading: 0,
                pitch: 0
            )
        )
        mapEstado.didAutocenter = true
    }
    
    /// Muestra toda la República Mexicana
    private func showFullMexico() {
        mapEstado.cameraPosition = .camera(
            MapCamera(
                centerCoordinate: mapConfig.centroMexico,
                distance: 2000000, // 2000 km
                heading: 0,
                pitch: 0
            )
        )
        mapEstado.isShowingFullMexico = true
        mapEstado.radioDisabled = true
    }
    
    /// Genera código QR de los establecimientos visibles
    private func generarCodigoQR() {
        let establecimientos = establecimientosFiltrados.prefix(9) // Máximo 9 para el QR
        let qrData = establecimientos.map { "\($0.nombre) - \($0.categoria ?? "Sin categoría")" }.joined(separator: "\n")
        
        if let qrImage = generateQRCode(from: qrData) {
            self.qrImage = qrImage
            mostrarQRSheet = true
        }
    }
    
    /// Genera imagen QR desde string
    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        let context = CIContext()
        let filter = CIFilter(name: "CIQRCodeGenerator")!
        
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
}

// MARK: - Preview

#Preview {
    GV_MapaCercanias_Refactored(isTodoMexico: false)
        .environmentObject(LocationService())
}
