//
//  GV_SCR_tc_menuprincipal.swift
//  limpioCS
//
//  Migrado: 2025-01-10
//  Sistema: GV (Temas + Headers + Menús + ScreenTypes)
//

import SwiftUI

struct GV_SCR_tc_menuprincipal: View {
    // MARK: - Configuración del Sistema GV
    private let screenType: ScreenType = .content
    private let myHeader: GV_HeaderType = .tipo2
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    // MARK: - Dependencias
    @EnvironmentObject private var location: LocationService
    
    // MARK: - Estados de Animación
    @State private var scrollOffset: CGFloat = 0
    @State private var cardAnimations: [Bool] = Array(repeating: false, count: 4)  // 3 cards principales + 1 testing
    @State private var bannerAnimation: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
            // Header con menú - TODO EN UNA SOLA LÍNEA! 🎯
            myHeader.headerViewWithMenu("Hecho en México", nil, .principal)
            
            // Contenido principal con tema aplicado
            ScrollView {
                VStack(spacing: themeManager.spacing * 2.5) {
                    // Espaciado superior
                    Spacer()
                        .frame(height: 20)
                
                    // Cards principales para usuarios
                    VStack(spacing: 20) {
                        // Participantes - Lista Unificada
                        GV_MenuCard(
                            title: "Participantes",
                            icon: "building.2.fill",
                            color: themeManager.cardPrimary,
                            items: [
                                GV_MenuItem(title: "Lista de Establecimientos", subtitle: "Todos los participantes", destination: AnyView(GV_SCR_vg_EstablecimientosListaView()))
                            ]
                        )
                        .offset(x: cardAnimations[0] ? 0 : -50)
                        .opacity(cardAnimations[0] ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.1), value: cardAnimations[0])
                        
                        // Mis Favoritos
                        GV_MenuCard(
                            title: "Mis Favoritos",
                            icon: "heart.fill",
                            color: themeManager.cardSecondary,
                            items: [
                                GV_MenuItem(title: "Favoritos", subtitle: "Mis participantes guardados", destination: AnyView(GV_SCR_vg_FavoritosView()))
                            ]
                        )
                        .offset(x: cardAnimations[1] ? 0 : 50)
                        .opacity(cardAnimations[1] ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: cardAnimations[1])
                        
                        // Mapa (Unificado - Cercanías + Todo México)
                        GV_MenuCard(
                            title: "Mapa",
                            icon: "map.fill",
                            color: themeManager.cardSuccess,
                            items: [
                                GV_MenuItem(title: "Mapa de Establecimientos", subtitle: "Cerca de ti y todo México", destination: AnyView(GV_GreatMap(isTodoMexico: false)))
                            ]
                        )
                        .offset(x: cardAnimations[2] ? 0 : -50)
                        .opacity(cardAnimations[2] ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.5), value: cardAnimations[2])
                        
                        // Banner de Patrocinadores (reemplaza "Todo México")
                        GV_Banner_Manager.shared.showGVBanner()
                            .offset(y: bannerAnimation ? 0 : 50)
                            .opacity(bannerAnimation ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.7), value: bannerAnimation)
                        
                        // 🧪 Testing - Solo para desarrollo
                        #if DEBUG
                        GV_MenuCard(
                            title: "🧪 Testing",
                            icon: "testtube.2",
                            color: .orange,
                            items: [
                                // COMENTADO - Vistas de testing eliminadas para producción
                                // GV_MenuItem(title: "🛠️ Admin Sistema", subtitle: "Administración completa del sistema GV_ep_Establecimientos", destination: AnyView(GV_VistaSimple_Test())),
                                // GV_MenuItem(title: "Test Sistema Categorías", subtitle: "Vista de prueba del sistema de categorías", destination: AnyView(GV_TestCategoriasView())),
                                // GV_MenuItem(title: "Test Ubicación", subtitle: "Diagnóstico de problemas de ubicación", destination: AnyView(GV_TestLocationView()))
                                GV_MenuItem(title: "⚙️ Configuración", subtitle: "Opciones generales de la app", destination: AnyView(Text("Configuración próximamente")))
                            ]
                        )
                        .offset(x: cardAnimations[3] ? 0 : 50)
                        .opacity(cardAnimations[3] ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.9), value: cardAnimations[3])
                        #endif
                        
                    }
                    .padding(.horizontal, themeManager.paddingMedium)
                    
                    Spacer(minLength: 50)
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: GV_ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                }
            )
            .onPreferenceChange(GV_ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .coordinateSpace(name: "scroll")
        }
        .background(themeManager.background)
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
        .onAppear {
            // Iniciar el servicio de ubicación
            print("🚀 [MENU] Iniciando LocationService desde menú principal")
            location.start()
            
            // Iniciar animaciones de las cards con delay
            for i in 0..<cardAnimations.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        cardAnimations[i] = true
                    }
                }
            }
            
            // Animar banner después de las cards
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeOut(duration: 0.6)) {
                    bannerAnimation = true
                }
            }
        }
        }
    }
}

// MARK: - Componentes de UI Temados

struct GV_MenuCard: View {
    let title: String
    let icon: String
    let color: Color
    let items: [GV_MenuItem]
    @State private var isHovered = false
    @State private var cardScale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 8
    
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(themeManager.title)
                    .foregroundColor(color)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
                
                Text(title)
                    .font(themeManager.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { index in
                    NavigationLink(destination: items[index].destination) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(items[index].title)
                                    .font(themeManager.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.textPrimary)
                                
                                Text(items[index].subtitle)
                                    .font(themeManager.caption)
                                    .foregroundColor(themeManager.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(themeManager.caption)
                                .foregroundColor(themeManager.textSecondary)
                                .scaleEffect(isHovered ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isHovered)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(themeManager.surface.opacity(isHovered ? 0.3 : 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadius))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(themeManager.paddingMedium)
        .background(themeManager.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadius))
        .shadow(color: themeManager.shadow, radius: shadowRadius, x: 0, y: 4)
        .scaleEffect(cardScale)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
                cardScale = hovering ? 1.02 : 1.0
                shadowRadius = hovering ? themeManager.shadowRadius * 1.5 : themeManager.shadowRadius
            }
        }
    }
}

struct GV_MenuItem {
    let title: String
    let subtitle: String
    let destination: AnyView
}

// MARK: - Componentes de Animación

struct GV_ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    GV_SCR_tc_menuprincipal()
        .environmentObject(LocationService())
}
