//
//  GV_MapaFiltros.swift
//  limpioCS
//
//  Created: 2025-01-10
//  Sistema: GV - Componente de Filtros del Mapa
//

import SwiftUI

// MARK: - Vista de Filtros del Mapa

struct GV_MapaFiltros: View {
    // MARK: - Bindings
    @Binding var filtroNombre: String
    @Binding var soloFavoritos: Bool
    @Binding var mostrarClusters: Bool
    @Binding var usarColoresPorCategoria: Bool
    @Binding var categoriaSeleccionada: String?
    @Binding var mostrarSelectorCategoria: Bool
    
    // MARK: - Callbacks
    let onGenerarQR: () -> Void
    
    // MARK: - Managers
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Fila superior: Búsqueda
            HStack(spacing: 12) {
                // Campo de búsqueda
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.textSecondary)
                    
                    TextField("Buscar establecimiento...", text: $filtroNombre)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(themeManager.body)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                        .fill(themeManager.surface)
                        .stroke(themeManager.border, lineWidth: themeManager.borderWidth)
                )
            }
            
            // Fila inferior: Botones de filtro
            HStack(spacing: 8) {
                // Botón de favoritos
                Button(action: {
                    soloFavoritos.toggle()
                }) {
                    Image(systemName: soloFavoritos ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(soloFavoritos ? .red : themeManager.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(soloFavoritos ? themeManager.accent.opacity(0.2) : themeManager.surface)
                        )
                }
                .buttonStyle(.plain)
                
                // Botón de clusters
                Button(action: {
                    mostrarClusters.toggle()
                }) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(mostrarClusters ? themeManager.accent : themeManager.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(mostrarClusters ? themeManager.accent.opacity(0.2) : themeManager.surface)
                        )
                }
                .buttonStyle(.plain)
                
                // Botón de colores por categoría
                Button(action: {
                    usarColoresPorCategoria.toggle()
                }) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(usarColoresPorCategoria ? themeManager.accent : themeManager.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(usarColoresPorCategoria ? themeManager.accent.opacity(0.2) : themeManager.surface)
                        )
                }
                .buttonStyle(.plain)
                
                // Botón de categorías
                Button(action: {
                    mostrarSelectorCategoria = true
                }) {
                    Image(systemName: "tag")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(categoriaSeleccionada != nil ? themeManager.accent : themeManager.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(categoriaSeleccionada != nil ? themeManager.accent.opacity(0.2) : themeManager.surface)
                        )
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Botón de QR
                Button(action: onGenerarQR) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.accent)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(themeManager.accent.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, themeManager.paddingMedium)
        .padding(.vertical, 8)
        .background(themeManager.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadius))
        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        GV_MapaFiltros(
            filtroNombre: .constant(""),
            soloFavoritos: .constant(false),
            mostrarClusters: .constant(false),
            usarColoresPorCategoria: .constant(false),
            categoriaSeleccionada: .constant(nil),
            mostrarSelectorCategoria: .constant(false),
            onGenerarQR: {}
        )
        .padding()
        
        Spacer()
    }
    .background(Color.gray.opacity(0.1))
}
