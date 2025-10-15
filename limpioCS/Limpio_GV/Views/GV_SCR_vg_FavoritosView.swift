//
//  GV_SCR_vg_FavoritosView.swift
//  limpioCS
//
//  Migrado: 2025-01-10
//  Sistema: GV (Temas + Headers + Menús + ScreenTypes)
//

import SwiftUI
import SwiftData

struct GV_SCR_vg_FavoritosView: View {
    // MARK: - Configuración del Sistema GV
    private let screenType: ScreenType = .general
    private let myHeader: GV_HeaderType = .tipo2
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Managers
    @ObservedObject private var favoritosManager = GV_FavoritosManager.shared
    
    // Trae todos los establecimientos (filtrará por favoritos en computed property)
    @Query(
        sort: \GV_modeloCont_Establecimientos.establecimiento_nombre,
        order: .forward
    )
    private var todosEstablecimientos: [GV_modeloCont_Establecimientos]
    
    // Computed property para obtener solo los favoritos
    private var favoritos: [GV_modeloCont_Establecimientos] {
        return todosEstablecimientos.filter { establecimiento in
            favoritosManager.isFavorite(establecimientoId: establecimiento.establecimiento_id)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header con menú - TODO EN UNA SOLA LÍNEA! 🎯
            myHeader.headerViewWithMenu("Mis Favoritos", nil, .principal)
            
            // Contenido principal con tema aplicado
            VStack(spacing: 0) {
                if favoritos.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "star")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.textSecondary.opacity(0.3))
                        
                        VStack(spacing: 8) {
                            Text("Aún no tienes favoritos")
                                .font(themeManager.title)
                                .foregroundColor(themeManager.textPrimary)
                            
                            Text("Marca establecimientos con la estrella para verlos aquí.")
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
                            ForEach(favoritos) { est in
                                // Vista simple temporal hasta reconstruir el componente
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(est.establecimiento_nombre)
                                        .font(themeManager.body)
                                        .fontWeight(.bold)
                                    
                                    if let estado = est.direccion_estado {
                                        Text(estado)
                                            .font(themeManager.caption)
                                            .foregroundColor(themeManager.textSecondary)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(themeManager.cardBackground)
                                .cornerRadius(themeManager.cornerRadius)
                                .padding(.horizontal, themeManager.paddingMedium)
                            }
                        }
                        .padding(.vertical, themeManager.spacing)
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
        GV_SCR_vg_FavoritosView()
    }
}
