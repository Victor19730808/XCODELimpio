//
//  PORT_PASO.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Descripción:
//  ----------------------------------------------------------------
//  • Portada mínima para pruebas del módulo BDF.
//  • Acceso a:
//      - Lista unificada (Todos / Favoritos)
//      - Mapa base (ccp_BDF_MapView)
//      - Mapa con clusters (ccp_BDF_MapClustersView)
//  • Migrado al sistema de temas dinámico
//  • iOS 17+
//
//  Fecha: 2025-10-04
//  Migrado: 2025-01-10
//

import SwiftUI

struct PORT_PASO: View {
    @EnvironmentObject private var location: LocationService
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var scrollOffset: CGFloat = 0
    @State private var cardAnimations: [Bool] = Array(repeating: false, count: 4)
    @State private var showAdminDatos = false // Estado para mostrar la vista de administración
    @State private var showThemeSelector = false // Estado para mostrar el selector de temas
    
    var body: some View {
        NavigationStack {
                ZStack {
                    // Fondo con gradiente usando el tema actual
                    LinearGradient(
                        gradient: Gradient(colors: [
                            themeManager.currentTheme.colors.surface,
                            themeManager.currentTheme.colors.background,
                            themeManager.currentTheme.colors.background
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    // Fondo sólido para asegurar contraste
                    themeManager.backgroundColor
                        .ignoresSafeArea()
                        .opacity(0.95)
                
                VStack(spacing: 0) {
                    // Header rojo con menú hamburguesa
                    VStack(spacing: 0) {
                        HStack {
                            // Espacio para balance visual
                            Color.clear
                                .frame(width: 30, height: 30)
                            
                            Spacer()
                            
                            // Etiqueta "Hecho en México" centrada
                            HeaderView.themed(
                                text: "Hecho en México",
                                type: .main,
                                themeManager: themeManager
                            )
                            
                            Spacer()
                            
                            // Menú hamburguesa centralizado
                            HamburgerMenuView.themed(
                                viewType: .main,
                                menuActions: [
                                    .themes: { showThemeSelector = true },
                                    .adminDatos: { showAdminDatos = true },
                                    .advancedSearch: { 
                                        // Búsquedas Avanzadas - implementar según necesidad
                                    },
                                    .mySettings: { 
                                        // Mis Configuraciones - implementar según necesidad
                                    }
                                ],
                                themeManager: themeManager
                            )
                            .padding(.trailing, 16)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        
                        // Línea divisoria
                        Rectangle()
                            .fill(themeManager.currentTheme.colors.textOnPrimary.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                    }
                    .frame(height: 120)
                    .background(themeManager.currentTheme.colors.primary) // Color primario del tema actual
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            // Espaciado superior
                            Spacer()
                                .frame(height: 20)
                        
                        // Cards principales para usuarios
                        VStack(spacing: 20) {
                            // Participantes - Lista Unificada
                            MenuCard(
                                title: "Participantes",
                                icon: "building.2.fill",
                                color: .blue,
                                items: [
                                    MenuItem(title: "Lista de Establecimientos", subtitle: "Todos los participantes", destination: AnyView(ccp_BDF_EstablecimientosListaView()))
                                ]
                            )
                            .offset(x: cardAnimations[0] ? 0 : -50)
                            .opacity(cardAnimations[0] ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.1), value: cardAnimations[0])
                            
                            // Mis Favoritos
                            MenuCard(
                                title: "Mis Favoritos",
                                icon: "heart.fill",
                                color: .red,
                                items: [
                                    MenuItem(title: "Favoritos", subtitle: "Mis participantes guardados", destination: AnyView(ccp_BDF_FavoritosView()))
                                ]
                            )
                            .offset(x: cardAnimations[1] ? 0 : 50)
                            .opacity(cardAnimations[1] ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: cardAnimations[1])
                            
                            // Cerca de Mi
                            MenuCard(
                                title: "Cerca de Mi",
                                icon: "location.fill",
                                color: .green,
                                items: [
                                    MenuItem(title: "Mapa de Cercanías", subtitle: "Participantes cercanos", destination: AnyView(ccp_BDF_MapView()))
                                ]
                            )
                            .offset(x: cardAnimations[2] ? 0 : -50)
                            .opacity(cardAnimations[2] ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.5), value: cardAnimations[2])
                            
                            // Todo México
                            MenuCard(
                                title: "Todo México",
                                icon: "map.fill",
                                color: .orange,
                                items: [
                                    MenuItem(title: "Mapa de la República", subtitle: "Vista de todo el país", destination: AnyView(ccp_BDF_MapClustersView()))
                                ]
                            )
                            .offset(x: cardAnimations[3] ? 0 : 50)
                            .opacity(cardAnimations[3] ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.7), value: cardAnimations[3])
                        }
                        .padding(.horizontal, 20)
                        
                        
                            Spacer(minLength: 50)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Iniciar animaciones de las cards con delay
            for i in 0..<cardAnimations.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        cardAnimations[i] = true
                    }
                }
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
        .coordinateSpace(name: "scroll")
        .sheet(isPresented: $showAdminDatos) {
            ccp_BDF_DBIncrementalTestView()
                .environmentObject(location)
        }
        .sheet(isPresented: $showThemeSelector) {
            ThemeSelectorView()
        }
    }
}

// MARK: - Componentes de UI

struct MenuCard: View {
    let title: String
    let icon: String
    let color: Color
    let items: [MenuItem]
    @State private var isHovered = false
    @State private var cardScale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 8
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
                
                HeaderView.sectionThemed(
                    text: title,
                    themeManager: themeManager
                )
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { index in
                    NavigationLink(destination: items[index].destination) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(items[index].title)
                                    .font(themeManager.currentTheme.fonts.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.currentTheme.colors.textPrimary)
                                
                                Text(items[index].subtitle)
                                    .font(themeManager.currentTheme.fonts.caption)
                                    .foregroundColor(themeManager.currentTheme.colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.colors.textSecondary)
                                .scaleEffect(isHovered ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isHovered)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(themeManager.currentTheme.colors.surface.opacity(isHovered ? 0.3 : 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
            .padding(20)
            .background(themeManager.currentTheme.colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: themeManager.currentTheme.colors.shadow, radius: shadowRadius, x: 0, y: 4)
        .scaleEffect(cardScale)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
                cardScale = hovering ? 1.02 : 1.0
                shadowRadius = hovering ? 12 : 8
            }
        }
    }
}

struct MenuItem {
    let title: String
    let subtitle: String
    let destination: AnyView
}

// MARK: - Componentes de Animación

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    PORT_PASO()
}
