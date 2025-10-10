//
//  GV_HeaderType.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Enumeración de tipos de headers independientes
//

import SwiftUI

/// Enumeración de tipos de headers independientes
enum GV_HeaderType: Int, CaseIterable, Identifiable {
    case tipo1 = 1    // Header simple sin menú
    case tipo2 = 2    // Header con menú hamburguesa
    case tipo3 = 3    // Header con caption personalizado
    case tipo4 = 4    // Header minimalista
    case tipo5 = 5    // Header con sombra
    
    var id: Int { self.rawValue }
    
    /// Nombre descriptivo del tipo de header
    var displayName: String {
        switch self {
        case .tipo1: return "Header Simple"
        case .tipo2: return "Header con Menú"
        case .tipo3: return "Header Personalizado"
        case .tipo4: return "Header Minimalista"
        case .tipo5: return "Header con Sombra"
        }
    }
    
    /// Descripción del tipo de header
    var description: String {
        switch self {
        case .tipo1: return "Header básico sin menú hamburguesa"
        case .tipo2: return "Header con menú hamburguesa incluido"
        case .tipo3: return "Header con caption personalizable"
        case .tipo4: return "Header minimalista con diseño simple"
        case .tipo5: return "Header con efectos de sombra"
        }
    }
}
