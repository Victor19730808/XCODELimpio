//
//  GV_MenuConfigSource.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Sistema de carga de configuraciones (Swift vs Plist)
//

import Foundation
import SwiftUI

/// Fuente de configuración para los menús
enum GV_ConfigSource {
    case swift  // Configuración desde código Swift (GV_MenuConfigManager)
    case plist  // Configuración desde archivo MenuConfigs.plist
}

/// Loader de configuraciones con bandera para cambiar entre fuentes
class GV_ConfigLoader {
    static let shared = GV_ConfigLoader()
    
    /// 🚩 BANDERA: Cambia esta variable para usar Swift o Plist
    /// - .swift: Usa configuraciones hardcoded en GV_MenuConfigManager
    /// - .plist: Carga configuraciones desde MenuConfigs.plist
    static var source: GV_ConfigSource = .swift  // 🚩 CAMBIAR AQUÍ
    
    private init() {}
    
    /// Carga la configuración de menú según la fuente activa
    /// - Parameter type: Tipo de menú
    /// - Returns: Configuración del menú
    func loadMenuConfig(for type: GV_MenuType) -> GV_MenuConfig {
        switch GV_ConfigLoader.source {
        case .swift:
            return loadFromSwift(type)
        case .plist:
            return loadFromPlist(type)
        }
    }
    
    /// Carga configuración desde código Swift
    private func loadFromSwift(_ type: GV_MenuType) -> GV_MenuConfig {
        return GV_MenuConfigManager.shared.getMenuConfigFromSwift(for: type)
    }
    
    /// Carga configuración desde Plist
    private func loadFromPlist(_ type: GV_MenuType) -> GV_MenuConfig {
        // Intentar cargar desde Plist en LAST_GV/
        guard let plistPath = Bundle.main.path(forResource: "LAST_GV/GV_MenuConfigs", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: [String: Any]] else {
            print("⚠️ No se pudo cargar GV_MenuConfigs.plist, usando Swift como fallback")
            return loadFromSwift(type)
        }
        
        // Obtener configuración para el tipo específico
        let typeKey = type.rawValue.description
        guard let config = plist[typeKey] else {
            print("⚠️ No se encontró configuración para tipo \(typeKey), usando Swift como fallback")
            return loadFromSwift(type)
        }
        
        // Parsear configuración
        let showMenu = config["showMenu"] as? Bool ?? true
        let iconName = config["iconName"] as? String ?? "line.3.horizontal"
        let iconSize = config["iconSize"] as? CGFloat ?? 22
        let padding = config["padding"] as? CGFloat ?? 16
        
        // Parsear opciones
        let optionsArray = config["options"] as? [String] ?? []
        let options = optionsArray.compactMap { optionString -> MenuOption? in
            switch optionString {
            case "themes": return .themes
            case "adminDatos": return .adminDatos
            case "advancedSearch": return .advancedSearch
            case "mySettings": return .mySettings
            default: return nil
            }
        }
        
        return GV_MenuConfig(
            showMenu: showMenu,
            iconName: iconName,
            iconSize: iconSize,
            iconColor: .white,
            options: options,
            backgroundColor: .clear,
            padding: padding
        )
    }
    
    /// Devuelve información sobre la fuente activa
    static func currentSourceInfo() -> String {
        switch source {
        case .swift:
            return "📱 Configuración: SWIFT (Hardcoded)"
        case .plist:
            return "📄 Configuración: PLIST (MenuConfigs.plist)"
        }
    }
}

