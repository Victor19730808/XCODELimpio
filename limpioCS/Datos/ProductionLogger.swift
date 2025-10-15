//
//  ProductionLogger.swift
//  limpioCS
//
//  Created: 2025-01-14
//  Sistema: Logger optimizado para producción
//

import Foundation

/// Sistema de logging optimizado para producción
/// - Se deshabilita automáticamente en builds de Release
/// - Mantiene solo logs esenciales en producción
/// - Permite debugging en Development
class ProductionLogger {
    
    // MARK: - Configuración
    
    /// Determina si estamos en modo debug (Development)
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Determina si debemos mostrar logs detallados
    static var showDetailedLogs: Bool {
        return isDebugMode
    }
    
    // MARK: - Métodos de Logging
    
    /// Log general - siempre visible en debug, solo errores en producción
    static func log(_ message: String, level: ProductionLogLevel = .info) {
        switch level {
        case .error:
            // Errores siempre se muestran
            print("❌ ERROR: \(message)")
        case .warning:
            // Warnings solo en debug
            if isDebugMode {
                print("⚠️ WARNING: \(message)")
            }
        case .info:
            // Info solo en debug
            if isDebugMode {
                print("ℹ️ INFO: \(message)")
            }
        case .debug:
            // Debug solo en debug mode
            if isDebugMode {
                print("🐛 DEBUG: \(message)")
            }
        case .success:
            // Success solo en debug
            if isDebugMode {
                print("✅ SUCCESS: \(message)")
            }
        }
    }
    
    /// Log específico para seed system
    static func seedLog(_ message: String) {
        if showDetailedLogs {
            print("🌱 SEED: \(message)")
        }
    }
    
    /// Log específico para mapa
    static func mapLog(_ message: String) {
        if showDetailedLogs {
            print("🗺️ MAP: \(message)")
        }
    }
    
    /// Log específico para ubicación
    static func locationLog(_ message: String) {
        if showDetailedLogs {
            print("📍 LOCATION: \(message)")
        }
    }
    
    /// Log específico para banners
    static func bannerLog(_ message: String) {
        if showDetailedLogs {
            print("🎯 BANNER: \(message)")
        }
    }
    
    /// Log específico para favoritos
    static func favoritesLog(_ message: String) {
        if showDetailedLogs {
            print("❤️ FAVORITES: \(message)")
        }
    }
    
    /// Log específico para categorías
    static func categoriesLog(_ message: String) {
        if showDetailedLogs {
            print("📂 CATEGORIES: \(message)")
        }
    }
}

// MARK: - Log Levels

enum ProductionLogLevel {
    case error
    case warning
    case info
    case debug
    case success
}

// MARK: - Convenience Methods

/// Reemplazo directo para print() en producción
func productionPrint(_ message: String, level: ProductionLogLevel = .info) {
    ProductionLogger.log(message, level: level)
}

/// Reemplazo directo para debugLog() en producción
func productionDebugLog(_ message: String) {
    ProductionLogger.log(message, level: .debug)
}
