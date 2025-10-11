//
//  GV_Temas_Manager.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Gestor global de temas con soporte para override local
//

import SwiftUI
import Combine

/// Manager global de temas - Singleton ObservableObject
class GV_Temas_Manager: ObservableObject {
    static let shared = GV_Temas_Manager()
    
    /// Tema actual activo (global)
    @Published var currentTheme: GV_Temas_Type {
        didSet {
            saveThemePreference()
        }
    }
    
    /// Key para UserDefaults
    private let themeKey = "GV_SelectedTheme"
    
    private init() {
        // Cargar tema guardado o usar Modo Claro por defecto
        if let savedTheme = UserDefaults.standard.value(forKey: themeKey) as? Int,
           let theme = GV_Temas_Type(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .modoClaro  // Default
        }
    }
    
    /// Guarda la preferencia de tema en UserDefaults
    private func saveThemePreference() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
    }
    
    /// Cambia el tema actual
    /// - Parameter theme: Nuevo tema a aplicar
    func changeTheme(to theme: GV_Temas_Type) {
        currentTheme = theme
    }
    
    /// Obtiene la configuración del tema actual
    var config: GV_Temas_Config {
        return currentTheme.temasConfig
    }
    
    /// Información del tema actual
    func currentThemeInfo() -> String {
        return """
        🎨 TEMA ACTUAL
        ══════════════
        Nombre: \(currentTheme.displayName)
        Fuente: \(GV_Temas_ConfigLoader.currentSourceInfo())
        ══════════════
        """
    }
}

/// Extensión para facilitar el acceso a propiedades del tema
extension GV_Temas_Manager {
    // MARK: - Accesos rápidos a colores
    var primary: Color { config.primary }
    var secondary: Color { config.secondary }
    var accent: Color { config.accent }
    var background: Color { config.background }
    var surface: Color { config.surface }
    var cardBackground: Color { config.cardBackground }
    var textPrimary: Color { config.textPrimary }
    var textSecondary: Color { config.textSecondary }
    var textOnPrimary: Color { config.textOnPrimary }
    var textOnSecondary: Color { config.textOnSecondary }
    var border: Color { config.border }
    var shadow: Color { config.shadow }
    
    // MARK: - Colores de Subheaders
    var subheaderBackground: Color { config.subheaderBackground }
    var subheaderText: Color { config.subheaderText }
    
    // MARK: - URLs de Configuración
    var imagenPromocionDefault: String { config.imagenPromocionDefault }
    
    // MARK: - Colores de Header
    var headerBackground: Color { config.headerBackground }
    var headerText: Color { config.headerText }
    var headerIcon: Color { config.headerIcon }
    
    // MARK: - Colores del Sistema
    var systemBackground: Color { config.systemBackground }
    var systemGroupedBackground: Color { config.systemGroupedBackground }
    var label: Color { config.label }
    var secondaryLabel: Color { config.secondaryLabel }
    
    // MARK: - Estados
    var error: Color { config.error }
    var warning: Color { config.warning }
    var success: Color { config.success }
    var info: Color { config.info }
    var separator: Color { config.separator }
    var disabled: Color { config.disabled }
    
    // MARK: - Colores de Cards
    var cardPrimary: Color { config.cardPrimary }
    var cardSecondary: Color { config.cardSecondary }
    var cardSuccess: Color { config.cardSuccess }
    var cardWarning: Color { config.cardWarning }
    
    // MARK: - Fuentes
    var largeTitle: Font { config.largeTitle }
    var title: Font { config.title }
    var headline: Font { config.headline }
    var body: Font { config.body }
    var subheadline: Font { config.subheadline }
    var callout: Font { config.callout }
    var caption: Font { config.caption }
    var footnote: Font { config.footnote }
    
    // MARK: - Efectos
    var cornerRadius: CGFloat { config.cornerRadius }
    var shadowRadius: CGFloat { config.shadowRadius }
    var borderWidth: CGFloat { config.borderWidth }
    var opacity: Double { config.opacity }
    
    // MARK: - Espaciados
    var paddingMedium: CGFloat { config.paddingMedium }
    var spacing: CGFloat { config.spacing }
}

/// ViewModifier para aplicar tema a cualquier vista
struct GV_ThemedModifier: ViewModifier {
    @ObservedObject var themeManager: GV_Temas_Manager
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.background)
            .foregroundColor(themeManager.textPrimary)
            .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
    }
}

/// Extensión para aplicar tema fácilmente
extension View {
    /// Aplica el tema global a la vista
    func themed() -> some View {
        modifier(GV_ThemedModifier(themeManager: GV_Temas_Manager.shared))
    }
    
    /// Aplica un tema específico (override local)
    func themed(_ theme: GV_Temas_Type) -> some View {
        let config = theme.temasConfig
        return self
            .background(config.background)
            .foregroundColor(config.textPrimary)
            .preferredColorScheme(theme.preferredColorScheme)
    }
}

