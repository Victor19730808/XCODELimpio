 //
//  ThemeManager.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Gestor principal de temas de la aplicación
//

import SwiftUI
import Combine

/// Tipos de tema disponibles
enum ThemeType: String, CaseIterable {
    case claro = "Claro"
    case oscuro = "Oscuro"
    case buenFin = "BuenFin"
    
    var displayName: String {
        switch self {
        case .claro:
            return "Modo Claro"
        case .oscuro:
            return "Modo Oscuro"
        case .buenFin:
            return "BuenFin"
        }
    }
}

/// Gestor singleton de temas
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: ThemeProtocol = ClaroTheme()
    @Published var currentThemeType: ThemeType = .claro // Default - Modo Claro
    
    private init() {
        loadSavedTheme()
    }
    
    /// Cambia el tema actual
    func setTheme(_ themeType: ThemeType) {
        currentThemeType = themeType
        
        switch themeType {
        case .claro:
            currentTheme = ClaroTheme()
        case .oscuro:
            currentTheme = OscuroTheme()
        case .buenFin:
            currentTheme = BuenFinTheme()
        }
        
        saveTheme()
    }
    
    /// Guarda el tema actual en UserDefaults
    private func saveTheme() {
        UserDefaults.standard.set(currentThemeType.rawValue, forKey: "selectedTheme")
    }
    
    /// Carga el tema guardado desde UserDefaults
    private func loadSavedTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let themeType = ThemeType(rawValue: savedTheme) {
            setTheme(themeType)
        }
    }
    
    /// Obtiene el color primario del tema actual
    var primaryColor: Color {
        return currentTheme.colors.primary
    }
    
    /// Obtiene el color de fondo del tema actual
    var backgroundColor: Color {
        return currentTheme.colors.background
    }
    
    /// Obtiene el color de texto primario del tema actual
    var textColor: Color {
        return currentTheme.colors.textPrimary
    }
}
