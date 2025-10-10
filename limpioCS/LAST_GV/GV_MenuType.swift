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
    case principal = 1      // Menu Principal (todas las opciones)
    case mapa = 2           // Menu Mapa (sin Admin Datos)
    case lista = 3          // Menu Lista (sin Búsquedas Avanzadas)
    case simple = 4         // Menu Simple (solo configuraciones básicas)
    case ninguno = 5        // Sin Menu (sin hamburguesa)
    case myPrueba = 6        // Es mi prueba
    
    var id: Int { self.rawValue }
    
    /// Nombre descriptivo del tipo de menú
    var displayName: String {
        switch self {
        case .principal:
            return "Menú Principal"
        case .mapa:
            return "Menú Mapa"
        case .lista:
            return "Menú Lista"
        case .simple:
            return "Menú Simple"
        case .ninguno:
            return "Sin Menú"
        case .myPrueba:
            return "Mi Prueba"
        }
    }
    
    /// Descripción de las opciones disponibles en este menú
    var description: String {
        switch self {
        case .principal:
            return "Todas las opciones: Temas, Admin Datos, Búsquedas Avanzadas, Configuraciones"
        case .mapa:
            return "Opciones de mapa: Temas, Búsquedas Avanzadas, Configuraciones (sin Admin Datos)"
        case .lista:
            return "Opciones de lista: Temas, Admin Datos, Configuraciones (sin Búsquedas Avanzadas)"
        case .simple:
            return "Opciones básicas: Solo Configuraciones"
        case .ninguno:
            return "Sin menú hamburguesa visible"
        case .myPrueba:
            return "Mi Prueba"
        }
    }
    
    /// Indica si este tipo de menú muestra el icono de hamburguesa
    var showHamburgerIcon: Bool {
        switch self {
        case .ninguno:
            return false
        default:
            return true
        }
    }
    
    /// Lista de opciones disponibles en este tipo de menú
    var availableOptions: [MenuOption] {
        switch self {
        case .principal:
            return [.themes, .adminDatos, .advancedSearch, .mySettings]
        case .mapa:
            return [.themes, .advancedSearch, .mySettings]
        case .lista:
            return [.themes, .advancedSearch, .mySettings]
        case .simple:
            return [.themes]
        case .ninguno:
            return []
        case .myPrueba:
            return [.adminDatos]
        }
    }
    
    /// Icono del sistema para este tipo de menú
    var icon: String {
        switch self {
        case .principal:
            return "line.3.horizontal"
        case .mapa:
            return "map"
        case .lista:
            return "list.bullet"
        case .simple:
            return "gear"
        case .ninguno:
            return ""
        case .myPrueba:
            return "folder.fill"
        }

    }
}

/// Tipo de navegación para opciones de menú
enum GV_NavigationType {
    case sheet      // Modal con .sheet()
    case navigation // NavigationLink
    case action     // Acción directa (no navegación)
}

/// Opciones de menú disponibles
enum MenuOption: String, CaseIterable {
    case themes = "Temas"
    case adminDatos = "Admin Datos"
    case advancedSearch = "Búsquedas Avanzadas"
    case mySettings = "Mis Configuraciones"
    case exit = "Regresar"
    case goToPortada = "Ir a Portada"
    
    var icon: String {
        switch self {
        case .themes:
            return "paintpalette"
        case .adminDatos:
            return "cylinder"
        case .advancedSearch:
            return "magnifyingglass.circle"
        case .mySettings:
            return "gearshape"
        case .exit:
            return "door.exit.open"
        case .goToPortada:
            return "house.fill"
        }
    }
    
    /// Tipo de navegación para esta opción (default: .sheet)
    var navigationType: GV_NavigationType {
        switch self {
        case .themes:
            return .sheet
        case .adminDatos:
            return .sheet
        case .advancedSearch:
            return .sheet
        case .mySettings:
            return .sheet
        case .exit:
            return .action
        case .goToPortada:
            return .navigation
        }
    }
    
    /// Vista destino para esta opción
    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .themes:
            GV_Temas_SelectorView()  // ✨ Vista real de selector de temas
        case .adminDatos:
            GV_SCR_vg_EstablecimientosListaView()  // ✨ Vista migrada de participantes
        case .advancedSearch:
            GV_SCR_vg_FavoritosView()  // ✨ Vista migrada de favoritos
        case .mySettings:
            Text("Mis Configuraciones")
                .padding()
        case .exit:
            Text("Salir")  // ✨ Acción especial - se manejará en el closure
                .padding()
        case .goToPortada:
            GV_SCR_tc_menuprincipal()  // ✨ Navegar al menú principal (portada)
        }
    }
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
            "availableOptions": self.availableOptions.map { $0.rawValue },
            "icon": self.icon
        ]
    }
    
    /// Devuelve toda la información del tipo de menú como texto formateado
    /// - Returns: String formateado con toda la información
    func showAllFormatted() -> String {
        let optionsList = availableOptions.map { "  • \($0.rawValue) (\($0.icon))" }.joined(separator: "\n")
        
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

