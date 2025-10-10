//
//  GV_Temas_SelectorView.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Vista para seleccionar temas - Se adapta al tema actual
//

import SwiftUI

struct GV_Temas_SelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var themeManager = GV_Temas_Manager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: themeManager.spacing) {
                    // Header con información
                    VStack(spacing: 8) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 50))
                            .foregroundColor(themeManager.primary)
                        
                        Text("Selecciona tu Tema")
                            .font(themeManager.title)
                            .foregroundColor(themeManager.textPrimary)
                        
                        Text("Cambia la apariencia de toda la aplicación")
                            .font(themeManager.caption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .padding(themeManager.paddingMedium)
                    
                    Divider()
                        .background(themeManager.separator)
                        .padding(.vertical, 10)
                    
                    // Cards de temas
                    ForEach(GV_Temas_Type.allCases) { tema in
                        ThemeCardView(
                            tema: tema,
                            isSelected: themeManager.currentTheme == tema
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                themeManager.changeTheme(to: tema)
                            }
                            
                            // Cerrar después de 0.5 segundos
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                dismiss()
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Info de configuración
                    VStack(spacing: 8) {
                        Text(GV_Temas_ConfigLoader.currentSourceInfo())
                            .font(themeManager.footnote)
                            .foregroundColor(themeManager.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(themeManager.paddingMedium)
                }
                .padding(themeManager.paddingMedium)
            }
            .background(themeManager.background)
            .navigationTitle("Temas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primary)
                }
            }
        }
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
    }
}

// MARK: - Card de Tema Individual

struct ThemeCardView: View {
    @ObservedObject var themeManager = GV_Temas_Manager.shared
    let tema: GV_Temas_Type
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header del card
            HStack {
                Image(systemName: tema.icon)
                    .font(.system(size: 28))
                    .foregroundColor(tema.temasConfig.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tema.displayName)
                        .font(themeManager.headline)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Text(tema.description)
                        .font(themeManager.caption)
                        .foregroundColor(themeManager.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Checkmark si está seleccionado
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(themeManager.success)
                }
            }
            
            // Preview de colores del tema
            HStack(spacing: 12) {
                Text("Preview:")
                    .font(themeManager.caption)
                    .foregroundColor(themeManager.textSecondary)
                
                // Color Primario
                VStack(spacing: 4) {
                    Circle()
                        .fill(tema.temasConfig.primary)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(themeManager.border, lineWidth: 2)
                        )
                    
                    Text("Primario")
                        .font(.system(size: 9))
                        .foregroundColor(themeManager.textSecondary)
                }
                
                // Color Secundario
                VStack(spacing: 4) {
                    Circle()
                        .fill(tema.temasConfig.secondary)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(themeManager.border, lineWidth: 2)
                        )
                    
                    Text("Secundario")
                        .font(.system(size: 9))
                        .foregroundColor(themeManager.textSecondary)
                }
                
                // Color Acento
                VStack(spacing: 4) {
                    Circle()
                        .fill(tema.temasConfig.accent)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(themeManager.border, lineWidth: 2)
                        )
                    
                    Text("Acento")
                        .font(.system(size: 9))
                        .foregroundColor(themeManager.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(themeManager.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                .fill(themeManager.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                        .stroke(
                            isSelected ? themeManager.primary : themeManager.border,
                            lineWidth: isSelected ? 3 : themeManager.borderWidth
                        )
                )
        )
        .shadow(
            color: isSelected ? themeManager.primary.opacity(0.3) : themeManager.shadow,
            radius: isSelected ? themeManager.shadowRadius * 1.5 : themeManager.shadowRadius
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    GV_Temas_SelectorView()
}


