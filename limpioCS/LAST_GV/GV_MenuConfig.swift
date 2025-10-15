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
    let displayName: String?
    let description: String?
    let showMenu: Bool
    let iconName: String
    let iconSize: CGFloat
    let iconColor: Color
    let options: [GV_MenuOptionModel]
    let backgroundColor: Color
    let padding: CGFloat
}

/// Clase singleton para gestionar y proporcionar configuraciones de menús.
class GV_MenuConfigManager {
    static let shared = GV_MenuConfigManager()
    
    private init() {}
    
    func getMenuConfig(for type: GV_MenuType) -> GV_MenuConfig {
        return GV_ConfigLoader.shared.loadMenuConfig(for: type)
    }
    
    func getMenuConfigFromSwift(for type: GV_MenuType) -> GV_MenuConfig {
        ProductionLogger.log("No se pudo cargar menú tipo \(type.rawValue) desde Plist", level: .error)
        ProductionLogger.log("Verifica que GV_MenuConfigs.plist esté correctamente configurado", level: .warning)
        
        return GV_MenuConfig(
            displayName: "Error de Configuración",
            description: "No se pudo cargar el menú desde el Plist",
            showMenu: true,
            iconName: "exclamationmark.triangle.fill",
            iconSize: 24,
            iconColor: .red,
            options: [],
            backgroundColor: .clear,
            padding: 16
        )
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
        showArrastrePrueba: Binding<Bool> = .constant(false),
        showAdminDatos: Binding<Bool>,
        showAdvancedSearch: Binding<Bool>,
        showMySettings: Binding<Bool>,
        onExit: @escaping () -> Void = {},
        onGoToPortada: @escaping () -> Void = {},
        onGoBack: @escaping () -> Void = {},
        onGoToEstablecimientos: @escaping () -> Void = {},
        onGoToFavoritos: @escaping () -> Void = {},
        onGoToMapa: @escaping () -> Void = {}
    ) -> some View {
        let config = menuConfig
        
        if config.showMenu {
            if config.options.isEmpty && config.iconName == "exclamationmark.triangle.fill" {
                Button(action: {
                    ProductionLogger.log("Menú no configurado correctamente", level: .error)
                }) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: config.iconSize))
                        .foregroundColor(.red)
                }
            } else {
                Menu {
                    ForEach(filteredOptions(config.options)) { option in
                        Button(action: {
                            handleMenuAction(
                                option: option,
                                showThemes: showThemes,
                                showArrastrePrueba: showArrastrePrueba,
                                showAdminDatos: showAdminDatos,
                                showAdvancedSearch: showAdvancedSearch,
                                showMySettings: showMySettings,
                                onExit: onExit,
                                onGoToPortada: onGoToPortada,
                                onGoBack: onGoBack,
                                onGoToEstablecimientos: onGoToEstablecimientos,
                                onGoToFavoritos: onGoToFavoritos,
                                onGoToMapa: onGoToMapa
                            )
                        }) {
                            Label(option.title, systemImage: option.icon)
                        }
                    }
                } label: {
                    Image(systemName: config.iconName)
                        .font(.system(size: config.iconSize))
                        .foregroundColor(config.iconColor)
                }
            }
        } else {
            Color.clear
                .frame(width: 30, height: 30)
        }
    }
    
    private func filteredOptions(_ options: [GV_MenuOptionModel]) -> [GV_MenuOptionModel] {
        #if DEBUG
        return options
        #else
        return options.filter { !$0.debugOnly }
        #endif
    }
    
    private func handleMenuAction(
        option: GV_MenuOptionModel,
        showThemes: Binding<Bool>,
        showArrastrePrueba: Binding<Bool>,
        showAdminDatos: Binding<Bool>,
        showAdvancedSearch: Binding<Bool>,
        showMySettings: Binding<Bool>,
        onExit: @escaping () -> Void,
        onGoToPortada: @escaping () -> Void,
        onGoBack: @escaping () -> Void,
        onGoToEstablecimientos: @escaping () -> Void,
        onGoToFavoritos: @escaping () -> Void,
        onGoToMapa: @escaping () -> Void
    ) {
        let sheetBindings: [String: Binding<Bool>] = [
            "themes": showThemes,
            "adminDatos": showAdminDatos,
            "advancedSearch": showAdvancedSearch,
            "mySettings": showMySettings
        ]
        
        let navigationActions: [String: () -> Void] = [
            "goToPortada": onGoToPortada,
            "goToEstablecimientos": onGoToEstablecimientos,
            "goToFavoritos": onGoToFavoritos,
            "goToMapa": onGoToMapa
        ]
        
        let actionHandlers: [String: () -> Void] = [
            "exit": onExit,
            "goBack": onGoBack,
            "goToConcanaco": { openURL("https://www.concanaco.com.mx") },
            "goToHHT": { openURL("https://www.hht.mx") },
            "goToManual": { openURL("https://youtu.be/pIBVWT8nEe0") }
        ]
        
        switch option.navigationTypeEnum {
        case .sheet:
            if let binding = sheetBindings[option.id] {
                binding.wrappedValue = true
            } else {
                print("⚠️ Sheet '\(option.id)' no está registrado en sheetBindings")
            }
        case .navigation:
            if let action = navigationActions[option.id] {
                action()
            } else {
                print("⚠️ Navegación '\(option.id)' no está registrada en navigationActions")
            }
        case .action:
            if let action = actionHandlers[option.id] {
                action()
            } else {
                print("⚠️ Acción '\(option.id)' no está registrada en actionHandlers")
            }
        }
    }
}

// MARK: - Helper Functions
private func openURL(_ urlString: String) {
    guard let url = URL(string: urlString) else { return }
    UIApplication.shared.open(url)
}
