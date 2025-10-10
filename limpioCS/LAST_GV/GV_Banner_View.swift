//
//  GV_Banner_View.swift
//  limpioCS
//
//  Created by Victor on 2025-10-10.
//  Vista de banners rotativos para patrocinadores
//  Parte del Framework GV - Función: showGVBanner()
//

import SwiftUI

/// Vista principal de banners rotativos - Función pública del framework GV
struct GV_Banner_View: View {
    @ObservedObject private var bannerManager = GV_Banner_Manager.shared
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    @State private var showWebView = false
    @State private var selectedURL: URL?
    
    var body: some View {
        // Solo mostrar si hay banners activos
        if bannerManager.hayBanners, let primerBanner = bannerManager.bannersActivos.first {
            VStack(spacing: 0) {
                // Header del banner (condicional según configuración)
                if primerBanner.mostrarHeader {
                    HStack {
                        Image(systemName: primerBanner.headerIcono)
                            .font(themeManager.headline)
                            .foregroundColor(themeManager.accent)
                        
                        Text(primerBanner.headerTitulo)
                            .font(themeManager.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.textPrimary)
                        
                        Spacer()
                        
                        // Botón Play/Pause
                        Button(action: {
                            bannerManager.toggleReproduccion()
                        }) {
                            Image(systemName: bannerManager.estaReproduciendo ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title3)
                                .foregroundColor(themeManager.accent)
                        }
                    }
                    .padding(.horizontal, themeManager.paddingMedium)
                    .padding(.vertical, 8)
                }
                
                // Contenido del banner con TabView
                TabView(selection: $bannerManager.bannerActualIndex) {
                    ForEach(Array(bannerManager.bannersActivos.enumerated()), id: \.element.id) { index, banner in
                        BannerCard(banner: banner)
                            .tag(index)
                            .onTapGesture {
                                handleBannerTap(banner)
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 180)
                
                // Indicadores de página personalizados
                HStack(spacing: 8) {
                    ForEach(0..<bannerManager.bannersActivos.count, id: \.self) { index in
                        Circle()
                            .fill(index == bannerManager.bannerActualIndex ? themeManager.accent : themeManager.textSecondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                bannerManager.saltarABanner(index)
                            }
                    }
                }
                .padding(.vertical, 8)
            }
            .background(themeManager.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadius))
            .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 4)
            .sheet(isPresented: $showWebView) {
                if let url = selectedURL {
                    SafariWebView(url: url)
                }
            }
        }
    }
    
    // MARK: - Manejo de Tap en Banner
    
    /// Maneja el tap en un banner
    private func handleBannerTap(_ banner: GV_Banner_Config) {
        guard banner.tieneEnlace, let url = banner.urlDestino else {
            print("ℹ️ Banner '\(banner.nombre)' no tiene enlace configurado")
            return
        }
        
        print("🔗 Abriendo enlace: \(url.absoluteString)")
        
        if banner.abrirFueraDeApp {
            // Abrir en Safari
            UIApplication.shared.open(url)
        } else {
            // Abrir en WebView interno
            selectedURL = url
            showWebView = true
        }
    }
}

// MARK: - Card Individual de Banner

struct BannerCard: View {
    let banner: GV_Banner_Config
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    var body: some View {
        ZStack {
            // Imagen de fondo
            if let assetsName = banner.imagenAssets, !assetsName.isEmpty {
                // Imagen desde Assets (preferencia)
                Image(assetsName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
            } else if let imageURL = banner.imagenURL {
                // Imagen desde URL (fallback)
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(themeManager.surface)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                    case .failure:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                // Sin imagen - mostrar texto alternativo
                fallbackView
            }
            
            // Overlay con gradiente para legibilidad
            LinearGradient(
                colors: [.clear, .black.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Información del banner
            VStack {
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(banner.nombre)
                            .font(themeManager.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if banner.tieneEnlace, let url = banner.url {
                            Text(cleanURL(url))
                                .font(themeManager.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    Spacer()
                    
                    if banner.tieneEnlace {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(themeManager.paddingMedium)
            }
        }
        .frame(height: 180)
        .cornerRadius(themeManager.cornerRadius)
    }
    
    // Vista de fallback cuando no hay imagen
    private var fallbackView: some View {
        ZStack {
            LinearGradient(
                colors: [themeManager.accent, themeManager.accent.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(banner.textoAlternativo)
                    .font(themeManager.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    // Limpia la URL para mostrar (quita https://, www., etc.)
    private func cleanURL(_ urlString: String) -> String {
        var cleaned = urlString
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
        
        // Tomar solo el dominio principal
        if let firstSlash = cleaned.firstIndex(of: "/") {
            cleaned = String(cleaned[..<firstSlash])
        }
        
        return cleaned
    }
}

// MARK: - Safari WebView (para abrir dentro de la app)

import SafariServices

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: config)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Función Pública del Framework GV

extension GV_Banner_Manager {
    /// 🎯 FUNCIÓN PRINCIPAL DEL FRAMEWORK
    /// Devuelve la vista del banner configurado y listo para usar
    /// - Returns: Vista del banner con auto-rotación
    func showGVBanner() -> some View {
        return GV_Banner_View()
    }
}

// MARK: - Preview

#Preview {
    VStack {
        GV_Banner_Manager.shared.showGVBanner()
            .padding()
        
        Spacer()
    }
}

