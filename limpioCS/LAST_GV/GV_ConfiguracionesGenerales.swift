//
//  GV_ConfiguracionesGenerales.swift
//  limpioCS
//
//  Created: 2025-10-15
//  Sistema: GV - Loader de Configuraciones Generales
//
//  Descripción:
//  ----------------------------------------------------------------
//  • Carga configuraciones desde GV_MisConfiguracionesGenerales.plist
//  • Singleton para acceso global
//  • Valores por defecto si falla la carga
//

import Foundation

/// Configuraciones generales de la aplicación (cargadas desde Plist)
class GV_ConfiguracionesGenerales {
    
    // MARK: - Singleton
    static let shared = GV_ConfiguracionesGenerales()
    
    // MARK: - Configuración del Mapa
    var mapa_RadioCentradoUsuario_KM: Double = 5.0
    var mapa_ZoomUsuario_LatitudeDelta: Double = 0.05
    var mapa_ZoomMexico_LatitudeDelta: Double = 15.0
    var mapa_MaxEstablecimientosVisibles: Int = 150
    var mapa_MaxEstablecimientosFetch: Int = 300
    var mapa_RegionBuffer: Double = 0.05
    var mapa_DebounceTime: Double = 0.3
    var mapa_ClusteringActivado: Bool = true
    var mapa_ClusterRadius: Double = 0.02
    var mapa_MinClusterSize: Int = 3
    
    // MARK: - Configuración de Ubicación
    var ubicacion_MinMovimientoMetros: Double = 20.0
    var ubicacion_MinIntervaloSegundos: Double = 2.0
    var ubicacion_TamanoCacheUbicaciones: Int = 100
    
    // MARK: - Configuración General
    var general_Version: String = "1.0.0"
    var general_ModoDebug: Bool = false
    var general_Idioma: String = "es"
    
    // MARK: - Init
    private init() {
        cargarConfiguraciones()
    }
    
    // MARK: - Carga de Configuraciones
    
    private func cargarConfiguraciones() {
        guard let url = Bundle.main.url(forResource: "GV_MisConfiguracionesGenerales", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            ProductionLogger.log("No se pudo cargar GV_MisConfiguracionesGenerales.plist - usando valores por defecto", level: .warning)
            return
        }
        
        // Cargar configuración del Mapa
        if let mapa = plist["Mapa"] as? [String: Any] {
            mapa_RadioCentradoUsuario_KM = mapa["RadioCentradoUsuario_KM"] as? Double ?? 5.0
            mapa_ZoomUsuario_LatitudeDelta = mapa["ZoomUsuario_LatitudeDelta"] as? Double ?? 0.05
            mapa_ZoomMexico_LatitudeDelta = mapa["ZoomMexico_LatitudeDelta"] as? Double ?? 15.0
            mapa_MaxEstablecimientosVisibles = mapa["MaxEstablecimientosVisibles"] as? Int ?? 150
            mapa_MaxEstablecimientosFetch = mapa["MaxEstablecimientosFetch"] as? Int ?? 300
            mapa_RegionBuffer = mapa["RegionBuffer"] as? Double ?? 0.05
            mapa_DebounceTime = mapa["DebounceTime"] as? Double ?? 0.3
            mapa_ClusteringActivado = mapa["ClusteringActivado"] as? Bool ?? true
            mapa_ClusterRadius = mapa["ClusterRadius"] as? Double ?? 0.02
            mapa_MinClusterSize = mapa["MinClusterSize"] as? Int ?? 3
        }
        
        // Cargar configuración de Ubicación
        if let ubicacion = plist["Ubicacion"] as? [String: Any] {
            ubicacion_MinMovimientoMetros = ubicacion["MinMovimientoMetros"] as? Double ?? 20.0
            ubicacion_MinIntervaloSegundos = ubicacion["MinIntervaloSegundos"] as? Double ?? 2.0
            ubicacion_TamanoCacheUbicaciones = ubicacion["TamanoCacheUbicaciones"] as? Int ?? 100
        }
        
        // Cargar configuración General
        if let general = plist["General"] as? [String: Any] {
            general_Version = general["Version"] as? String ?? "1.0.0"
            general_ModoDebug = general["ModoDebug"] as? Bool ?? false
            general_Idioma = general["Idioma"] as? String ?? "es"
        }
        
        ProductionLogger.log("Configuraciones cargadas - Radio mapa: \(mapa_RadioCentradoUsuario_KM)km", level: .info)
    }
    
    // MARK: - Helpers
    
    /// Convierte kilómetros a grados aproximados (latitudeDelta)
    func kmToLatitudeDelta(_ km: Double) -> Double {
        // Aproximadamente 111 km por grado de latitud
        return km / 111.0
    }
    
    /// Convierte grados (latitudeDelta) a kilómetros aproximados
    func latitudeDeltaToKm(_ delta: Double) -> Double {
        // Aproximadamente 111 km por grado de latitud
        return delta * 111.0
    }
}

