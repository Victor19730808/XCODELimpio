//
//  GV_SCR_tc_contentview.swift
//  limpioCS
//
//  Migrado: 2025-01-10
//  Sistema: GV (Temas + Headers + Menús + ScreenTypes)
//

import SwiftUI

struct GV_SCR_tc_contentview: View {
    // MARK: - Configuración del Sistema GV
    private let screenType: ScreenType = .content
    private let myHeader: GV_HeaderType = .tipo2
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    // MARK: - Dependencias
    @EnvironmentObject private var location: LocationService
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con menú - TODO EN UNA SOLA LÍNEA! 🎯
            myHeader.headerViewWithMenu("Portada", nil, .principal)
            
            // Contenido principal con tema aplicado
            NavigationStack {
                ScrollView {
                    LazyVStack(spacing: themeManager.spacing) {
                        // MARK: - Web Services
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Web Services")
                                .font(themeManager.headline)
                                .foregroundColor(themeManager.textPrimary)
                                .padding(.horizontal, themeManager.paddingMedium)
                        }
                        
                        Divider()
                            .background(themeManager.separator)
                            .padding(.vertical, 10)
                        
                        // MARK: - Base de Datos
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Base de Datos")
                                .font(themeManager.headline)
                                .foregroundColor(themeManager.textPrimary)
                                .padding(.horizontal, themeManager.paddingMedium)
                            
                            // COMENTADO - Vista de testing eliminada para producción
                            // NavigationLink {
                            //     ccp_BDF_DBIncrementalTestView()
                            // } label: {
                            //     Label("Prueba DB Incremental", systemImage: "externaldrive.connected.to.line.below")
                            //         .font(themeManager.body)
                            //         .foregroundColor(themeManager.textPrimary)
                            //         .frame(maxWidth: .infinity, alignment: .leading)
                            //         .padding(themeManager.paddingMedium)
                            //         .background(themeManager.cardBackground)
                            //         .cornerRadius(themeManager.cornerRadius)
                            //         .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius)
                            // }
                            // .padding(.horizontal, themeManager.paddingMedium)
                        }
                        
                        Divider()
                            .background(themeManager.separator)
                            .padding(.vertical, 10)
                        
                        // MARK: - Mapas
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mapa")
                                .font(themeManager.headline)
                                .foregroundColor(themeManager.textPrimary)
                                .padding(.horizontal, themeManager.paddingMedium)
                            
                            VStack(spacing: 8) {
                                NavigationLink {
                                    GV_GreatMap(isTodoMexico: false)
                                } label: {
                                    Label("Mapa de Establecimientos", systemImage: "map.fill")
                                        .font(themeManager.body)
                                        .foregroundColor(themeManager.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(themeManager.paddingMedium)
                                        .background(themeManager.cardBackground)
                                        .cornerRadius(themeManager.cornerRadius)
                                        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius)
                                }
                                .padding(.horizontal, themeManager.paddingMedium)
                                
                                NavigationLink {
                                    GV_GreatMap(isTodoMexico: true)
                                } label: {
                                    Label("Mapa Todo México", systemImage: "square.stack.3d.up.fill")
                                        .font(themeManager.body)
                                        .foregroundColor(themeManager.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(themeManager.paddingMedium)
                                        .background(themeManager.cardBackground)
                                        .cornerRadius(themeManager.cornerRadius)
                                        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius)
                                }
                            }
                            .padding(.horizontal, themeManager.paddingMedium)
                        }
                        
                        Divider()
                            .background(themeManager.separator)
                            .padding(.vertical, 10)
                        
                        // MARK: - Promociones
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Promociones")
                                .font(themeManager.headline)
                                .foregroundColor(themeManager.textPrimary)
                                .padding(.horizontal, themeManager.paddingMedium)
                            
                            NavigationLink {
                                GV_SRC_vg_EstablecimientoPromociones(establecimientoId: 123) // ID de ejemplo
                            } label: {
                                Label("Promociones (GV)", systemImage: "tag.fill")
                                    .font(themeManager.body)
                                    .foregroundColor(themeManager.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(themeManager.paddingMedium)
                                    .background(themeManager.cardBackground)
                                    .cornerRadius(themeManager.cornerRadius)
                                    .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius)
                            }
                            .padding(.horizontal, themeManager.paddingMedium)
                        }
                        
                        
                    }
                    .padding(.top, themeManager.paddingMedium)
                }
            }
        }
        .background(themeManager.background)
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
        .onAppear {
            // Inicia ubicación al entrar a la portada (útil para mapas, etc.)
            location.start()
        }
    }
}

#Preview {
    GV_SCR_tc_contentview()
        .environmentObject(LocationService())
}

