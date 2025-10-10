//
//  GV_MenuConfig.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Configuración y gestión de menús por tipo
//

import SwiftUI

/// Estructura que define la configuración de un menú.
struct GV_MenuConfig {
    let showMenu: Bool
    let iconName: String
    let iconSize: CGFloat
    let iconColor: Color
    let options: [MenuOption]
    let backgroundColor: Color
    let padding: CGFloat
}

/// Clase singleton para gestionar y proporcionar configuraciones de menús.
class GV_MenuConfigManager {
    static let shared = GV_MenuConfigManager()
    
    private init() {}
    
    /// Devuelve la configuración de menú para un tipo específico.
    /// Usa el GV_ConfigLoader para decidir si carga desde Swift o Plist
    func getMenuConfig(for type: GV_MenuType) -> GV_MenuConfig {
        return GV_ConfigLoader.shared.loadMenuConfig(for: type)
    }
    
    /// Devuelve la configuración de menú desde código Swift (hardcoded)
    func getMenuConfigFromSwift(for type: GV_MenuType) -> GV_MenuConfig {
        switch type {
        case .principal:
            return GV_MenuConfig(
                showMenu: true,
                iconName: "line.3.horizontal",
                iconSize: 24,
                iconColor: .white,
                options: [.themes, .adminDatos, .advancedSearch, .mySettings, .exit, .goToPortada],
                backgroundColor: .clear,
                padding: 16
            )
        case .mapa:
            return GV_MenuConfig(
                showMenu: true,
                iconName: "map",
                iconSize: 22,
                iconColor: .white,
                options: [.themes, .advancedSearch, .mySettings, .exit, .goToPortada],
                backgroundColor: .clear,
                padding: 20
            )
        case .lista:
            return GV_MenuConfig(
                showMenu: true,
                iconName: "list.bullet",
                iconSize: 22,
                iconColor: .white,
                options: [.themes, .adminDatos, .mySettings, .exit, .goToPortada],
                backgroundColor: .clear,
                padding: 20
            )
        case .simple:
            return GV_MenuConfig(
                showMenu: true,
                iconName: "gear",
                iconSize: 20,
                iconColor: .white,
                options: [.themes, .exit, .goToPortada],
                backgroundColor: .clear,
                padding: 15
            )
        case .ninguno:
            return GV_MenuConfig(
                showMenu: false,
                iconName: "",
                iconSize: 0,
                iconColor: .clear,
                options: [],
                backgroundColor: .clear,
                padding: 0
            )
        case .myPrueba:
            return GV_MenuConfig(
                showMenu: true,
                iconName: "folder.fill",
                iconSize: 20,
                iconColor: .white,
                options: [.adminDatos, .exit, .goToPortada],
                backgroundColor: .clear,
                padding: 15
            )
        }
    }
}

/// Extensión para GV_MenuType con configuración de menú
extension GV_MenuType {
    /// Obtiene la configuración de menú para este tipo
    var menuConfig: GV_MenuConfig {
        return GV_MenuConfigManager.shared.getMenuConfig(for: self)
    }
    
    /// Función que devuelve directamente el View del menú con navegación automática
    /// - Parameters:
    ///   - showThemes: Binding para mostrar vista de Temas
    ///   - showAdminDatos: Binding para mostrar vista de Admin Datos
    ///   - showAdvancedSearch: Binding para mostrar vista de Búsquedas Avanzadas
    ///   - showMySettings: Binding para mostrar vista de Mis Configuraciones
    ///   - onExit: Closure para manejar la acción de "Regresar"
    ///   - onGoToPortada: Closure para manejar la acción de "Ir a Portada"
    /// - Returns: View del menú configurado
    @ViewBuilder
    func menuView(
        showThemes: Binding<Bool>,
        showAdminDatos: Binding<Bool>,
        showAdvancedSearch: Binding<Bool>,
        showMySettings: Binding<Bool>,
        onExit: @escaping () -> Void = {},
        onGoToPortada: @escaping () -> Void = {}
    ) -> some View {
        let config = menuConfig
        
        if config.showMenu {
            Menu {
                ForEach(config.options, id: \.self) { option in
                    Button(action: {
                        switch option {
                        case .themes:
                            showThemes.wrappedValue = true
                        case .adminDatos:
                            showAdminDatos.wrappedValue = true
                        case .advancedSearch:
                            showAdvancedSearch.wrappedValue = true
                        case .mySettings:
                            showMySettings.wrappedValue = true
                        case .exit:
                            // ✨ Acción especial: regresar
                            onExit()
                        case .goToPortada:
                            // ✨ Acción especial: ir a portada
                            onGoToPortada()
                        }
                    }) {
                        Label(option.rawValue, systemImage: option.icon)
                    }
                }
            } label: {
                Image(systemName: config.iconName)
                    .font(.system(size: config.iconSize))
                    .foregroundColor(config.iconColor)
            }
        } else {
            // Sin menú - espacio vacío para mantener centrado el texto
            Color.clear
                .frame(width: 30, height: 30)
        }
    }
}
