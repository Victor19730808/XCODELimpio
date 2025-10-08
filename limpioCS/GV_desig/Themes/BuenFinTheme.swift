//
//  BuenFinTheme.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Tema BuenFin basado en las imágenes proporcionadas
//

import SwiftUI

struct BuenFinTheme: ThemeProtocol {
    let name = "BuenFin"
    
    let colors = ColorTheme(
        // Colores principales - Rojo vibrante del BuenFin
        primary: Color(red: 0.9, green: 0.2, blue: 0.2),      // Rojo vibrante #E53935
        secondary: Color(red: 0.8, green: 0.1, blue: 0.1),     // Rojo más oscuro
        accent: Color(red: 1.0, green: 0.4, blue: 0.1),        // Naranja vibrante
        
        // Colores de fondo
        background: Color.white,                                // Fondo blanco predominante
        surface: Color(red: 0.98, green: 0.98, blue: 0.98),   // Gris muy claro para secciones informativas
        cardBackground: Color.white,                            // Tarjetas blancas
        
        // Colores de texto
        textPrimary: Color(red: 0.1, green: 0.1, blue: 0.1),   // Negro para texto principal
        textSecondary: Color(red: 0.3, green: 0.3, blue: 0.3), // Gris oscuro para texto secundario
        textOnPrimary: Color.white,                             // Blanco sobre fondos rojos
        
        // Colores de estado - Manteniendo el rojo como base
        success: Color(red: 0.2, green: 0.7, blue: 0.3),
        warning: Color(red: 0.9, green: 0.6, blue: 0.1),
        error: Color(red: 0.9, green: 0.2, blue: 0.2),         // Mismo rojo del tema
        info: Color(red: 0.9, green: 0.2, blue: 0.2),          // Mismo rojo del tema
        
        // Colores de UI
        border: Color(red: 0.9, green: 0.2, blue: 0.2),        // Bordes rojos
        divider: Color(red: 0.85, green: 0.85, blue: 0.85),    // Divisores grises claros
        shadow: Color(red: 0.9, green: 0.2, blue: 0.2).opacity(0.2) // Sombra roja sutil
    )
    
    let fonts = FontTheme(
        title: .system(size: 32, weight: .bold, design: .default),     // Más grande para impacto
        headline: .system(size: 24, weight: .bold, design: .default),  // Negrita para encabezados
        subheadline: .system(size: 18, weight: .semibold, design: .default),
        body: .system(size: 16, weight: .regular, design: .default),
        caption: .system(size: 14, weight: .regular, design: .default),
        footnote: .system(size: 12, weight: .regular, design: .default),
        button: .system(size: 16, weight: .bold, design: .default)     // Negrita para botones
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

// MARK: - Extensiones específicas para el tema BuenFin
extension BuenFinTheme {
    /// Color rojo específico del BuenFin
    var buenFinRed: Color {
        return Color(red: 0.9, green: 0.2, blue: 0.2)
    }
    
    /// Color para botones del BuenFin (blanco con borde rojo)
    var buenFinButtonBackground: Color {
        return Color.white
    }
    
    /// Color para texto de botones del BuenFin
    var buenFinButtonText: Color {
        return Color(red: 0.9, green: 0.2, blue: 0.2)
    }
    
    /// Color para fondos de sección informativa
    var infoSectionBackground: Color {
        return Color(red: 0.98, green: 0.98, blue: 0.98)
    }
}
