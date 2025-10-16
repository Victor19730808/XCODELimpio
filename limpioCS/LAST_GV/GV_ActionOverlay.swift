import SwiftUI

/// Overlay de acciones reutilizable (Mapa, Lista, etc.)
struct GV_ActionOverlay: View {
    @Binding var isPresented: Bool
    var showWebsite: Bool
    var isFavorite: Bool
    var onGo: () -> Void
    var onRoute: () -> Void
    var onPromos: () -> Void
    var onQuickPromos: () -> Void
    var onToggleFavorite: () -> Void
    var onWebsite: () -> Void
    
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    var body: some View {
        Group {
            if isPresented {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { isPresented = false } }
                    VStack(spacing: 14) {
                        HStack(spacing: 24) {
                            actionButton(system: "mappin.and.ellipse") { onGo(); dismiss() }.accessibilityLabel("Ir a")
                            actionButton(system: "car.fill") { onRoute(); dismiss() }.accessibilityLabel("Ruta desde mi ubicación")
                            actionButton(system: "tag.fill") { onPromos(); dismiss() }.accessibilityLabel("Ver promociones")
                            // Variante ligera de promociones
                            actionButton(system: "tag") { onQuickPromos(); dismiss() }.accessibilityLabel("Promos rápidas")
                            actionButton(system: isFavorite ? "heart.slash" : "heart.fill",
                                         tint: isFavorite ? themeManager.textPrimary : .red) { onToggleFavorite(); dismiss() }
                                .accessibilityLabel(isFavorite ? "Quitar de favoritos" : "Guardar en favoritos")
                        }
                        HStack(spacing: 24) {
                            if showWebsite {
                                actionButton(system: "safari") { onWebsite(); dismiss() }.accessibilityLabel("Ver sitio web")
                            }
                            Button { dismiss() } label: {
                                Circle().fill(Color.red.opacity(0.2)).frame(width: 58, height: 58)
                                    .overlay(Image(systemName: "xmark").font(.system(size: 20, weight: .bold)).foregroundColor(.red))
                            }.accessibilityLabel("Cerrar")
                        }.opacity(0.9)
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.bottom, 18)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func actionButton(system: String, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(themeManager.cardBackground)
                .frame(width: 58, height: 58)
                .overlay(Image(systemName: system).font(.system(size: 22, weight: .semibold)).foregroundColor(tint ?? themeManager.textPrimary))
        }
    }
    
    private func dismiss() { withAnimation(.easeOut(duration: 0.2)) { isPresented = false } }
}



