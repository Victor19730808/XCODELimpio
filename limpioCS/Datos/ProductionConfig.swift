//
//  ProductionConfig.swift
//  limpioCS
//
//  Created: 2025-01-14
//  Sistema: Configuración para builds de producción
//

import Foundation

/// Configuración específica para builds de producción
struct ProductionConfig {
    
    // MARK: - Build Configuration
    
    /// Determina si estamos en modo producción
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    /// Determina si debemos mostrar información de debug
    static var showDebugInfo: Bool {
        return !isProduction
    }
    
    // MARK: - Performance Settings
    
    /// Límite de establecimientos visibles en el mapa (producción)
    static var maxEstablecimientosVisibles: Int {
        return isProduction ? 100 : 150
    }
    
    /// Límite de fetch para lazy loading (producción)
    static var maxEstablecimientosFetch: Int {
        return isProduction ? 300 : 500
    }
    
    /// Tiempo de debounce para actualizaciones del mapa (producción)
    static var mapDebounceTime: Double {
        return isProduction ? 0.5 : 0.3
    }
    
    // MARK: - Cache Settings
    
    /// Tamaño máximo del cache de ubicación (producción)
    static var maxLocationCacheSize: Int {
        return isProduction ? 50 : 100
    }
    
    /// Tiempo de vida del cache de ubicación en segundos (producción)
    static var locationCacheLifetime: TimeInterval {
        return isProduction ? 3600 : 1800 // 1 hora vs 30 minutos
    }
    
    // MARK: - UI Settings
    
    /// Habilitar animaciones detalladas (producción)
    static var enableDetailedAnimations: Bool {
        return !isProduction
    }
    
    /// Mostrar información de debug en la UI
    static var showDebugUI: Bool {
        return !isProduction
    }
    
    // MARK: - Network Settings
    
    /// Timeout para requests de red (producción)
    static var networkTimeout: TimeInterval {
        return isProduction ? 10.0 : 15.0
    }
    
    /// Número máximo de reintentos (producción)
    static var maxRetryAttempts: Int {
        return isProduction ? 2 : 3
    }
    
    // MARK: - Logging Settings
    
    /// Nivel de logging en producción
    static var logLevel: String {
        return isProduction ? "ERROR" : "DEBUG"
    }
    
    /// Habilitar logs de performance
    static var enablePerformanceLogging: Bool {
        return !isProduction
    }
}

// MARK: - Convenience Extensions

extension ProductionConfig {
    
    /// Retorna el valor optimizado para producción
    static func optimizedValue<T>(production: T, debug: T) -> T {
        return isProduction ? production : debug
    }
    
    /// Ejecuta código solo en debug
    static func debugOnly(_ closure: () -> Void) {
        if !isProduction {
            closure()
        }
    }
    
    /// Ejecuta código solo en producción
    static func productionOnly(_ closure: () -> Void) {
        if isProduction {
            closure()
        }
    }
}
