//
//  HeaderManager.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Gestor singleton para manejar configuraciones de encabezados
//

import SwiftUI

/// Gestor singleton para configuraciones de encabezados
class HeaderManager {
    static let shared = HeaderManager()
    
    private let configuration = HeaderConfiguration()
    
    private init() {}
    
    /// Obtiene el estilo para un tipo de encabezado
    func getStyle(for type: HeaderType) -> HeaderStyle {
        return configuration.getStyle(for: type)
    }
    
    /// Calcula el tamaño de fuente adaptativo
    func adaptiveFontSize(for type: HeaderType, availableWidth: CGFloat, text: String) -> CGFloat {
        return configuration.adaptiveFontSize(for: type, availableWidth: availableWidth, text: text)
    }
    
    /// Verifica si necesita ajuste automático
    func needsAutoAdjustment(for type: HeaderType, availableWidth: CGFloat, text: String) -> Bool {
        return configuration.needsAutoAdjustment(for: type, availableWidth: availableWidth, text: text)
    }
    
    /// Obtiene todas las configuraciones (para debugging)
    func getAllStyles() -> [HeaderType: HeaderStyle] {
        return [
            .main: configuration.getStyle(for: .main),
            .section: configuration.getStyle(for: .section)
        ]
    }
}
