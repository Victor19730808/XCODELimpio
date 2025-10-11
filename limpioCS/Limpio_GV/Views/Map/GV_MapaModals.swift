//
//  GV_MapaModals.swift
//  limpioCS
//
//  Created: 2025-01-10
//  Sistema: GV - Modals y Sheets del Mapa
//

import SwiftUI
import UIKit

// MARK: - Sheet de Detalles del Establecimiento

/// Modal con detalles completos del establecimiento
struct GV_EstablecimientoDetailSheet: View {
    let establecimiento: lmpBDF_EstablecimientoLocal
    let themeManager: GV_Temas_Manager
    let favoritosManager: GV_FavoritosManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: themeManager.spacing) {
                    // Header del establecimiento
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(establecimiento.nombre)
                                .font(themeManager.title)
                                .foregroundColor(themeManager.textPrimary)
                            
                            Spacer()
                            
                            if favoritosManager.isFavorite(establecimientoId: establecimiento.id) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(themeManager.accent)
                                    .font(.title2)
                            }
                        }
                        
                        // Dirección construida con municipio y estado
                        if let municipio = establecimiento.municipio, let estado = establecimiento.estado {
                            Text("\(municipio), \(estado)")
                                .font(themeManager.body)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }
                    
                    Divider()
                    
                    // Información del establecimiento
                    VStack(spacing: 12) {
                        if let categoria = establecimiento.categoria {
                            GV_InfoRow(
                                icon: "tag.fill",
                                title: "Categoría",
                                value: categoria
                            )
                        }
                        
                        if let municipio = establecimiento.municipio {
                            GV_InfoRow(
                                icon: "building.2.fill",
                                title: "Municipio",
                                value: municipio
                            )
                        }
                        
                        if let estado = establecimiento.estado {
                            GV_InfoRow(
                                icon: "map.fill",
                                title: "Estado",
                                value: estado
                            )
                        }
                        
                        // Coordenadas (para debug)
                        if let lat = establecimiento.lat, let lon = establecimiento.lon {
                            GV_InfoRow(
                                icon: "location.fill",
                                title: "Coordenadas",
                                value: String(format: "%.4f, %.4f", lat, lon)
                            )
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(themeManager.paddingMedium)
            }
            .navigationTitle("Detalles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .background(themeManager.background)
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
    }
}

// MARK: - Fila de Información

/// Componente reutilizable para mostrar información en filas
struct GV_InfoRow: View {
    let icon: String
    let title: String
    let value: String
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(themeManager.accent)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(themeManager.caption)
                    .foregroundColor(themeManager.textSecondary)
                
                Text(value)
                    .font(themeManager.body)
                    .foregroundColor(themeManager.textPrimary)
            }
            
            Spacer()
        }
        .padding(themeManager.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                .fill(themeManager.surface)
        )
    }
}

// MARK: - Sheet de Código QR

/// Modal para mostrar el código QR generado
struct GV_QRCodeSheet: View {
    let qrImage: UIImage?
    let cantidadLugares: Int
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Título
                    VStack(spacing: 8) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.accent)
                        
                        Text("Código QR Generado")
                            .font(themeManager.title)
                            .foregroundColor(themeManager.textPrimary)
                        
                        Text("\(min(cantidadLugares, 9)) lugares visibles")
                            .font(themeManager.caption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    
                    // Imagen del QR
                    if let qrImage = qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: themeManager.shadow, radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.surface)
                            .frame(width: 250, height: 250)
                            .overlay(
                                Text("Error al generar QR")
                                    .foregroundColor(themeManager.textSecondary)
                            )
                    }
                    
                    // Botón de compartir
                    if let qrImage = qrImage {
                        Button(action: {
                            shareQRCode(qrImage)
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Compartir")
                            }
                            .font(themeManager.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(themeManager.accent)
                            .cornerRadius(themeManager.cornerRadius)
                        }
                    }
                    
                    Spacer()
                }
                .padding(themeManager.paddingMedium)
            }
            .navigationTitle("Código QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shareQRCode(_ image: UIImage) {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Sheet de Selector de Categorías

/// Modal para seleccionar categorías de establecimientos
struct GV_SelectorCategoriaSheet: View {
    @Binding var categoriaSeleccionada: String?
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    private let categoriaManager = GV_CategoriaManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Selector de Categorías")
                        .font(themeManager.title)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Text("Funcionalidad en desarrollo")
                        .font(themeManager.body)
                        .foregroundColor(themeManager.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Cerrar") {
                        dismiss()
                    }
                    .padding()
                    .background(themeManager.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding(themeManager.paddingMedium)
            }
            .navigationTitle("Filtrar por Categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        GV_EstablecimientoDetailSheet(
            establecimiento: lmpBDF_EstablecimientoLocal(
                id: 1,
                nombre: "Restaurante Ejemplo",
                municipio: "Campeche",
                estado: "Campeche",
                categoria: "Restaurante"
            ),
            themeManager: GV_Temas_Manager.shared,
            favoritosManager: GV_FavoritosManager.shared
        )
    }
}
