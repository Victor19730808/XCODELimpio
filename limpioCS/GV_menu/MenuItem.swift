//
//  MenuItem.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Estructura para representar una opción de menú
//

import SwiftUI

/// Estructura que representa una opción de menú hamburguesa
struct HamburgerMenuItem {
    let option: MenuOption
    let action: () -> Void
    
    init(option: MenuOption, action: @escaping () -> Void) {
        self.option = option
        self.action = action
    }
}

/// Extensión para crear items de menú fácilmente
extension HamburgerMenuItem {
    static func themes(action: @escaping () -> Void) -> HamburgerMenuItem {
        return HamburgerMenuItem(option: .themes, action: action)
    }
    
    static func adminDatos(action: @escaping () -> Void) -> HamburgerMenuItem {
        return HamburgerMenuItem(option: .adminDatos, action: action)
    }
    
    static func advancedSearch(action: @escaping () -> Void) -> HamburgerMenuItem {
        return HamburgerMenuItem(option: .advancedSearch, action: action)
    }
    
    static func mySettings(action: @escaping () -> Void) -> HamburgerMenuItem {
        return HamburgerMenuItem(option: .mySettings, action: action)
    }
}
