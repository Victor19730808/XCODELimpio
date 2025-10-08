//
//  HamburgerMenuView.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Componente reutilizable del menú hamburguesa
//

import SwiftUI

/// Componente reutilizable del menú hamburguesa
struct HamburgerMenuView: View {
    let viewType: ViewType
    let menuActions: [MenuOption: () -> Void]
    let iconColor: Color
    let backgroundColor: Color
    let shadowColor: Color
    
    private let menuManager = MenuManager.shared
    
    init(
        viewType: ViewType,
        menuActions: [MenuOption: () -> Void],
        iconColor: Color = .white,
        backgroundColor: Color = .white.opacity(0.15),
        shadowColor: Color = .black.opacity(0.1)
    ) {
        self.viewType = viewType
        self.menuActions = menuActions
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.shadowColor = shadowColor
    }
    
    var body: some View {
        Menu {
            ForEach(menuManager.getMenuOptions(for: viewType), id: \.rawValue) { option in
                if let action = menuActions[option] {
                    Button {
                        action()
                    } label: {
                        Label(option.displayName, systemImage: option.iconName)
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title2)
                .foregroundColor(iconColor)
                .padding(12)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
                )
        }
    }
}

/// Extensión para crear el menú con colores del tema
extension HamburgerMenuView {
    /// Crea un menú hamburguesa con colores del tema actual
    static func themed(
        viewType: ViewType,
        menuActions: [MenuOption: () -> Void],
        themeManager: ThemeManager
    ) -> HamburgerMenuView {
        return HamburgerMenuView(
            viewType: viewType,
            menuActions: menuActions,
            iconColor: themeManager.currentTheme.colors.textOnPrimary,
            backgroundColor: themeManager.currentTheme.colors.textOnPrimary.opacity(0.15),
            shadowColor: themeManager.currentTheme.colors.shadow
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        // Menú para vista principal
        HamburgerMenuView(
            viewType: .main,
            menuActions: [
                .themes: { print("Temas tapped") },
                .adminDatos: { print("Admin Datos tapped") },
                .advancedSearch: { print("Búsquedas Avanzadas tapped") },
                .mySettings: { print("Mis Configuraciones tapped") }
            ]
        )
        
        // Menú para mapas (sin Admin Datos)
        HamburgerMenuView(
            viewType: .map,
            menuActions: [
                .themes: { print("Temas tapped") },
                .advancedSearch: { print("Búsquedas Avanzadas tapped") },
                .mySettings: { print("Mis Configuraciones tapped") }
            ]
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
