import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    @State private var headerOpacity: Double = 0.0
    @State private var contentOpacity: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Fondo usando el tema actual
            themeManager.backgroundColor
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
            
            VStack(spacing: 0) {
                    // Header rojo minimalista
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            
                            // Etiqueta "Hecho en México" centrada
                            Text("Hecho en México")
                                .font(themeManager.currentTheme.fonts.body)
                                .foregroundColor(themeManager.currentTheme.colors.textOnPrimary)
                            
                            Spacer()
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
                .background(themeManager.currentTheme.colors.primary)
                .opacity(headerOpacity)
                
                // Contenido principal con fondo gris
                VStack(spacing: 0) {
                    // Fondo gris elegante
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
                        
                        VStack(spacing: 40) {
                            Spacer()
                            
                            // Composición elegante con las tres imágenes
                            VStack(spacing: 0) {
                                // Composición triangular de las imágenes
                                ZStack {
                                    // Círculo de fondo con pulso sutil
                                    Circle()
                                        .fill(themeManager.currentTheme.colors.primary.opacity(0.08))
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
                                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                            .scaleEffect(logoScale)
                                        
                                        // Imágenes inferiores - HM y BF lado a lado
                                        HStack(spacing: 35) {
                                            Image("HM")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 120, height: 120)
                                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                                .scaleEffect(logoScale)
                                            
                                            Image("BF")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 120, height: 120)
                                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                                .scaleEffect(logoScale)
                                        }
                                    }
                                }
                                .opacity(logoOpacity)
                            }
                            
                            Spacer()
                            
                            // Footer con mensaje poderoso
                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Text("IMPULSANDO EL CRECIMIENTO")
                                        .font(themeManager.currentTheme.fonts.headline)
                                        .foregroundColor(themeManager.currentTheme.colors.textPrimary)
                                    
                                    Text("ECONÓMICO DE MÉXICO")
                                        .font(themeManager.currentTheme.fonts.headline)
                                        .foregroundColor(themeManager.currentTheme.colors.textPrimary)
                                }
                                
                                VStack(spacing: 6) {
                                    Text("Conectamos consumidores con establecimientos")
                                        .font(themeManager.currentTheme.fonts.caption)
                                        .foregroundColor(themeManager.currentTheme.colors.textSecondary)
                                    
                                    Text("para fortalecer la economía nacional")
                                        .font(themeManager.currentTheme.fonts.caption)
                                        .foregroundColor(themeManager.currentTheme.colors.textSecondary)
                                }
                                
                                // Etiqueta de desarrollador
                                Text("Performed by: VAL Human Tech")
                                    .font(themeManager.currentTheme.fonts.footnote)
                                    .foregroundColor(themeManager.currentTheme.colors.textSecondary.opacity(0.5))
                                    .padding(.top, 8)
                            }
                            .opacity(contentOpacity)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                    }
                }
                .padding(.horizontal, 30)
            }
        }
        .onAppear {
            startAnimation()
        }
        .fullScreenCover(isPresented: $showMainApp) {
            PORT_PASO()
        }
    }
    
    private func startAnimation() {
        // Secuencia de animaciones estilo El Buen Fin
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

// MARK: - Componentes de Estilo con Temas Dinámicos

// Los componentes de animación compleja han sido reemplazados por un diseño más limpio
// que se adapta dinámicamente al tema seleccionado (Claro, Oscuro, BuenFin)

#Preview {
    SplashScreenView()
}
