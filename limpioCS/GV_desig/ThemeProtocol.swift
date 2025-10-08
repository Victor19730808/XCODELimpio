//
//  ThemeProtocol.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Protocolo base para todos los temas de la aplicación
//

import SwiftUI

/// Protocolo base que define la estructura de un tema
protocol ThemeProtocol {
    var name: String { get }
    var colors: ColorTheme { get }
    var fonts: FontTheme { get }
    var spacing: SpacingTheme { get }
}

/// Definición de colores para cada tema
struct ColorTheme {
    // Colores principales
    let primary: Color
    let secondary: Color
    let accent: Color
    
    // Colores de fondo
    let background: Color
    let surface: Color
    let cardBackground: Color
    
    // Colores de texto
    let textPrimary: Color
    let textSecondary: Color
    let textOnPrimary: Color
    
    // Colores de estado
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
    
    // Colores de UI
    let border: Color
    let divider: Color
    let shadow: Color
}

/// Definición de tipografías
struct FontTheme {
    let title: Font
    let headline: Font
    let subheadline: Font
    let body: Font
    let caption: Font
    let footnote: Font
    let button: Font
}

/// Definición de espaciados
struct SpacingTheme {
    let xs: CGFloat    // 4
    let sm: CGFloat    // 8
    let md: CGFloat    // 16
    let lg: CGFloat    // 24
    let xl: CGFloat    // 32
    let xxl: CGFloat   // 48
}
