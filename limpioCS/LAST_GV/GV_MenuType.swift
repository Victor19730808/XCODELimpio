//
//  GV_MenuType.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Definición de tipos de menú para el sistema General Views
//

import SwiftUI

/// Enum que define los tipos de menú disponibles en el sistema General Views
enum GV_MenuType: Int, CaseIterable, Identifiable {
    case principal = 1
    case mapa = 2
    case splash = 3
    case ninguno = 4
    
    var id: Int { self.rawValue }
    
    var displayName: String {
        return self.menuConfig.displayName ?? "Menú"
    }
    
    var description: String {
        return self.menuConfig.description ?? ""
    }
    
    var showHamburgerIcon: Bool {
        return self.menuConfig.showMenu
    }
    
    var icon: String {
        return self.menuConfig.iconName
    }
    
    var availableOptions: [GV_MenuOptionModel] {
        return self.menuConfig.options
    }
}

enum GV_NavigationType {
    case sheet
    case navigation
    case action
}

/// Extensión para obtener información formateada del tipo de menú
extension GV_MenuType {
    /// Devuelve un diccionario con todos los valores del tipo de menú
    /// - Returns: Diccionario con id, rawValue, displayName, description, showHamburgerIcon, availableOptions
    func showAll() -> [String: Any] {
        return [
            "id": self.id,
            "rawValue": self.rawValue,
            "displayName": self.displayName,
            "description": self.description,
            "showHamburgerIcon": self.showHamburgerIcon,
            "availableOptions": self.availableOptions.map { $0.title },
            "icon": self.icon
        ]
    }
    
    func showAllFormatted() -> String {
        let optionsList = availableOptions.map { "  • \($0.title) (\($0.icon))" }.joined(separator: "\n")
        
        return """
        🍔 INFORMACIÓN DEL TIPO DE MENÚ
        ═══════════════════════════════
        
        🔢 ID: \(self.id)
        📊 Raw Value: \(self.rawValue)
        📝 Nombre: \(self.displayName)
        📄 Descripción: \(self.description)
        🎨 Icono: \(self.icon)
        👁️  Muestra Hamburguesa: \(self.showHamburgerIcon ? "Sí" : "No")
        
        📋 OPCIONES DISPONIBLES (\(self.availableOptions.count))
        ═══════════════════════════════
        \(optionsList.isEmpty ? "  (Sin opciones)" : optionsList)
        
        ═══════════════════════════════
        """
    }
}

