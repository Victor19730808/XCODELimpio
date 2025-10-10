//
//  GV_SCR_tp_3.swift
//  limpioCS
//
//  Created by Victor on 08/10/25.
//

import SwiftUI

struct GV_SCR_tp_3: View {
    // Configuración como variables let
    private let screenType: ScreenType = .splash
    private let myHeader: GV_HeaderType = .tipo2
    @ObservedObject private var themeManager = GV_Temas_Manager.shared  // ✨ MANAGER PARA CAMBIOS DINÁMICOS
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con menú - TODO EN UNA SOLA LÍNEA! 🎯
            myHeader.headerViewWithMenu("Mi Header", "BF", .principal)
            
                // Contenido principal con tema aplicado
                VStack(spacing: themeManager.spacing) {
                    Text("Contenido de la vista")
                        .font(themeManager.title)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Divider()
                        .background(themeManager.separator)
                        .padding(.vertical, 10)
                    
                    // Card de ejemplo con tema
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Card con Tema Aplicado")
                            .font(themeManager.headline)
                            .foregroundColor(themeManager.textPrimary)
                        
                        Text("Tema: \(themeManager.currentTheme.displayName)")
                            .font(themeManager.body)
                            .foregroundColor(themeManager.textSecondary)
                        
                        HStack {
                            Button("Primario") {}
                                .padding()
                                .background(themeManager.primary)
                                .foregroundColor(themeManager.textOnPrimary)
                                .cornerRadius(themeManager.cornerRadius)
                            
                            Button("Acento") {}
                                .padding()
                                .background(themeManager.accent)
                                .foregroundColor(themeManager.textOnPrimary)
                                .cornerRadius(themeManager.cornerRadius)
                        }
                    }
                    .padding(themeManager.paddingMedium)
                    .background(themeManager.cardBackground)
                    .cornerRadius(themeManager.cornerRadius)
                    .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius)
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .background(themeManager.separator)
                        .padding(.vertical, 10)
                    
                    // Información del sistema de pantalla
                    Text(screenType.showAllFormattedAuto(filePath: #file))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(themeManager.textSecondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .background(themeManager.background)
            .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
    }
}
#Preview {
    GV_SCR_tp_3()
}
