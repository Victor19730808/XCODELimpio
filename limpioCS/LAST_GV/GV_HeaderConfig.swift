//
//  GV_HeaderConfig.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Configuración de headers por tipo
//

import SwiftUI
import UIKit

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

    // Lee valor simple desde GV_Headers_Config.plist (fileprivate para uso en este archivo)
    fileprivate func valueForKey(_ key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "GV_Headers_Config", ofType: "plist"),
              let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else { return nil }
        return plist[key] as? String
    }

    /// Verifica si existe un asset con ese nombre
    fileprivate func assetExists(_ name: String) -> Bool {
        return UIImage(named: name) != nil
    }
    
    /// Obtiene la configuración de header para un tipo específico
    /// - Parameter headerType: Tipo de header
    /// - Returns: Configuración del header
    func getHeaderConfig(for headerType: GV_HeaderType) -> GV_HeaderConfig {
        let themeManager = GV_Temas_Manager.shared
        let currentTheme = themeManager.currentTheme
        
        switch headerType {
        case .tipo1:
            return GV_HeaderConfig(
                height: 80,
                backgroundColor: currentTheme.temasConfig.headerBackground,
                caption: "Header Simple",
                horizontalPadding: 20,
                verticalPadding: 15
            )
            
        case .tipo2:
            return GV_HeaderConfig(
                height: 70,
                backgroundColor: currentTheme.temasConfig.headerBackground,
                caption: "Header con Menú",
                horizontalPadding: 16,
                verticalPadding: 20
            )
            
        default:
            return GV_HeaderConfig(
                height: 80,
                backgroundColor: currentTheme.temasConfig.headerBackground,
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
                // Lado izquierdo - Imagen o espacio vacío con frame fijo
                HStack {
                    // Splash: icono desde plist si no se pasa imagen
                    let leftImageName: String? = {
                        if let imagen = imagen { return imagen }
                        if self == .tipo1 { return GV_HeaderConfigManager.shared.valueForKey("SplashLeftIconAssets") }
                        return nil
                    }()
                    if let imgName = leftImageName, GV_HeaderConfigManager.shared.assetExists(imgName) {
                        Image(imgName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(GV_Temas_Manager.shared.headerIcon)
                    } else {
                        Image(systemName: "questionmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(GV_Temas_Manager.shared.headerIcon)
                    }
                }
                .frame(width: 50, alignment: .leading)
                
                // Texto perfectamente centrado
                Text(caption)
                    .font(.headline)
                    .foregroundColor(GV_Temas_Manager.shared.headerText)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                
                // Lado derecho - Menú con frame fijo para balancear el centrado
                HStack {
                    menuType.menuView(
                        showThemes: showThemes,
                        showAdminDatos: showAdminDatos,
                        showAdvancedSearch: showAdvancedSearch,
                        showMySettings: showMySettings,
                        onExit: {},
                        onGoToPortada: {},
                        onGoBack: {},
                        onGoToEstablecimientos: {},
                        onGoToFavoritos: {},
                        onGoToMapa: {}
                    )
                }
                .frame(width: 50, alignment: .trailing)
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
        _ menuType: GV_MenuType = .ninguno,
        onNavigateToEstablecimientos: (() -> Void)? = nil,
        onNavigateToFavoritos: (() -> Void)? = nil,
        onNavigateToMapa: (() -> Void)? = nil
    ) -> some View {
        GV_HeaderWithMenuWrapper(
            headerType: self,
            caption: caption,
            imagen: imagen,
            menuType: menuType,
            onNavigateToEstablecimientos: onNavigateToEstablecimientos,
            onNavigateToFavoritos: onNavigateToFavoritos,
            onNavigateToMapa: onNavigateToMapa
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
    let onNavigateToEstablecimientos: (() -> Void)?
    let onNavigateToFavoritos: (() -> Void)?
    let onNavigateToMapa: (() -> Void)?
    
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showThemes = false
    @State private var showAdminDatos = false
    @State private var showAdvancedSearch = false
    @State private var showMySettings = false
    
    var body: some View {
        let config = GV_HeaderConfig(
            height: headerType.headerConfig.height,
            backgroundColor: themeManager.headerBackground,
            caption: headerType.headerConfig.caption,
            horizontalPadding: headerType.headerConfig.horizontalPadding,
            verticalPadding: headerType.headerConfig.verticalPadding
        )
        
        VStack(spacing: 0) {
            HStack {
                // Lado izquierdo - Imagen (desde parámetro o plist para splash) o espacio fijo
                HStack {
                    let leftImageName: String? = {
                        if let imagen = imagen { return imagen }
                        if headerType == .tipo1 { return GV_HeaderConfigManager.shared.valueForKey("SplashLeftIconAssets") }
                        return nil
                    }()
                    if let imgName = leftImageName {
                        Image(imgName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(GV_Temas_Manager.shared.headerIcon)
                    } else {
                        Color.clear
                            .frame(width: 30, height: 30)
                    }
                }
                .frame(width: 50, alignment: .leading)
                
                // Texto perfectamente centrado
                Text(caption)
                    .font(.headline)
                    .foregroundColor(GV_Temas_Manager.shared.headerText)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                
                // Lado derecho - Menú con frame fijo para balancear el centrado
                HStack {
                    menuType.menuView(
                        showThemes: $showThemes,
                        showAdminDatos: $showAdminDatos,
                        showAdvancedSearch: $showAdvancedSearch,
                        showMySettings: $showMySettings,
                        onExit: {
                            dismiss()
                        },
                        onGoToPortada: {
                            // Navegar a la portada (menú principal)
                            dismiss()
                        },
                        onGoBack: {
                            // Regresar a la vista anterior
                            dismiss()
                        },
                        onGoToEstablecimientos: {
                            // Navegar a lista de establecimientos
                            onNavigateToEstablecimientos?()
                        },
                        onGoToFavoritos: {
                            // Navegar a favoritos
                            onNavigateToFavoritos?()
                        },
                        onGoToMapa: {
                            // Navegar a mapa
                            onNavigateToMapa?()
                        }
                    )
                }
                .frame(width: 50, alignment: .trailing)
            }
            .padding(.horizontal, config.horizontalPadding)
            .padding(.vertical, config.verticalPadding)
        }
        .frame(height: config.height)
        .background(config.backgroundColor)
        .sheet(isPresented: $showThemes) {
            GV_Temas_SelectorView()
        }
        .sheet(isPresented: $showAdminDatos) {
            GV_SCR_vg_EstablecimientosListaView()
        }
        .sheet(isPresented: $showAdvancedSearch) {
            GV_SCR_vg_FavoritosView()
        }
        .sheet(isPresented: $showMySettings) {
            Text("Mis Configuraciones")
                .padding()
        }
    }
}
