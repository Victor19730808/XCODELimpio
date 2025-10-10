//
//  GV_Temas_ConfigSource.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Sistema de carga de configuraciones de temas (Swift vs Plist)
//

import Foundation
import SwiftUI

/// Fuente de configuración para los temas
enum GV_Temas_ConfigSourceType {
    case swift  // Configuración desde código Swift
    case plist  // Configuración desde archivo GV_Temas_Configs.plist
}

/// Loader de configuraciones de temas con bandera para cambiar entre fuentes
class GV_Temas_ConfigLoader {
    static let shared = GV_Temas_ConfigLoader()
    
    /// 🚩 BANDERA: Cambia esta variable para usar Swift o Plist
    /// - .swift: Usa configuraciones hardcoded en GV_Temas_ConfigManager
    /// - .plist: Carga configuraciones desde GV_Temas_Configs.plist
    static var source: GV_Temas_ConfigSourceType = .swift  // 🚩 CAMBIAR AQUÍ
    
    private init() {}
    
    /// Carga la configuración de tema según la fuente activa
    /// - Parameter type: Tipo de tema
    /// - Returns: Configuración del tema
    func loadTemasConfig(for type: GV_Temas_Type) -> GV_Temas_Config {
        switch GV_Temas_ConfigLoader.source {
        case .swift:
            return loadFromSwift(type)
        case .plist:
            return loadFromPlist(type)
        }
    }
    
    /// Carga configuración desde código Swift
    private func loadFromSwift(_ type: GV_Temas_Type) -> GV_Temas_Config {
        return GV_Temas_ConfigManager.shared.getTemasConfigFromSwift(for: type)
    }
    
    /// Carga configuración desde Plist
    private func loadFromPlist(_ type: GV_Temas_Type) -> GV_Temas_Config {
        // TODO: Implementar carga desde Plist
        // Por ahora, usa Swift como fallback
        print("⚠️ Carga desde Plist no implementada aún para temas, usando Swift como fallback")
        return loadFromSwift(type)
    }
    
    /// Devuelve información sobre la fuente activa
    static func currentSourceInfo() -> String {
        switch source {
        case .swift:
            return "🎨 Configuración Temas: SWIFT (Hardcoded)"
        case .plist:
            return "📄 Configuración Temas: PLIST (GV_Temas_Configs.plist)"
        }
    }
}


