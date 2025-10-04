//
//  SplashShowcaseAllInOne.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Showcase de transiciones Splash -> Menú en un SOLO archivo.
//  Cambia la constante `currentStyle` para probar cada efecto.
//  iOS 17+ · SwiftUI
//

import SwiftUI

// MARK: - Selector principal (cambia aquí el estilo)
struct SplashShowcaseView: View {
    // Estilos disponibles: .kenBurns, .flip3D, .zoomOutBounce, .parallaxSlide, .staggeredButtons
    private let currentStyle: SplashStyle = .staggeredButtons

    var body: some View {
        switch currentStyle {
        case .kenBurns:
            SplashKenBurnsView()
        case .flip3D:
            SplashFlip3DView()
        case .zoomOutBounce:
            SplashZoomOutBounceView()
        case .parallaxSlide:
            SplashParallaxSlideView()
        case .staggeredButtons:
            SplashStaggeredButtonsView()
        }
    }
}

// MARK: - Enum de estilos
enum SplashStyle {
    case kenBurns, flip3D, zoomOutBounce, parallaxSlide, staggeredButtons
}

#Preview {
    SplashShowcaseView()
        .environment(\.colorScheme, .dark)
}

// ===============================================================
// ==============   1) KEN BURNS + BLUR PROGRESIVO   =============
// ===============================================================
struct SplashKenBurnsView: View {
    @State private var showSplash = true
    @State private var zoom: CGFloat = 1.0
    @State private var tilt: Double = 0
    @State private var blur: CGFloat = 0

    var body: some View {
        ZStack {
            if showSplash {
                Image("Portada")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .scaleEffect(zoom)
                    .rotationEffect(.degrees(tilt))
                    .blur(radius: blur)
                    .overlay(
                        LinearGradient(colors: [.clear, .black.opacity(0.15), .black.opacity(0.35)],
                                       startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                    )
                    .transition(.opacity)
            } else {
                ButtonsHomeView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                zoom = 1.12
                tilt = 1.5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.8)) { blur = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(duration: 0.9, bounce: 0.35)) { showSplash = false }
            }
        }
    }
}

// ===============================================================
// ==========================  2) FLIP 3D  =======================
// ===============================================================
struct SplashFlip3DView: View {
    @State private var flipped = false

    var body: some View {
        ZStack {
            if !flipped {
                Image("Portada")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    .transition(.identity)
            } else {
                ButtonsHomeView()
                    .rotation3DEffect(.degrees(flipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                    .transition(.identity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 1.0)) { flipped = true }
            }
        }
    }
}

// ===============================================================
// ====================  3) ZOOM OUT + BOUNCE  ===================
// ===============================================================
struct SplashZoomOutBounceView: View {
    @State private var showSplash = true
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            if showSplash {
                Image("Portada")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .scaleEffect(scale)
                    .transition(.opacity)
            } else {
                ButtonsHomeView()
                    .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8)) { scale = 1.2 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(duration: 0.8, bounce: 0.4)) { showSplash = false }
            }
        }
    }
}

// ===============================================================
// ====================  4) SLIDE + PARALLAX  ====================
// ===============================================================
struct SplashParallaxSlideView: View {
    @State private var showSplash = true
    @State private var offsetY: CGFloat = 0

    var body: some View {
        ZStack {
            if showSplash {
                Image("Portada")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .offset(y: offsetY) // se mueve a distinta velocidad (parallax ligero)
                    .transition(.identity)
            } else {
                ButtonsHomeView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) { offsetY = -80 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 1.0)) { showSplash = false }
            }
        }
    }
}

// ===============================================================
// =========== 5) STAGGERED (BOTONES APARECEN EN CASCADA) ========
// ===============================================================
struct SplashStaggeredButtonsView: View {
    @State private var showSplash = true
    @State private var showButtons = [false, false, false, false]

    private let titles = ["Hecho en México", "Mis Favoritos", "Cerca de mí", "Todo México"]
    private let icons  = ["seal.fill", "star.fill", "map.fill", "globe.americas.fill"]

    var body: some View {
        ZStack {
            if showSplash {
                Image("Portada")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .transition(.opacity)
            } else {
                NavigationStack {
                    VStack(spacing: 18) {
                        Text("Bienvenido")
                            .font(.headline)
                            .padding(.top, 40)

                        ForEach(0..<4, id: \.self) { i in
                            if showButtons[i] {
                                MenuButton(title: titles[i], systemImage: icons[i]) { Text(titles[i]) }
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 22)
                    .navigationTitle("Menú Principal")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showSplash = false }
                for i in 0..<4 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 * Double(i)) {
                        withAnimation(.spring(duration: 0.6, bounce: 0.35)) { showButtons[i] = true }
                    }
                }
            }
        }
    }
}

// ===============================================================
// ===================  VISTA MENÚ REUTILIZABLE  =================
// ===============================================================
struct ButtonsHomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Menú Principal")
                    .font(.headline)
                    .padding(.top, 28)

                MenuButton(title: "Hecho en México", systemImage: "seal.fill") { HechoEnMexicoView() }
                MenuButton(title: "Mis Favoritos", systemImage: "star.fill") { FavoritosView() }
                MenuButton(title: "Cerca de mí", systemImage: "map.fill") { Mapa1View() }
                MenuButton(title: "Todo México", systemImage: "globe.americas.fill") { Mapa2View() }

                Spacer()
            }
            .padding(.horizontal, 22)
        }
    }
}

struct MenuButton<Destination: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage).font(.headline.weight(.semibold))
                Text(title).font(.headline)
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                Color.red.opacity(0.18),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}

// ===============================================================
// ==============  DESTINOS PLACEHOLDER (reemplazar)  ============
// ===============================================================
struct HechoEnMexicoView: View {
    var body: some View {
        Text("Hecho en México").navigationTitle("Hecho en México")
    }
}

struct FavoritosView: View {
    var body: some View {
        Text("Mis Favoritos").navigationTitle("Favoritos")
    }
}

struct Mapa1View: View {
    var body: some View {
        Text("Mapa 1 — Cerca de mí").navigationTitle("Cerca de mí")
    }
}

struct Mapa2View: View {
    var body: some View {
        Text("Mapa 2 — Todo México").navigationTitle("Todo México")
    }
}
