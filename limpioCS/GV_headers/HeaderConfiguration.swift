//
//  HeaderConfiguration.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Configuración centralizada de estilos de encabezados
//

import SwiftUI

/// Tipos de encabezado disponibles
enum HeaderType: String, CaseIterable {
    case main = "main"           // Encabezados principales (ej: "Hecho en México", "Mapa de Cercanías")
    case section = "section"     // Encabezados de sección (ej: "Participantes", "Mis Favoritos")
    
    var displayName: String {
        switch self {
        case .main: return "Encabezados Principales"
        case .section: return "Encabezados de Sección"
        }
    }
}

/// Configuración de estilos para encabezados
struct HeaderStyle {
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let maxLines: Int
    let minScaleFactor: CGFloat
    let lineLimit: Int?
    let truncationMode: Text.TruncationMode
    
    static let main = HeaderStyle(
        fontSize: 22,
        fontWeight: .bold,
        maxLines: 2,
        minScaleFactor: 0.8,
        lineLimit: 2,
        truncationMode: .tail
    )
    
    static let section = HeaderStyle(
        fontSize: 18,
        fontWeight: .semibold,
        maxLines: 1,
        minScaleFactor: 0.85,
        lineLimit: 1,
        truncationMode: .tail
    )
}

/// Configuración centralizada de encabezados
class HeaderConfiguration {
    
    /// Estilos por tipo de encabezado
    private let styles: [HeaderType: HeaderStyle] = [
        .main: .main,
        .section: .section
    ]
    
    /// Obtiene el estilo para un tipo de encabezado
    func getStyle(for type: HeaderType) -> HeaderStyle {
        return styles[type] ?? .main
    }
    
    /// Calcula el tamaño de fuente adaptativo basado en el ancho disponible
    func adaptiveFontSize(for type: HeaderType, availableWidth: CGFloat, text: String) -> CGFloat {
        let baseStyle = getStyle(for: type)
        let baseFontSize = baseStyle.fontSize
        
        // Validar que el ancho disponible sea válido
        guard availableWidth > 0 else {
            return baseFontSize
        }
        
        // Calcular caracteres por línea estimados
        let estimatedCharsPerLine = max(1, Int(availableWidth / (baseFontSize * 0.6)))
        let totalChars = text.count
        let estimatedLines = max(1, (totalChars + estimatedCharsPerLine - 1) / estimatedCharsPerLine)
        
        // Si el texto necesita más líneas de las permitidas, reducir el tamaño
        if estimatedLines > baseStyle.maxLines {
            let scaleFactor = CGFloat(baseStyle.maxLines) / CGFloat(estimatedLines)
            let scaledFontSize = baseFontSize * scaleFactor
            return max(scaledFontSize, baseFontSize * baseStyle.minScaleFactor)
        }
        
        return baseFontSize
    }
    
    /// Verifica si el texto necesita ajuste automático
    func needsAutoAdjustment(for type: HeaderType, availableWidth: CGFloat, text: String) -> Bool {
        let baseStyle = getStyle(for: type)
        
        // Validar que el ancho disponible sea válido
        guard availableWidth > 0 else {
            return false
        }
        
        let estimatedCharsPerLine = max(1, Int(availableWidth / (baseStyle.fontSize * 0.6)))
        let totalChars = text.count
        let estimatedLines = max(1, (totalChars + estimatedCharsPerLine - 1) / estimatedCharsPerLine)
        
        return estimatedLines > baseStyle.maxLines
    }
}
