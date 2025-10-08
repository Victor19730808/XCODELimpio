//
//  MenuManager.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Gestor singleton para manejar configuraciones de menú
//

import SwiftUI

/// Gestor singleton para configuraciones de menú
class MenuManager {
    static let shared = MenuManager()
    
    private let configuration = MenuConfiguration()
    
    private init() {}
    
    /// Obtiene las opciones de menú para un tipo de vista específico
    func getMenuOptions(for viewType: ViewType) -> [MenuOption] {
        return configuration.getOptions(for: viewType)
    }
    
    /// Verifica si una opción está habilitada para un tipo de vista
    func isOptionEnabled(_ option: MenuOption, for viewType: ViewType) -> Bool {
        return configuration.isOptionEnabled(option, for: viewType)
    }
    
    /// Crea items de menú para un tipo de vista con acciones específicas
    func createMenuItems(for viewType: ViewType, actions: [MenuOption: () -> Void]) -> [HamburgerMenuItem] {
        let enabledOptions = getMenuOptions(for: viewType)
        
        return enabledOptions.compactMap { option in
            guard let action = actions[option] else { return nil }
            return HamburgerMenuItem(option: option, action: action)
        }
    }
    
    /// Obtiene todas las configuraciones (para debugging)
    func getAllConfigurations() -> [ViewType: Set<MenuOption>] {
        return configuration.getAllConfigurations()
    }
}
