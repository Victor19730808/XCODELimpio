import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    @State private var particleOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.0
    @State private var rotationAngle: Double = 0.0
    
    var body: some View {
        ZStack {
            // Fondo con gradiente animado
            AnimatedGradientBackground()
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
            
            // Imagen de portada con parallax
            Image("Portada")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
                .offset(y: particleOffset * 0.3) // Efecto parallax
                .animation(.easeInOut(duration: 1.0), value: logoScale)
                .animation(.easeInOut(duration: 1.0), value: logoOpacity)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: particleOffset)
            
            // Efecto de partículas
            ParticleEffectView(offset: particleOffset)
                .opacity(logoOpacity * 0.6)
            
            // Overlay con efecto de desvanecimiento
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .ignoresSafeArea()
                .opacity(isAnimating ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 1.5), value: isAnimating)
            
                // Logo/Texto de la app con efectos avanzados
                VStack(spacing: 20) {
                    // Contenido removido - solo efectos de fondo
                }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
        }
        .onAppear {
            startAnimation()
        }
        .fullScreenCover(isPresented: $showMainApp) {
            PORT_PASO()
        }
    }
    
    private func startAnimation() {
        // Secuencia de animaciones avanzadas
        withAnimation(.easeInOut(duration: 0.8)) {
            backgroundOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Iniciar efectos de partículas
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                particleOffset = 20
            }
            
            // Iniciar efecto de brillo
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
            
            // Iniciar rotación sutil
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                rotationAngle = 5
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
        }
        
        // Transición a la app principal después de 2.5 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            showMainApp = true
        }
    }
}

// MARK: - Componentes de Animación Avanzada

struct AnimatedGradientBackground: View {
    @State private var gradientOffset: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color.blue.opacity(0.8),
                Color.purple.opacity(0.6),
                Color.pink.opacity(0.4)
            ]),
            startPoint: UnitPoint(x: gradientOffset, y: 0),
            endPoint: UnitPoint(x: 1 - gradientOffset, y: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                gradientOffset = 0.3
            }
        }
    }
}

struct ParticleEffectView: View {
    let offset: CGFloat
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 2...6),
                color: [Color.white, Color.blue, Color.purple].randomElement() ?? .white,
                opacity: Double.random(in: 0.3...0.8),
                scale: Double.random(in: 0.5...1.2)
            )
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
    let scale: Double
}

#Preview {
    SplashScreenView()
}
