//
//  MenuConfiguration.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Configuración centralizada de opciones de menú por vista
//

import SwiftUI

/// Tipos de vista para configurar opciones de menú
enum ViewType: String, CaseIterable {
    case main = "Main"                    // PORT_PASO, ContentView
    case map = "Map"                      // MapView, MapClustersView  
    case list = "List"                    // EstablecimientosListaView
    case favorites = "Favorites"          // FavoritosView
    case promotions = "Promotions"        // PromocionesView
    
    var displayName: String {
        switch self {
        case .main: return "Vistas Principales"
        case .map: return "Mapas"
        case .list: return "Listas"
        case .favorites: return "Favoritos"
        case .promotions: return "Promociones"
        }
    }
}

/// Opciones disponibles en el menú hamburguesa
enum MenuOption: String, CaseIterable {
    case themes = "themes"
    case adminDatos = "adminDatos"
    case advancedSearch = "advancedSearch"
    case mySettings = "mySettings"
    
    var displayName: String {
        switch self {
        case .themes: return "Tema"
        case .adminDatos: return "Admin Datos"
        case .advancedSearch: return "Búsquedas Avanzadas"
        case .mySettings: return "Mis Configuraciones"
        }
    }
    
    var iconName: String {
        switch self {
        case .themes: return "paintbrush"
        case .adminDatos: return "wrench.and.screwdriver"
        case .advancedSearch: return "magnifyingglass.circle"
        case .mySettings: return "gear"
        }
    }
}

/// Configuración de opciones de menú por tipo de vista
class MenuConfiguration {
    
    /// Configuraciones por tipo de vista
    private let configurations: [ViewType: Set<MenuOption>] = [
        .main: [.themes, .adminDatos, .advancedSearch, .mySettings],
        .map: [.themes, .advancedSearch, .mySettings], // Sin Admin Datos
        .list: [.themes, .adminDatos, .mySettings], // Sin Búsquedas Avanzadas (ya tiene su propia)
        .favorites: [.themes, .adminDatos, .advancedSearch, .mySettings],
        .promotions: [.themes, .adminDatos, .advancedSearch, .mySettings]
    ]
    
    /// Obtiene las opciones disponibles para un tipo de vista
    func getOptions(for viewType: ViewType) -> [MenuOption] {
        return configurations[viewType]?.sorted(by: { $0.rawValue < $1.rawValue }) ?? []
    }
    
    /// Verifica si una opción está habilitada para un tipo de vista
    func isOptionEnabled(_ option: MenuOption, for viewType: ViewType) -> Bool {
        return configurations[viewType]?.contains(option) ?? false
    }
    
    /// Permite configurar dinámicamente las opciones para una vista específica
    func setOptions(_ options: Set<MenuOption>, for viewType: ViewType) {
        // Esta funcionalidad se puede expandir en el futuro para configuraciones personalizadas
        // Por ahora usamos las configuraciones predefinidas
    }
    
    /// Obtiene todas las configuraciones (para debugging o administración)
    func getAllConfigurations() -> [ViewType: Set<MenuOption>] {
        return configurations
    }
}
