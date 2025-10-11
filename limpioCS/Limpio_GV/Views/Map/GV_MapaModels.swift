//
//  GV_MapaModels.swift
//  limpioCS
//
//  Created: 2025-01-10
//  Sistema: GV - Modelos del Mapa
//

import Foundation
import CoreLocation
import SwiftData
import MapKit
import SwiftUI

// MARK: - Modelo de Cluster

/// Representa un grupo de establecimientos cercanos en el mapa
struct GV_Cluster: Hashable {
    let id: UUID
    let center: CLLocationCoordinate2D
    let establecimientos: [lmpBDF_EstablecimientoLocal]
    
    // Implementación de Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GV_Cluster, rhs: GV_Cluster) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Extensiones útiles para Cluster

extension GV_Cluster {
    /// Número de establecimientos en el cluster
    var count: Int {
        return establecimientos.count
    }
    
    /// Establecimiento más cercano al centro del cluster
    var establecimientoMasCercano: lmpBDF_EstablecimientoLocal? {
        guard !establecimientos.isEmpty else { return nil }
        
        return establecimientos.min { establecimiento1, establecimiento2 in
            let dist1 = calculateDistance(
                lat1: center.latitude,
                lon1: center.longitude,
                lat2: establecimiento1.lat ?? 0,
                lon2: establecimiento1.lon ?? 0
            )
            let dist2 = calculateDistance(
                lat1: center.latitude,
                lon1: center.longitude,
                lat2: establecimiento2.lat ?? 0,
                lon2: establecimiento2.lon ?? 0
            )
            return dist1 < dist2
        }
    }
    
    /// Calcula la distancia entre dos coordenadas (en metros)
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let location1 = CLLocation(latitude: lat1, longitude: lon1)
        let location2 = CLLocation(latitude: lat2, longitude: lon2)
        return location1.distance(from: location2)
    }
}

// MARK: - Modelo de Filtros del Mapa

/// Representa los filtros activos en el mapa
struct MapaFiltros {
    var radioKm: Double = 20
    var nombre: String = ""
    var soloFavoritos: Bool = false
    var categoriaSeleccionada: String? = nil
    var mostrarClusters: Bool = false
    var usarColoresPorCategoria: Bool = false
    
    /// Indica si hay filtros activos
    var tieneFiltrosActivos: Bool {
        return !nombre.isEmpty || soloFavoritos || categoriaSeleccionada != nil
    }
}

// MARK: - Modelo de Estado del Mapa

/// Representa el estado actual del mapa
struct MapaEstado {
    var cameraPosition: MapCameraPosition = .automatic
    var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.6345, longitude: -102.5528),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    var selectedEstablecimiento: lmpBDF_EstablecimientoLocal? = nil
    var selectedCluster: GV_Cluster? = nil
    var isLoading: Bool = false
    var didAutocenter: Bool = false
    var isShowingFullMexico: Bool = false
    var radioDisabled: Bool = false
}

// MARK: - Modelo de Configuración del Mapa

/// Configuración del mapa
struct MapaConfiguracion {
    let clusterRadius: Double = 0.01
    let radioPorDefecto: Double = 20
    let centroMexico: CLLocationCoordinate2D = CLLocationCoordinate2D(
        latitude: 23.6345,
        longitude: -102.5528
    )
    let spanPorDefecto: MKCoordinateSpan = MKCoordinateSpan(
        latitudeDelta: 0.1,
        longitudeDelta: 0.1
    )
}
