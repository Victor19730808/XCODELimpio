//
//  GV_MapaPines.swift
//  limpioCS
//
//  Created: 2025-01-10
//  Sistema: GV - Componentes de Pines del Mapa
//

import SwiftUI
import MapKit

// MARK: - Pin de Establecimiento

/// Pin personalizado para establecimientos individuales
struct GV_PinEstablecimiento: View {
    let establecimiento: lmpBDF_EstablecimientoLocal
    let themeManager: GV_Temas_Manager
    let favoritosManager: GV_FavoritosManager
    let usarColoresPorCategoria: Bool
    
    var body: some View {
        ZStack {
            // Círculo con gradiente sutil
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2.5)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
            
            // Icono interior
            Image(systemName: favoritosManager.isFavorite(establecimientoId: establecimiento.id) ? "heart.fill" : "building.2.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Colores para gradiente
    
    private var gradientColors: [Color] {
        if favoritosManager.isFavorite(establecimientoId: establecimiento.id) {
            return [themeManager.accent, themeManager.accent.opacity(0.8)]
        } else if usarColoresPorCategoria {
            let baseColor = colorPorCategoria(establecimiento.categoria)
            return [baseColor, baseColor.opacity(0.8)]
        } else {
            return [Color.teal, Color.teal.opacity(0.8)]
        }
    }
    
    // MARK: - Función para obtener color según categoría
    
    private func colorPorCategoria(_ categoria: String?) -> Color {
        guard let cat = categoria?.lowercased() else { return Color.gray }
        
        // Mapeo de categorías a colores (ajusta según tus categorías reales)
        switch cat {
        case let c where c.contains("restaurante") || c.contains("comida") || c.contains("restaurant"):
            return Color.red
        case let c where c.contains("moda") || c.contains("ropa") || c.contains("fashion"):
            return Color.purple
        case let c where c.contains("hogar") || c.contains("mueble") || c.contains("home"):
            return Color.brown
        case let c where c.contains("tecnología") || c.contains("electr") || c.contains("tech"):
            return Color.blue
        case let c where c.contains("salud") || c.contains("farmacia") || c.contains("health"):
            return Color.green
        case let c where c.contains("deporte") || c.contains("sport") || c.contains("gym"):
            return Color.orange
        case let c where c.contains("belleza") || c.contains("estética") || c.contains("beauty"):
            return Color.pink
        case let c where c.contains("entretenimiento") || c.contains("cine") || c.contains("entertainment"):
            return Color.indigo
        case let c where c.contains("educación") || c.contains("librería") || c.contains("education"):
            return Color.cyan
        case let c where c.contains("automotriz") || c.contains("auto") || c.contains("car"):
            return Color.gray
        default:
            return Color.teal  // Color por defecto
        }
    }
}

// MARK: - Pin de Cluster

/// Pin para mostrar clusters de establecimientos
struct GV_PinCluster: View {
    let count: Int
    let themeManager: GV_Temas_Manager
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            // Círculo exterior con efecto de presión
            Circle()
                .fill(themeManager.accent)
                .frame(width: (count > 9 ? 32 : 28) + (isPressed ? 4 : 0), 
                       height: (count > 9 ? 32 : 28) + (isPressed ? 4 : 0))
                .shadow(color: Color.black.opacity(0.3), radius: isPressed ? 5 : 3, x: 0, y: isPressed ? 3 : 2)
                .scaleEffect(isPressed ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
            
            // Círculo interior con borde
            Circle()
                .fill(Color.white)
                .frame(width: (count > 9 ? 26 : 22) + (isPressed ? 2 : 0), 
                       height: (count > 9 ? 26 : 22) + (isPressed ? 2 : 0))
            
            // Texto del contador
            Text("\(count)")
                .font(.system(size: (count > 9 ? 12 : 14) + (isPressed ? 1 : 0), weight: .bold))
                .foregroundColor(themeManager.accent)
        }
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {}
    }
}

// MARK: - Pin de Ubicación del Usuario

/// Pin para mostrar la ubicación actual del usuario
struct GV_PinUbicacionUsuario: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Círculo exterior sutil (azul translúcido)
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: isPulsing ? 24 : 20, height: isPulsing ? 24 : 20)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
            
            // Pin principal (azul sólido, pequeño)
            Circle()
                .fill(Color.blue)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            GV_PinEstablecimiento(
                establecimiento: lmpBDF_EstablecimientoLocal(
                    id: 1,
                    nombre: "Restaurante Ejemplo",
                    categoria: "Restaurante"
                ),
                themeManager: GV_Temas_Manager.shared,
                favoritosManager: GV_FavoritosManager.shared,
                usarColoresPorCategoria: true
            )
            
            GV_PinCluster(
                count: 5,
                themeManager: GV_Temas_Manager.shared,
                onTap: {}
            )
            
            GV_PinUbicacionUsuario()
        }
        
        Spacer()
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
