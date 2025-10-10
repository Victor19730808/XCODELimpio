//
//  GV_Temas_Type.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Definición de tipos de temas para el sistema General Views
//

import SwiftUI

/// Enum que define los tipos de tema disponibles en el sistema General Views
enum GV_Temas_Type: Int, CaseIterable, Identifiable {
    case modoClaro = 1      // Modo Claro
    case modoOscuro = 2     // Modo Oscuro
    case buenFin = 3        // Tema Buen Fin
    
    var id: Int { self.rawValue }
    
    /// Nombre descriptivo del tema
    var displayName: String {
        switch self {
        case .modoClaro:
            return "Modo Claro"
        case .modoOscuro:
            return "Modo Oscuro"
        case .buenFin:
            return "Buen Fin"
        }
    }
    
    /// Descripción del tema
    var description: String {
        switch self {
        case .modoClaro:
            return "Tema claro, ideal para uso diurno"
        case .modoOscuro:
            return "Tema oscuro, ideal para uso nocturno"
        case .buenFin:
            return "Tema especial Buen Fin con colores rojo, blanco y gris"
        }
    }
    
    /// Icono representativo del tema
    var icon: String {
        switch self {
        case .modoClaro:
            return "sun.max.fill"
        case .modoOscuro:
            return "moon.fill"
        case .buenFin:
            return "tag.fill"
        }
    }
    
    /// ColorScheme preferido para este tema
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .modoClaro:
            return .light
        case .modoOscuro:
            return .dark
        case .buenFin:
            return .light  // Buen Fin usa esquema claro
        }
    }
}

/// Extensión para obtener información formateada del tema
extension GV_Temas_Type {
    /// Devuelve un diccionario con todos los valores del tema
    /// - Returns: Diccionario con id, rawValue, displayName, description, icon
    func showAll() -> [String: Any] {
        let schemeText = preferredColorScheme == .light ? "light" : preferredColorScheme == .dark ? "dark" : "auto"
        return [
            "id": self.id,
            "rawValue": self.rawValue,
            "displayName": self.displayName,
            "description": self.description,
            "icon": self.icon,
            "preferredColorScheme": schemeText
        ]
    }
    
    /// Devuelve toda la información del tema como texto formateado
    /// - Returns: String formateado con toda la información
    func showAllFormatted() -> String {
        let schemeText = preferredColorScheme == .light ? "light" : preferredColorScheme == .dark ? "dark" : "auto"
        return """
        🎨 INFORMACIÓN DEL TEMA
        ══════════════════════
        
        🔢 ID: \(self.id)
        📊 Raw Value: \(self.rawValue)
        📝 Nombre: \(self.displayName)
        📄 Descripción: \(self.description)
        🎨 Icono: \(self.icon)
        🌓 Color Scheme: \(schemeText)
        
        ══════════════════════
        """
    }
}

