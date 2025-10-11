//
//  GV_MapaClustering.swift
//  limpioCS
//
//  Created: 2025-01-10
//  Sistema: GV - Lógica de Clustering del Mapa
//

import Foundation
import CoreLocation
import SwiftData
import MapKit
import Combine

// MARK: - Manager de Clustering

/// Maneja toda la lógica de clustering de establecimientos
class GV_MapaClusteringManager: ObservableObject {
    
    // MARK: - Propiedades
    
    @Published var clusters: [GV_Cluster] = []
    @Published var selectedCluster: GV_Cluster? = nil
    
    // MARK: - Configuración
    
    private let defaultClusterRadius: Double = 0.01
    private let minClusterSize: Int = 2
    
    // MARK: - Funciones Públicas
    
    /// Crea clusters a partir de una lista de establecimientos
    func createClusters(from establecimientos: [lmpBDF_EstablecimientoLocal], radius: Double? = nil) -> [GV_Cluster] {
        let clusterRadius = radius ?? defaultClusterRadius
        var clusters: [GV_Cluster] = []
        var processedEstablecimientos: Set<Int> = []
        
        for establecimiento in establecimientos {
            // Saltar si ya fue procesado
            if processedEstablecimientos.contains(establecimiento.id) {
                continue
            }
            
            guard let lat = establecimiento.lat, let lon = establecimiento.lon else {
                continue
            }
            
            // Buscar establecimientos cercanos
            let nearbyEstablecimientos = establecimientos.filter { otherEst in
                guard let otherLat = otherEst.lat, let otherLon = otherEst.lon else {
                    return false
                }
                
                let distance = calculateDistance(
                    lat1: lat, lon1: lon,
                    lat2: otherLat, lon2: otherLon
                )
                
                return distance <= clusterRadius && !processedEstablecimientos.contains(otherEst.id)
            }
            
            // Crear cluster si hay suficientes establecimientos
            if nearbyEstablecimientos.count >= minClusterSize {
                let centerLat = nearbyEstablecimientos.map { $0.lat ?? 0 }.reduce(0, +) / Double(nearbyEstablecimientos.count)
                let centerLon = nearbyEstablecimientos.map { $0.lon ?? 0 }.reduce(0, +) / Double(nearbyEstablecimientos.count)
                
                let cluster = GV_Cluster(
                    id: UUID(),
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    establecimientos: nearbyEstablecimientos
                )
                
                clusters.append(cluster)
                
                // Marcar como procesados
                for est in nearbyEstablecimientos {
                    processedEstablecimientos.insert(est.id)
                }
            }
        }
        
        self.clusters = clusters
        return clusters
    }
    
    /// Actualiza los clusters basado en la región visible del mapa
    func updateClusters(for establecimientos: [lmpBDF_EstablecimientoLocal], 
                       visibleRegion: MKCoordinateRegion,
                       clusterRadius: Double? = nil) {
        
        // Calcular radio dinámico basado en el zoom
        let dynamicRadius = calculateDynamicClusterRadius(for: visibleRegion)
        let radius = clusterRadius ?? dynamicRadius
        
        // Crear clusters solo para establecimientos visibles
        let visibleEstablecimientos = filterEstablecimientosInRegion(establecimientos, region: visibleRegion)
        _ = createClusters(from: visibleEstablecimientos, radius: radius)
    }
    
    /// Expande un cluster seleccionado
    func expandCluster(_ cluster: GV_Cluster) {
        selectedCluster = cluster
    }
    
    /// Colapsa el cluster seleccionado
    func collapseCluster() {
        selectedCluster = nil
    }
    
    /// Obtiene establecimientos que no están en clusters
    func getEstablecimientosNoAgrupados(from establecimientos: [lmpBDF_EstablecimientoLocal]) -> [lmpBDF_EstablecimientoLocal] {
        let establecimientosEnClusters = Set(clusters.flatMap { $0.establecimientos })
        return establecimientos.filter { !establecimientosEnClusters.contains($0) }
    }
    
    // MARK: - Funciones Privadas
    
    /// Calcula la distancia entre dos coordenadas (en grados)
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let location1 = CLLocation(latitude: lat1, longitude: lon1)
        let location2 = CLLocation(latitude: lat2, longitude: lon2)
        return location1.distance(from: location2) / 1000.0 // Convertir a kilómetros
    }
    
    /// Calcula el radio dinámico basado en la región visible
    private func calculateDynamicClusterRadius(for region: MKCoordinateRegion) -> Double {
        let latDelta = region.span.latitudeDelta
        let lonDelta = region.span.longitudeDelta
        
        // Radio más pequeño para zoom más cercano
        let avgDelta = (latDelta + lonDelta) / 2
        
        switch avgDelta {
        case 0...0.01:
            return 0.005  // Zoom muy cercano
        case 0.01...0.05:
            return 0.01   // Zoom cercano
        case 0.05...0.1:
            return 0.02   // Zoom medio
        case 0.1...0.5:
            return 0.05   // Zoom lejano
        default:
            return 0.1    // Zoom muy lejano
        }
    }
    
    /// Filtra establecimientos que están dentro de una región
    private func filterEstablecimientosInRegion(_ establecimientos: [lmpBDF_EstablecimientoLocal], 
                                              region: MKCoordinateRegion) -> [lmpBDF_EstablecimientoLocal] {
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        
        return establecimientos.filter { establecimiento in
            guard let lat = establecimiento.lat, let lon = establecimiento.lon else { return false }
            return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
        }
    }
}

// MARK: - Extensiones útiles

extension GV_MapaClusteringManager {
    /// Limpia todos los clusters
    func clearClusters() {
        clusters = []
        selectedCluster = nil
    }
    
    /// Obtiene el cluster más cercano a una coordenada
    func getClusterNear(coordinate: CLLocationCoordinate2D) -> GV_Cluster? {
        return clusters.min { cluster1, cluster2 in
            let dist1 = calculateDistance(
                lat1: coordinate.latitude,
                lon1: coordinate.longitude,
                lat2: cluster1.center.latitude,
                lon2: cluster1.center.longitude
            )
            let dist2 = calculateDistance(
                lat1: coordinate.latitude,
                lon1: coordinate.longitude,
                lat2: cluster2.center.latitude,
                lon2: cluster2.center.longitude
            )
            return dist1 < dist2
        }
    }
    
    /// Calcula la distancia entre dos coordenadas (función pública)
    func calculateDistancePublic(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let location1 = CLLocation(latitude: lat1, longitude: lon1)
        let location2 = CLLocation(latitude: lat2, longitude: lon2)
        return location1.distance(from: location2)
    }
}
