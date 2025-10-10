//
//  GV_Temas_Config.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Configuración de temas por tipo
//

import SwiftUI

/// Estructura que define la configuración completa de un tema
struct GV_Temas_Config {
    // MARK: - Colores Principales
    let primary: Color
    let secondary: Color
    let accent: Color
    
    // MARK: - Fondos
    let background: Color
    let surface: Color
    let cardBackground: Color
    
    // MARK: - Textos
    let textPrimary: Color
    let textSecondary: Color
    let textOnPrimary: Color
    let textOnSecondary: Color
    
    // MARK: - Colores de Header
    let headerBackground: Color
    let headerText: Color
    let headerIcon: Color
    
    // MARK: - Otros Colores
    let border: Color
    let shadow: Color
    
    // MARK: - Colores del Sistema (Adaptativos)
    let systemBackground: Color
    let systemGroupedBackground: Color
    let label: Color
    let secondaryLabel: Color
    
    // MARK: - Estados de Feedback
    let error: Color
    let warning: Color
    let success: Color
    let info: Color
    
    // MARK: - Colores de Cards
    let cardPrimary: Color      // Para "Participantes" - Azul
    let cardSecondary: Color    // Para "Mis Favoritos" - Rojo
    let cardSuccess: Color      // Para "Cerca de Mi" - Verde
    let cardWarning: Color      // Para "Todo México" - Naranja
    
    // MARK: - UI States
    let separator: Color
    let disabled: Color
    
    // MARK: - Fuentes
    let largeTitle: Font
    let title: Font
    let headline: Font
    let body: Font
    let subheadline: Font
    let callout: Font
    let caption: Font
    let footnote: Font
    
    // MARK: - Efectos
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let borderWidth: CGFloat
    let opacity: Double
    
    // MARK: - Espaciados
    let paddingMedium: CGFloat
    let spacing: CGFloat
}

/// Clase singleton para gestionar y proporcionar configuraciones de temas
class GV_Temas_ConfigManager {
    static let shared = GV_Temas_ConfigManager()
    
    private init() {}
    
    /// Devuelve la configuración de tema para un tipo específico
    /// Usa el GV_Temas_ConfigLoader para decidir si carga desde Swift o Plist
    func getTemasConfig(for type: GV_Temas_Type) -> GV_Temas_Config {
        return GV_Temas_ConfigLoader.shared.loadTemasConfig(for: type)
    }
    
    /// Devuelve la configuración de tema desde código Swift (hardcoded)
    func getTemasConfigFromSwift(for type: GV_Temas_Type) -> GV_Temas_Config {
        switch type {
        case .modoClaro:
            return GV_Temas_Config(
                // Colores Principales
                primary: .blue,
                secondary: .gray,
                accent: .orange,
                
                // Fondos
                background: .white,
                surface: Color.gray.opacity(0.05),
                cardBackground: .white,
                
                // Textos
                textPrimary: .black,
                textSecondary: .gray,
                textOnPrimary: .white,
                textOnSecondary: .white,
                
                // Colores de Header
                headerBackground: .blue,
                headerText: .white,
                headerIcon: .white,
                
                // Otros Colores
                border: Color.gray.opacity(0.2),
                shadow: Color.black.opacity(0.1),
                
                // Colores del Sistema
                systemBackground: Color(uiColor: .systemBackground),
                systemGroupedBackground: Color(uiColor: .systemGroupedBackground),
                label: Color(uiColor: .label),
                secondaryLabel: Color(uiColor: .secondaryLabel),
                
                // Estados de Feedback
                error: .red,
                warning: .yellow,
                success: .green,
                info: .blue,
                
                // Colores de Cards
                cardPrimary: .blue,      // Participantes - Azul
                cardSecondary: .red,     // Mis Favoritos - Rojo
                cardSuccess: .green,     // Cerca de Mi - Verde
                cardWarning: .orange,    // Todo México - Naranja
                
                // UI States
                separator: Color.gray.opacity(0.3),
                disabled: Color.gray.opacity(0.5),
                
                // Fuentes
                largeTitle: .largeTitle,
                title: .title,
                headline: .headline,
                body: .body,
                subheadline: .subheadline,
                callout: .callout,
                caption: .caption,
                footnote: .footnote,
                
                // Efectos
                cornerRadius: 12,
                shadowRadius: 8,
                borderWidth: 1,
                opacity: 0.8,
                
                // Espaciados
                paddingMedium: 16,
                spacing: 12
            )
            
        case .modoOscuro:
            return GV_Temas_Config(
                // Colores Principales
                primary: Color(red: 0.4, green: 0.6, blue: 1.0),
                secondary: Color.gray,
                accent: Color.orange,
                
                // Fondos
                background: Color(white: 0.1),
                surface: Color(white: 0.15),
                cardBackground: Color(white: 0.2),
                
                // Textos
                textPrimary: .white,
                textSecondary: Color.gray.opacity(0.8),
                textOnPrimary: .white,
                textOnSecondary: .black,
                
                // Colores de Header
                headerBackground: Color(red: 0.4, green: 0.6, blue: 1.0),
                headerText: .white,
                headerIcon: .white,
                
                // Otros Colores
                border: Color.white.opacity(0.2),
                shadow: Color.black.opacity(0.3),
                
                // Colores del Sistema
                systemBackground: Color(uiColor: .systemBackground),
                systemGroupedBackground: Color(uiColor: .systemGroupedBackground),
                label: Color(uiColor: .label),
                secondaryLabel: Color(uiColor: .secondaryLabel),
                
                // Estados de Feedback
                error: Color(red: 1.0, green: 0.3, blue: 0.3),
                warning: Color.yellow,
                success: Color.green,
                info: Color(red: 0.4, green: 0.6, blue: 1.0),
                
                // Colores de Cards
                cardPrimary: Color(red: 0.4, green: 0.6, blue: 1.0),    // Participantes - Azul claro
                cardSecondary: Color(red: 1.0, green: 0.3, blue: 0.3),  // Mis Favoritos - Rojo claro
                cardSuccess: Color(red: 0.3, green: 0.8, blue: 0.3),    // Cerca de Mi - Verde claro
                cardWarning: Color(red: 1.0, green: 0.6, blue: 0.2),    // Todo México - Naranja claro
                
                // UI States
                separator: Color.white.opacity(0.2),
                disabled: Color.gray.opacity(0.4),
                
                // Fuentes
                largeTitle: .largeTitle,
                title: .title,
                headline: .headline,
                body: .body,
                subheadline: .subheadline,
                callout: .callout,
                caption: .caption,
                footnote: .footnote,
                
                // Efectos
                cornerRadius: 12,
                shadowRadius: 8,
                borderWidth: 1,
                opacity: 0.9,
                
                // Espaciados
                paddingMedium: 16,
                spacing: 12
            )
            
        case .buenFin:
            return GV_Temas_Config(
                // Colores Principales (Rojo Buen Fin)
                primary: Color(red: 0.9, green: 0.1, blue: 0.2),
                secondary: Color(white: 0.95),
                accent: Color(red: 0.7, green: 0.1, blue: 0.15),
                
                // Fondos (Blanco/Gris)
                background: .white,
                surface: Color.gray.opacity(0.05),
                cardBackground: Color(white: 0.98),
                
                // Textos
                textPrimary: Color(white: 0.2),
                textSecondary: Color.gray,
                textOnPrimary: .white,
                textOnSecondary: Color(white: 0.2),
                
                // Colores de Header
                headerBackground: Color(red: 0.9, green: 0.1, blue: 0.2),
                headerText: .white,
                headerIcon: .white,
                
                // Otros Colores
                border: Color.gray.opacity(0.3),
                shadow: Color.black.opacity(0.15),
                
                // Colores del Sistema
                systemBackground: Color(uiColor: .systemBackground),
                systemGroupedBackground: Color(uiColor: .systemGroupedBackground),
                label: Color(uiColor: .label),
                secondaryLabel: Color(uiColor: .secondaryLabel),
                
                // Estados de Feedback
                error: Color(red: 0.9, green: 0.1, blue: 0.2),
                warning: Color.yellow,
                success: Color.green,
                info: .blue,
                
                // Colores de Cards (Buen Fin - Tonos rojos y complementarios)
                cardPrimary: Color(red: 0.9, green: 0.1, blue: 0.2),     // Participantes - Rojo Buen Fin
                cardSecondary: Color(red: 0.7, green: 0.1, blue: 0.15),  // Mis Favoritos - Rojo oscuro
                cardSuccess: Color(red: 0.1, green: 0.6, blue: 0.1),     // Cerca de Mi - Verde
                cardWarning: Color(red: 0.9, green: 0.5, blue: 0.1),     // Todo México - Naranja
                
                // UI States
                separator: Color.gray.opacity(0.3),
                disabled: Color.gray.opacity(0.5),
                
                // Fuentes (Redondeadas para Buen Fin)
                largeTitle: .system(.largeTitle, design: .rounded),
                title: .system(.title, design: .rounded),
                headline: .system(.headline, design: .rounded),
                body: .system(.body, design: .rounded),
                subheadline: .system(.subheadline, design: .rounded),
                callout: .system(.callout, design: .rounded),
                caption: .system(.caption, design: .rounded),
                footnote: .system(.footnote, design: .rounded),
                
                // Efectos
                cornerRadius: 8,
                shadowRadius: 6,
                borderWidth: 2,
                opacity: 0.85,
                
                // Espaciados
                paddingMedium: 16,
                spacing: 12
            )
        }
    }
}

/// Extensión para GV_Temas_Type con acceso a configuración
extension GV_Temas_Type {
    /// Obtiene la configuración de tema para este tipo
    var temasConfig: GV_Temas_Config {
        return GV_Temas_ConfigManager.shared.getTemasConfig(for: self)
    }
}

