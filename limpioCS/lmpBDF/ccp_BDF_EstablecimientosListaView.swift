import SwiftUI
import SwiftData

struct ccp_BDF_EstablecimientosListaView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    @Query(sort: \lmpBDF_EstablecimientoLocal.nombre, order: .forward)
    private var all: [lmpBDF_EstablecimientoLocal]
    
    // Computed properties
    private var data: [lmpBDF_EstablecimientoLocal] {
        let baseData = showFavoritesOnly ? all.filter { $0.esFavorito } : all
        
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
        ZStack {
            // Fondo con gradiente sutil usando el tema actual
            LinearGradient(
                gradient: Gradient(colors: [
                    themeManager.currentTheme.colors.surface,
                    themeManager.currentTheme.colors.background
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header rojo estilo El Buen Fin
                VStack(spacing: 0) {
                    HStack {
                        // Botón regresar al menú principal
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "house.fill")
                                    .font(.title2)
                                    .foregroundColor(themeManager.currentTheme.colors.textOnPrimary)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(themeManager.currentTheme.colors.textOnPrimary.opacity(0.2))
                                            .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                    )
                            }
                            .padding(.leading, 20)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Título "Participantes" centrado
                        HeaderView.themed(
                            text: "Participantes",
                            type: .section,
                            themeManager: themeManager
                        )
                        
                        // Menú hamburguesa
                        HStack {
                            Spacer()
                            
                            HamburgerMenuView.themed(
                                viewType: .list,
                                menuActions: [
                                    .themes: { 
                                        // Temas - implementar según necesidad
                                    },
                                    .adminDatos: { 
                                        // Admin Datos - implementar según necesidad
                                    },
                                    .mySettings: { 
                                        // Mis Configuraciones - implementar según necesidad
                                    }
                                ],
                                themeManager: themeManager
                            )
                            .padding(.trailing, 20)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // Línea divisoria
                    Rectangle()
                        .fill(themeManager.currentTheme.colors.textOnPrimary.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                }
                .frame(height: 100)
                .background(themeManager.currentTheme.colors.primary)
                
                // Contenido principal
                VStack(spacing: 0) {
                    // Barra de búsqueda y controles
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            // Barra de búsqueda
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                                
                                TextField("Buscar por nombre o categoría...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                                
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.currentTheme.colors.cardBackground)
                                    .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                            )
                            
                            // Toggle de favoritos
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showFavoritesOnly.toggle()
                                }
                            } label: {
                                Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(showFavoritesOnly ? .yellow : themeManager.currentTheme.colors.textSecondary)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(themeManager.currentTheme.colors.cardBackground)
                                            .shadow(color: themeManager.currentTheme.colors.shadow, radius: 4, x: 0, y: 2)
                                    )
                            }
                        }
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .background(themeManager.currentTheme.colors.background)
                    
                    // Lista de participantes
                    Group {
                        if data.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                
                                Image(systemName: searchText.isEmpty ? 
                                    (showFavoritesOnly ? "star" : "building.2") :
                                    "magnifyingglass")
                                    .font(.system(size: 60))
                                    .foregroundStyle(themeManager.currentTheme.colors.textSecondary.opacity(0.3))
                                
                                VStack(spacing: 8) {
                                    Text(searchText.isEmpty ? 
                                        (showFavoritesOnly ? "Aún no tienes favoritos" : "Sin registros") :
                                        "Sin resultados")
                                        .font(themeManager.currentTheme.fonts.title)
                                        .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                                    
                                    Text(searchText.isEmpty ? 
                                        (showFavoritesOnly ? "Marca participantes con la estrella para verlos aquí." : "Aún no hay participantes en la base local.") :
                                        "Intenta con otros términos de búsqueda.")
                                        .font(themeManager.currentTheme.fonts.body)
                                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(data) { est in
                                        ccp_UI_EstablecimientoRow(est: est)
                                            .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.vertical, 16)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Componentes de UI

#Preview {
    NavigationStack {
        ccp_BDF_EstablecimientosListaView()
    }
}
