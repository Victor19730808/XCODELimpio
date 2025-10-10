//
//  GV_HeaderConfig.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Configuración de headers por tipo
//

import SwiftUI

/// Configuración de header para cada tipo
struct GV_HeaderConfig {
    /// Altura del header en puntos
    let height: CGFloat
    
    /// Color de fondo del header
    let backgroundColor: Color
    
    /// Texto del caption
    let caption: String
    
    /// Padding horizontal del header
    let horizontalPadding: CGFloat
    
    /// Padding vertical del header
    let verticalPadding: CGFloat
}

/// Manager para obtener configuraciones de header por tipo
class GV_HeaderConfigManager {
    static let shared = GV_HeaderConfigManager()
    
    private init() {}
    
    /// Obtiene la configuración de header para un tipo específico
    /// - Parameter headerType: Tipo de header
    /// - Returns: Configuración del header
    func getHeaderConfig(for headerType: GV_HeaderType) -> GV_HeaderConfig {
        // ✨ Obtener colores del tema actual automáticamente
        let themeManager = GV_Temas_Manager.shared
        let currentTheme = themeManager.currentTheme
        
        switch headerType {
        case .tipo1:
            return GV_HeaderConfig(
                height: 80,
                backgroundColor: currentTheme.temasConfig.headerBackground,  // ✨ Color del tema
                caption: "Header Simple",
                horizontalPadding: 20,
                verticalPadding: 15
            )
            
        case .tipo2:
            return GV_HeaderConfig(
                height: 70,
                backgroundColor: currentTheme.temasConfig.headerBackground,  // ✨ Color del tema
                caption: "Header con Menú",
                horizontalPadding: 20,
                verticalPadding: 20
            )
            
        default:
            // Para tipos no implementados aún, usar tipo1 como default
            return GV_HeaderConfig(
                height: 80,
                backgroundColor: currentTheme.temasConfig.headerBackground,  // ✨ Color del tema
                caption: "Header Default",
                horizontalPadding: 20,
                verticalPadding: 15
            )
        }
    }
}

/// Extensión para GV_HeaderType con configuración de header
extension GV_HeaderType {
    /// Obtiene la configuración de header para este tipo
    var headerConfig: GV_HeaderConfig {
        return GV_HeaderConfigManager.shared.getHeaderConfig(for: self)
    }
    
    
    /// Función que devuelve directamente el View del header con menú integrado
    /// - Parameters:
    ///   - caption: Texto personalizado para el caption
    ///   - imagen: Nombre de la imagen desde Assets (opcional)
    ///   - menuType: Tipo de menú a mostrar (default: .ninguno)
    ///   - showThemes: Binding para mostrar vista de Temas
    ///   - showAdminDatos: Binding para mostrar vista de Admin Datos
    ///   - showAdvancedSearch: Binding para mostrar vista de Búsquedas Avanzadas
    ///   - showMySettings: Binding para mostrar vista de Mis Configuraciones
    /// - Returns: View del header configurado
    @ViewBuilder
    func headerView(
        _ caption: String,
        _ imagen: String? = nil,
        _ menuType: GV_MenuType = .ninguno,
        showThemes: Binding<Bool> = .constant(false),
        showAdminDatos: Binding<Bool> = .constant(false),
        showAdvancedSearch: Binding<Bool> = .constant(false),
        showMySettings: Binding<Bool> = .constant(false)
    ) -> some View {
        let config = headerConfig
        
        VStack(spacing: 0) {
            HStack {
                // Imagen del lado izquierdo (si se proporciona)
                if let imagen = imagen {
                    Image(imagen)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(GV_Temas_Manager.shared.headerIcon)  // ✨ Color del tema
                } else {
                    // Espacio vacío para mantener centrado el texto
                    Color.clear
                        .frame(width: 30, height: 30)
                }
                
                Spacer()
                
                Text(caption)
                    .font(.headline)
                    .foregroundColor(GV_Temas_Manager.shared.headerText)  // ✨ Color del tema
                
                Spacer()
                
                // Menú integrado automáticamente
                menuType.menuView(
                    showThemes: showThemes,
                    showAdminDatos: showAdminDatos,
                    showAdvancedSearch: showAdvancedSearch,
                    showMySettings: showMySettings
                )
            }
            .padding(.horizontal, config.horizontalPadding)
            .padding(.vertical, config.verticalPadding)
        }
        .frame(height: config.height)
        .background(config.backgroundColor)
    }
    
    /// Función TODO EN UNO - Header con menú completamente automático
    /// Maneja internamente los @State y .sheet() para máxima simplicidad
    /// - Parameters:
    ///   - caption: Texto personalizado para el caption
    ///   - imagen: Nombre de la imagen desde Assets (opcional)
    ///   - menuType: Tipo de menú a mostrar (default: .ninguno)
    /// - Returns: View del header con menú completamente funcional
    @ViewBuilder
    func headerViewWithMenu(
        _ caption: String,
        _ imagen: String? = nil,
        _ menuType: GV_MenuType = .ninguno
    ) -> some View {
        GV_HeaderWithMenuWrapper(
            headerType: self,
            caption: caption,
            imagen: imagen,
            menuType: menuType
        )
    }
}

// MARK: - Wrapper View para manejar estados internamente

/// Vista wrapper que maneja internamente los @State y .sheet() del menú
private struct GV_HeaderWithMenuWrapper: View {
    let headerType: GV_HeaderType
    let caption: String
    let imagen: String?
    let menuType: GV_MenuType
    
    @ObservedObject private var themeManager = GV_Temas_Manager.shared  // ✨ Observar cambios de tema
    @Environment(\.dismiss) private var dismiss  // ✨ Para manejar "Regresar"
    @State private var showThemes = false
    @State private var showAdminDatos = false
    @State private var showAdvancedSearch = false
    @State private var showMySettings = false
    
    var body: some View {
        // ✨ Usar configuración dinámica basada en el tema actual
        let config = GV_HeaderConfig(
            height: headerType.headerConfig.height,
            backgroundColor: themeManager.headerBackground,  // ✨ Color dinámico del tema
            caption: headerType.headerConfig.caption,
            horizontalPadding: headerType.headerConfig.horizontalPadding,
            verticalPadding: headerType.headerConfig.verticalPadding
        )
        
        VStack(spacing: 0) {
            HStack {
                // Imagen del lado izquierdo (si se proporciona)
                if let imagen = imagen {
                    Image(imagen)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(GV_Temas_Manager.shared.headerIcon)  // ✨ Color del tema
                } else {
                    // Espacio vacío para mantener centrado el texto
                    Color.clear
                        .frame(width: 30, height: 30)
                }
                
                Spacer()
                
                Text(caption)
                    .font(.headline)
                    .foregroundColor(GV_Temas_Manager.shared.headerText)  // ✨ Color del tema
                
                Spacer()
                
                // Menú integrado automáticamente
                menuType.menuView(
                    showThemes: $showThemes,
                    showAdminDatos: $showAdminDatos,
                    showAdvancedSearch: $showAdvancedSearch,
                    showMySettings: $showMySettings,
                    onExit: {
                        dismiss()  // ✨ Regresar
                    },
                    onGoToPortada: {
                        // ✨ Ir a portada - se manejará con NavigationLink
                        // Por ahora, solo regresamos
                        dismiss()
                    }
                )
            }
            .padding(.horizontal, config.horizontalPadding)
            .padding(.vertical, config.verticalPadding)
        }
        .frame(height: config.height)
        .background(config.backgroundColor)
        // Sheets automáticos con las vistas destino configuradas
        .sheet(isPresented: $showThemes) {
            MenuOption.themes.destinationView
        }
        .sheet(isPresented: $showAdminDatos) {
            MenuOption.adminDatos.destinationView
        }
        .sheet(isPresented: $showAdvancedSearch) {
            MenuOption.advancedSearch.destinationView
        }
        .sheet(isPresented: $showMySettings) {
            MenuOption.mySettings.destinationView
        }
    }
}
