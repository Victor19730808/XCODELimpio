//
//  ThemeViewModifier.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Modificadores de vista para aplicar temas fácilmente
//

import SwiftUI

/// Modificador para aplicar el tema actual a cualquier vista
struct ThemedView: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.backgroundColor)
            .foregroundColor(themeManager.textColor)
    }
}

/// Modificador para tarjetas con tema
struct ThemedCard: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.currentTheme.colors.cardBackground)
            .foregroundColor(themeManager.currentTheme.colors.textPrimary)
            .cornerRadius(12)
            .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
    }
}

/// Modificador para botones con tema
struct ThemedButton: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
    }
    
    func body(content: Content) -> some View {
        content
            .font(themeManager.currentTheme.fonts.button)
            .padding(.horizontal, themeManager.currentTheme.spacing.md)
            .padding(.vertical, themeManager.currentTheme.spacing.sm)
            .background(buttonBackground)
            .foregroundColor(buttonForeground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(buttonBorder, lineWidth: style == .outline ? 1 : 0)
            )
    }
    
    private var buttonBackground: Color {
        switch style {
        case .primary:
            return themeManager.currentTheme.colors.primary
        case .secondary:
            return themeManager.currentTheme.colors.secondary
        case .outline:
            return themeManager.currentTheme.colors.cardBackground
        }
    }
    
    private var buttonForeground: Color {
        switch style {
        case .primary, .secondary:
            return themeManager.currentTheme.colors.textOnPrimary
        case .outline:
            return themeManager.currentTheme.colors.primary
        }
    }
    
    private var buttonBorder: Color {
        return themeManager.currentTheme.colors.primary
    }
}

// MARK: - Extensiones para uso fácil
extension View {
    /// Aplica el tema actual a la vista
    func themed() -> some View {
        self.modifier(ThemedView())
    }
    
    /// Aplica el estilo de tarjeta con tema
    func themedCard() -> some View {
        self.modifier(ThemedCard())
    }
    
    /// Aplica el estilo de botón con tema
    func themedButton(_ style: ThemedButton.ButtonStyle = .primary) -> some View {
        self.modifier(ThemedButton(style: style))
    }
}
