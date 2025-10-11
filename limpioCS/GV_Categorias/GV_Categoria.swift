//
//  GV_Categoria.swift
//  limpioCS
//
//  Sistema de categorías basado en Plist
//  Creado: 2025-01-11
//

import SwiftUI

/// Modelo de categoría que mapea directamente del Plist y del API
struct GV_Categoria: Codable, Identifiable, Hashable {
    let categoria_id: Int
    let categoria_nombre: String
    let categoria_taxonomia: String
    let categoria_tags: String
    let evento_id: Int
    
    // Propiedades visuales (solo en Plist local)
    let colorHex: String
    let icono: String
    
    // MARK: - Identifiable
    var id: Int { categoria_id }
    
    // MARK: - Computed Properties
    
    /// Color de SwiftUI parseado desde hex
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
    
    /// Color con opacidad para fondos
    var colorOpaco: Color {
        color.opacity(0.1)
    }
    
    /// Color para texto sobre el fondo de la categoría
    var colorTexto: Color {
        // Si el color es muy oscuro, usar blanco; si es claro, usar el color original
        return color
    }
    
    /// Tags como array
    var tagsArray: [String] {
        categoria_tags
            .split(separator: " ")
            .map { String($0) }
    }
    
    // MARK: - Búsqueda y filtrado
    
    /// Verifica si la categoría coincide con un término de búsqueda
    func matches(searchTerm: String) -> Bool {
        guard !searchTerm.isEmpty else { return true }
        
        let term = searchTerm.lowercased()
        return categoria_nombre.lowercased().contains(term) ||
               categoria_taxonomia.lowercased().contains(term) ||
               categoria_tags.lowercased().contains(term)
    }
    
    /// Vista del icono como SF Symbol
    @ViewBuilder
    func iconoView(size: CGFloat = 24) -> some View {
        Image(systemName: icono)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

// MARK: - Color Extension para Hex

extension Color {
    /// Inicializa un Color desde un string hexadecimal
    /// - Parameter hex: String en formato "#RRGGBB" o "RRGGBB"
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    /// Convierte el Color a String hex
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else {
            return nil
        }
        
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

