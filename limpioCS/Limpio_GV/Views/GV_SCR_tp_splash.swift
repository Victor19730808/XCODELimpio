//
//  GV_SCR_tp_splash.swift
//  limpioCS
//
//  Migrado: 2025-01-10
//  Sistema: GV (Temas + Headers + Menús + ScreenTypes)
//

import SwiftUI

struct GV_SCR_tp_splash: View {
    // MARK: - Configuración del Sistema GV
    private let screenType: ScreenType = .splash
    private let myHeader: GV_HeaderType = .tipo1
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    // MARK: - Estados de Animación
    @State private var isAnimating = false
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    @State private var headerOpacity: Double = 0.0
    @State private var contentOpacity: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Fondo temado
            themeManager.background
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
            
            VStack(spacing: 0) {
                // Header con menú - TODO EN UNA SOLA LÍNEA! 🎯
                myHeader.headerViewWithMenu("Hecho en México", nil, .principal)
                    .opacity(headerOpacity)
                
                // Contenido principal con tema aplicado
                VStack(spacing: 0) {
                    // Fondo con gradiente temado
                    ZStack {
                        // Gradiente basado en el tema actual
                        LinearGradient(
                            gradient: Gradient(colors: [
                                themeManager.surface,
                                themeManager.background,
                                themeManager.background
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                        
                        VStack(spacing: 40) {
                            Spacer()
                            
                            // Composición elegante con las tres imágenes
                            VStack(spacing: 0) {
                                // Composición triangular de las imágenes
                                ZStack {
                                    // Círculo de fondo con pulso sutil temado
                                    Circle()
                                        .fill(themeManager.primary.opacity(0.08))
                                        .frame(width: 400, height: 400)
                                        .scaleEffect(pulseScale)
                                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseScale)
                                    
                                    // Composición de las tres imágenes
                                    VStack(spacing: 25) {
                                        // Imagen superior - CO
                                        Image("CO")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 140, height: 140)
                                            .shadow(color: themeManager.shadow, radius: 8, x: 0, y: 4)
                                            .scaleEffect(logoScale)
                                        
                                        // Imágenes inferiores - HM y BF lado a lado
                                        HStack(spacing: 35) {
                                            Image("HM")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 120, height: 120)
                                                .shadow(color: themeManager.shadow, radius: 8, x: 0, y: 4)
                                                .scaleEffect(logoScale)
                                            
                                            Image("BF")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 120, height: 120)
                                                .shadow(color: themeManager.shadow, radius: 8, x: 0, y: 4)
                                                .scaleEffect(logoScale)
                                        }
                                    }
                                }
                                .opacity(logoOpacity)
                            }
                            
                            Spacer()
                            
                            // Footer con mensaje poderoso temado
                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Text("IMPULSANDO EL CRECIMIENTO")
                                        .font(themeManager.headline)
                                        .foregroundColor(themeManager.textPrimary)
                                    
                                    Text("ECONÓMICO DE MÉXICO")
                                        .font(themeManager.headline)
                                        .foregroundColor(themeManager.textPrimary)
                                }
                                
                                VStack(spacing: 6) {
                                    Text("Conectamos consumidores con establecimientos")
                                        .font(themeManager.caption)
                                        .foregroundColor(themeManager.textSecondary)
                                    
                                    Text("para fortalecer la economía nacional")
                                        .font(themeManager.caption)
                                        .foregroundColor(themeManager.textSecondary)
                                }
                                
                                // Etiqueta de desarrollador
                                Text("Performed by: VAL Human Tech")
                                    .font(themeManager.footnote)
                                    .foregroundColor(themeManager.textSecondary.opacity(0.5))
                                    .padding(.top, 8)
                            }
                            .opacity(contentOpacity)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                    }
                }
            }
        }
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
        .onAppear {
            startAnimation()
        }
        .fullScreenCover(isPresented: $showMainApp) {
            GV_SCR_tc_menuprincipal() // ✨ Navegar a Menú Principal migrado
        }
    }
    
    private func startAnimation() {
        // Secuencia de animaciones estilo El Buen Fin con tema dinámico
        withAnimation(.easeInOut(duration: 0.6)) {
            backgroundOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.8)) {
                headerOpacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Iniciar efecto de pulso
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.8)) {
                contentOpacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.6)) {
                isAnimating = true
            }
        }
        
        // Transición a la app principal después de 5 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            showMainApp = true
        }
    }
}

#Preview {
    GV_SCR_tp_splash()
}
