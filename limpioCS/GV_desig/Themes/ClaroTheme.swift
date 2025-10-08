//
//  ClaroTheme.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Tema Modo Claro de la aplicación
//

import SwiftUI

struct ClaroTheme: ThemeProtocol {
    let name = "Modo Claro"
    
    let colors = ColorTheme(
        // Colores principales
        primary: Color(red: 0.2, green: 0.3, blue: 0.8),      // Azul suave
        secondary: Color(red: 0.1, green: 0.6, blue: 0.3),     // Verde
        accent: Color(red: 0.9, green: 0.4, blue: 0.2),        // Naranja
        
        // Colores de fondo
        background: Color.white,
        surface: Color(red: 0.98, green: 0.98, blue: 0.98),   // Gris muy claro
        cardBackground: Color.white,
        
        // Colores de texto
        textPrimary: Color(red: 0.1, green: 0.1, blue: 0.1),   // Negro suave
        textSecondary: Color(red: 0.4, green: 0.4, blue: 0.4), // Gris medio
        textOnPrimary: Color.white,
        
        // Colores de estado
        success: Color(red: 0.2, green: 0.7, blue: 0.3),
        warning: Color(red: 0.9, green: 0.6, blue: 0.1),
        error: Color(red: 0.8, green: 0.2, blue: 0.2),
        info: Color(red: 0.1, green: 0.5, blue: 0.8),
        
        // Colores de UI
        border: Color(red: 0.9, green: 0.9, blue: 0.9),
        divider: Color(red: 0.85, green: 0.85, blue: 0.85),
        shadow: Color.black.opacity(0.1)
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
