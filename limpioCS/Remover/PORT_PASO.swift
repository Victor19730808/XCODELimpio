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
//  • iOS 17+
//
//  Fecha: 2025-10-04
//

import SwiftUI

struct PORT_PASO: View {
    @EnvironmentObject private var location: LocationService
    @State private var scrollOffset: CGFloat = 0
    @State private var cardAnimations: [Bool] = Array(repeating: false, count: 3)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con gradiente
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header con imagen y título con parallax
                        VStack(spacing: 15) {
                            Image("Portada")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .offset(y: scrollOffset * 0.5) // Efecto parallax
                                .scaleEffect(1 + scrollOffset * 0.0001) // Efecto de zoom sutil
                            
                            VStack(spacing: 8) {
                                Text("Sistema de Gestión de Establecimientos")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .offset(y: scrollOffset * 0.2) // Parallax en el subtítulo
                            }
                        }
                        .padding(.top, 20)
                        
                        // Cards de funcionalidades con animaciones
                        VStack(spacing: 20) {
                            // Sección Explorar
                            MenuCard(
                                title: "Explorar Base de Datos",
                                icon: "magnifyingglass.circle.fill",
                                color: .blue,
                                items: [
                                    MenuItem(title: "Lista Unificada", subtitle: "Filtros y búsqueda", destination: AnyView(ccp_BDF_EstablecimientosListaView())),
                                    MenuItem(title: "Favoritos", subtitle: "Establecimientos guardados", destination: AnyView(ccp_BDF_FavoritosView()))
                                ]
                            )
                            .offset(x: cardAnimations[0] ? 0 : -50)
                            .opacity(cardAnimations[0] ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.1), value: cardAnimations[0])
                            
                            // Sección Administración
                            MenuCard(
                                title: "Administración",
                                icon: "gear.circle.fill",
                                color: .orange,
                                items: [
                                    MenuItem(title: "Prueba DB Incremental", subtitle: "Gestión de datos", destination: AnyView(ccp_BDF_DBIncrementalTestView())),
                                    MenuItem(title: "Promociones", subtitle: "Gestión de ofertas", destination: AnyView(ccp_BDF_PromocionesView()))
                                ]
                            )
                            .offset(x: cardAnimations[1] ? 0 : 50)
                            .opacity(cardAnimations[1] ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: cardAnimations[1])
                            
                            // Sección Mapas
                            MenuCard(
                                title: "Visualización",
                                icon: "map.circle.fill",
                                color: .green,
                                items: [
                                    MenuItem(title: "Mapa Principal", subtitle: "Vista general", destination: AnyView(ccp_BDF_MapView())),
                                    MenuItem(title: "Mapa con Clusters", subtitle: "Vista agrupada", destination: AnyView(ccp_BDF_MapClustersView()))
                                ]
                            )
                            .offset(x: cardAnimations[2] ? 0 : -50)
                            .opacity(cardAnimations[2] ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.5), value: cardAnimations[2])
                        }
                        .padding(.horizontal, 20)
                        
                        // Footer con información de ubicación
                        if !location.estado.isEmpty && !location.municipio.isEmpty {
                            VStack(spacing: 8) {
                                Text("📍 Ubicación Actual")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(location.municipio), \(location.estado)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 50)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { index in
                    NavigationLink(destination: items[index].destination) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(items[index].title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(items[index].subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .scaleEffect(isHovered ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isHovered)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(isHovered ? 0.1 : 0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: shadowRadius, x: 0, y: 4)
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
