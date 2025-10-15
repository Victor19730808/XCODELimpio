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
    var mapa_SearchDebounceTime: Double = 0.35
    var mapa_SearchMinChars: Int = 1
    var mapa_SearchMaxResults: Int = 20
    var mapa_SearchFetchLimit: Int = 2000
    var mapa_HighlightDuration: Double = 1.2
    var mapa_HighlightFadeDuration: Double = 0.4
    var mapa_ActionMenuDelay: Double = 0.2
    var mapa_NoCategoryIcon: String = "questionmark.circle.fill"
    var mapa_NoCategoryColorHex: String = "#9E9E9E"
    // Thresholds de región
    var mapa_ThresholdCenterFactor: Double = 0.10
    var mapa_ThresholdSpanFactorLat: Double = 0.10
    var mapa_ThresholdSpanFactorLon: Double = 0.10
    // Caché por tiles
    var mapa_TileCacheTTLSeconds: Int = 300
    var mapa_TileGridBaseDegrees: Double = 0.20
    // Fetch adaptativo
    var mapa_AdaptiveFetch_WideLatDelta: Double = 12.0
    var mapa_AdaptiveFetch_MediumLatDelta: Double = 4.0
    var mapa_AdaptiveFetch_WideLimit: Int = 120
    var mapa_AdaptiveFetch_MediumLimit: Int = 220
    var mapa_AdaptiveFetch_CloseLimit: Int = 300
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
    
    // Lista (Participantes)
    var lista_SearchMaxResults: Int = 20
    var lista_SearchDebounceTime: Double = 0.35
    var lista_SearchMinChars: Int = 1
    var lista_DistanceCacheInvalidationMeters: Double = 60.0
    var lista_NoCategoryIcon: String = "questionmark.circle.fill"
    var lista_NoCategoryColorHex: String = "#9E9E9E"
    var lista_RowSpacing: Double = 8.0
    
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
            mapa_SearchDebounceTime = mapa["SearchDebounceTime"] as? Double ?? 0.35
            mapa_SearchMinChars = mapa["SearchMinChars"] as? Int ?? 1
            mapa_SearchMaxResults = mapa["SearchMaxResults"] as? Int ?? 20
            mapa_SearchFetchLimit = mapa["SearchFetchLimit"] as? Int ?? 2000
            mapa_HighlightDuration = mapa["HighlightDuration"] as? Double ?? 1.2
            mapa_HighlightFadeDuration = mapa["HighlightFadeDuration"] as? Double ?? 0.4
            mapa_ActionMenuDelay = mapa["ActionMenuDelay"] as? Double ?? 0.2
            mapa_NoCategoryIcon = mapa["NoCategoryIcon"] as? String ?? "questionmark.circle.fill"
            mapa_NoCategoryColorHex = mapa["NoCategoryColorHex"] as? String ?? "#9E9E9E"
            mapa_ThresholdCenterFactor = mapa["ThresholdCenterFactor"] as? Double ?? 0.10
            mapa_ThresholdSpanFactorLat = mapa["ThresholdSpanFactorLat"] as? Double ?? 0.10
            mapa_ThresholdSpanFactorLon = mapa["ThresholdSpanFactorLon"] as? Double ?? 0.10
            mapa_TileCacheTTLSeconds = mapa["TileCacheTTLSeconds"] as? Int ?? 300
            mapa_TileGridBaseDegrees = mapa["TileGridBaseDegrees"] as? Double ?? 0.20
            mapa_AdaptiveFetch_WideLatDelta = mapa["AdaptiveFetch_WideLatDelta"] as? Double ?? 12.0
            mapa_AdaptiveFetch_MediumLatDelta = mapa["AdaptiveFetch_MediumLatDelta"] as? Double ?? 4.0
            mapa_AdaptiveFetch_WideLimit = mapa["AdaptiveFetch_WideLimit"] as? Int ?? 120
            mapa_AdaptiveFetch_MediumLimit = mapa["AdaptiveFetch_MediumLimit"] as? Int ?? 220
            mapa_AdaptiveFetch_CloseLimit = mapa["AdaptiveFetch_CloseLimit"] as? Int ?? 300
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
        
        // Lista de Participantes
        if let lista = plist["Lista"] as? [String: Any] {
            lista_SearchMaxResults = lista["SearchMaxResults"] as? Int ?? 20
            lista_SearchDebounceTime = lista["SearchDebounceTime"] as? Double ?? 0.35
            lista_SearchMinChars = lista["SearchMinChars"] as? Int ?? 1
            lista_DistanceCacheInvalidationMeters = lista["DistanceCacheInvalidationMeters"] as? Double ?? 60.0
            lista_NoCategoryIcon = lista["NoCategoryIcon"] as? String ?? "questionmark.circle.fill"
            lista_NoCategoryColorHex = lista["NoCategoryColorHex"] as? String ?? "#9E9E9E"
            lista_RowSpacing = lista["RowSpacing"] as? Double ?? 8.0
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

