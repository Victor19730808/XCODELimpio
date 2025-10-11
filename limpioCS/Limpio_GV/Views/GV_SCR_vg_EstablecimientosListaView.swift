//
//  GV_SCR_vg_EstablecimientosListaView.swift
//  limpioCS
//
//  Migrado: 2025-01-10
//  Sistema: GV (Temas + Headers + Menús + ScreenTypes)
//

import SwiftUI
import SwiftData

struct GV_SCR_vg_EstablecimientosListaView: View {
    // MARK: - Configuración del Sistema GV
    private let screenType: ScreenType = .general
    private let myHeader: GV_HeaderType = .tipo2
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    // MARK: - Estados
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    @Query(sort: \lmpBDF_EstablecimientoLocal.nombre, order: .forward)
    private var all: [lmpBDF_EstablecimientoLocal]
    
    // MARK: - Managers
    @ObservedObject private var favoritosManager = GV_FavoritosManager.shared
    
    // Computed properties
    private var data: [lmpBDF_EstablecimientoLocal] {
        let baseData = showFavoritesOnly ? all.filter { favoritosManager.isFavorite(establecimientoId: $0.id) } : all
        
        if searchText.isEmpty {
            return baseData
        } else {
            return baseData.filter { est in
                // Búsqueda principal: nombre O categoría (OR)
                let nombreMatch = est.nombre.localizedCaseInsensitiveContains(searchText)
                let categoriaMatch = est.categoria?.localizedCaseInsensitiveContains(searchText) == true
                
                // Búsqueda secundaria: municipio O estado (opcional)
                let municipioMatch = est.municipio?.localizedCaseInsensitiveContains(searchText) == true
                let estadoMatch = est.estado?.localizedCaseInsensitiveContains(searchText) == true
                
                // Prioridad: nombre O categoría, luego municipio O estado
                return nombreMatch || categoriaMatch || municipioMatch || estadoMatch
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header con menú - TODO EN UNA SOLA LÍNEA! 🎯
            myHeader.headerViewWithMenu("Participantes", nil, .principal)
            
            // Contenido principal con tema aplicado
            VStack(spacing: 0) {
                // Barra de búsqueda y controles
                VStack(spacing: themeManager.spacing) {
                    HStack(spacing: 12) {
                        // Barra de búsqueda
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(themeManager.textSecondary)
                            
                            TextField("Buscar por nombre o categoría...", text: $searchText)
                                .textFieldStyle(.plain)
                                .foregroundColor(themeManager.textPrimary)
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(themeManager.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                                .fill(themeManager.cardBackground)
                                .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 2)
                        )
                        
                        // Toggle de favoritos
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showFavoritesOnly.toggle()
                            }
                        } label: {
                            Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                                .font(themeManager.title)
                                .foregroundColor(showFavoritesOnly ? themeManager.warning : themeManager.textSecondary)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(themeManager.cardBackground)
                                        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 2)
                                )
                        }
                    }
                }
                .padding(.horizontal, themeManager.paddingMedium)
                .padding(.top, themeManager.paddingMedium)
                .padding(.bottom, themeManager.spacing)
                .background(themeManager.background)
                
                // Lista de participantes
                Group {
                    if data.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: searchText.isEmpty ? 
                                (showFavoritesOnly ? "star" : "building.2") :
                                "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(themeManager.textSecondary.opacity(0.3))
                            
                            VStack(spacing: 8) {
                                Text(searchText.isEmpty ? 
                                    (showFavoritesOnly ? "Aún no tienes favoritos" : "Sin registros") :
                                    "Sin resultados")
                                    .font(themeManager.title)
                                    .foregroundColor(themeManager.textPrimary)
                                
                                Text(searchText.isEmpty ? 
                                    (showFavoritesOnly ? "Marca participantes con la estrella para verlos aquí." : "Aún no hay participantes en la base local.") :
                                    "Intenta con otros términos de búsqueda.")
                                    .font(themeManager.body)
                                    .foregroundColor(themeManager.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: themeManager.spacing) {
                                ForEach(data) { est in
                                    ccp_UI_EstablecimientoRow(est: est)
                                        .padding(.horizontal, themeManager.paddingMedium)
                                }
                            }
                            .padding(.vertical, themeManager.spacing)
                        }
                    }
                }
            }
        }
        .background(themeManager.background)
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        GV_SCR_vg_EstablecimientosListaView()
    }
}
