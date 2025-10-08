//
//  ThemeSelectorView.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Vista para seleccionar el tema de la aplicación
//

import SwiftUI

struct ThemeSelectorView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: themeManager.currentTheme.spacing.lg) {
                // Header
                VStack(spacing: themeManager.currentTheme.spacing.md) {
                    Text("Seleccionar Tema")
                        .font(themeManager.currentTheme.fonts.title)
                        .foregroundColor(themeManager.currentTheme.colors.textPrimary)
                    
                    Text("Elige el tema que mejor se adapte a ti")
                        .font(themeManager.currentTheme.fonts.body)
                        .foregroundColor(themeManager.currentTheme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, themeManager.currentTheme.spacing.lg)
                
                // Opciones de tema
                VStack(spacing: themeManager.currentTheme.spacing.md) {
                    ForEach(ThemeType.allCases, id: \.self) { themeType in
                        ThemeOptionView(
                            themeType: themeType,
                            isSelected: themeManager.currentThemeType == themeType,
                            onTap: {
                                themeManager.setTheme(themeType)
                            }
                        )
                    }
                }
                .padding(.horizontal, themeManager.currentTheme.spacing.lg)
                
                Spacer()
            }
            .themed()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Listo") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(themeManager.currentTheme.colors.primary)
            )
        }
    }
}

struct ThemeOptionView: View {
    let themeType: ThemeType
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: themeManager.currentTheme.spacing.md) {
                // Icono del tema
                themeIcon
                    .frame(width: 50, height: 50)
                    .background(themeColors.primary)
                    .cornerRadius(25)
                
                // Información del tema
                VStack(alignment: .leading, spacing: 4) {
                    Text(themeType.displayName)
                        .font(themeManager.currentTheme.fonts.headline)
                        .foregroundColor(themeManager.currentTheme.colors.textPrimary)
                    
                    Text(themeDescription)
                        .font(themeManager.currentTheme.fonts.caption)
                        .foregroundColor(themeManager.currentTheme.colors.textSecondary)
                }
                
                Spacer()
                
                // Indicador de selección
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.colors.primary)
                        .font(.title2)
                }
            }
            .padding(themeManager.currentTheme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? themeManager.currentTheme.colors.primary : themeManager.currentTheme.colors.border,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var themeIcon: some View {
        Group {
            switch themeType {
            case .claro:
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.white)
            case .oscuro:
                Image(systemName: "moon.fill")
                    .foregroundColor(.white)
            case .buenFin:
                Image(systemName: "heart.fill")
                    .foregroundColor(.white)
            }
        }
    }
    
    private var themeColors: ColorTheme {
        switch themeType {
        case .claro:
            return ClaroTheme().colors
        case .oscuro:
            return OscuroTheme().colors
        case .buenFin:
            return BuenFinTheme().colors
        }
    }
    
    private var themeDescription: String {
        switch themeType {
        case .claro:
            return "Modo claro con colores suaves"
        case .oscuro:
            return "Modo oscuro para uso nocturno"
        case .buenFin:
            return "Tema especial BuenFin con colores rojos"
        }
    }
}

#Preview {
    ThemeSelectorView()
}
