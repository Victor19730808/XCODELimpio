//
//  OscuroTheme.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Tema oscuro de la aplicación
//

import SwiftUI

struct OscuroTheme: ThemeProtocol {
    let name = "Oscuro"
    
    let colors = ColorTheme(
        // Colores principales
        primary: Color(red: 0.3, green: 0.5, blue: 0.9),      // Azul más claro para contraste
        secondary: Color(red: 0.2, green: 0.7, blue: 0.4),     // Verde más brillante
        accent: Color(red: 1.0, green: 0.5, blue: 0.3),        // Naranja más brillante
        
        // Colores de fondo
        background: Color(red: 0.05, green: 0.05, blue: 0.05), // Negro profundo
        surface: Color(red: 0.1, green: 0.1, blue: 0.1),       // Gris muy oscuro
        cardBackground: Color(red: 0.15, green: 0.15, blue: 0.15), // Gris oscuro
        
        // Colores de texto
        textPrimary: Color.white,
        textSecondary: Color(red: 0.7, green: 0.7, blue: 0.7), // Gris claro
        textOnPrimary: Color.black,
        
        // Colores de estado
        success: Color(red: 0.3, green: 0.8, blue: 0.4),
        warning: Color(red: 1.0, green: 0.7, blue: 0.2),
        error: Color(red: 0.9, green: 0.3, blue: 0.3),
        info: Color(red: 0.2, green: 0.6, blue: 0.9),
        
        // Colores de UI
        border: Color(red: 0.3, green: 0.3, blue: 0.3),
        divider: Color(red: 0.2, green: 0.2, blue: 0.2),
        shadow: Color.black.opacity(0.3)
    )
    
    let fonts = FontTheme(
        title: .system(size: 28, weight: .bold, design: .default),
        headline: .system(size: 22, weight: .semibold, design: .default),
        subheadline: .system(size: 18, weight: .medium, design: .default),
        body: .system(size: 16, weight: .regular, design: .default),
        caption: .system(size: 14, weight: .regular, design: .default),
        footnote: .system(size: 12, weight: .regular, design: .default),
        button: .system(size: 16, weight: .semibold, design: .default)
    )
    
    let spacing = SpacingTheme(
        xs: 4,
        sm: 8,
        md: 16,
        lg: 24,
        xl: 32,
        xxl: 48
    )
}
