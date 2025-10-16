//
//  GV_SCR_vg_FavoritosView.swift
//  limpioCS
//
//  Migrado: 2025-01-10
//  Sistema: GV (Temas + Headers + Menús + ScreenTypes)
//

import SwiftUI
import SwiftData
import CoreLocation

struct GV_SCR_vg_FavoritosView: View {
    // MARK: - Configuración del Sistema GV
    private let screenType: ScreenType = .general
    private let myHeader: GV_HeaderType = .tipo2
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    private let categoriaManager = GV_CategoriaManager.shared
    private let config = GV_ConfiguracionesGenerales.shared
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Managers
    @ObservedObject private var favoritosManager = GV_FavoritosManager.shared
    @EnvironmentObject private var locationService: LocationService
    
    // Trae todos los establecimientos (filtrará por favoritos en computed property)
    @Query(
        sort: \GV_modeloCont_Establecimientos.establecimiento_nombre,
        order: .forward
    )
    private var todosEstablecimientos: [GV_modeloCont_Establecimientos]
    
    // Computed property para obtener solo los favoritos
    private var favoritos: [GV_modeloCont_Establecimientos] {
        let base = todosEstablecimientos.filter { favoritosManager.isFavorite(establecimientoId: $0.establecimiento_id) }
        let userCoord: CLLocationCoordinate2D? = {
            guard let lat = locationService.latitude, let lon = locationService.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }()
        return base.sorted { a, b in
            distancia(a, user: userCoord) < distancia(b, user: userCoord)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header con menú - TODO EN UNA SOLA LÍNEA! 🎯
            myHeader.headerViewWithMenu("Mis Favoritos", nil, .principal)
            
            // Contenido principal con tema aplicado
            VStack(spacing: 0) {
                if favoritos.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "star")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.textSecondary.opacity(0.3))
                        
                        VStack(spacing: 8) {
                            Text("Aún no tienes favoritos")
                                .font(themeManager.title)
                                .foregroundColor(themeManager.textPrimary)
                            
                            Text("Marca establecimientos con la estrella para verlos aquí.")
                                .font(themeManager.body)
                                .foregroundColor(themeManager.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: config.lista_RowSpacing) {
                            ForEach(favoritos) { est in
                                Button { selected = est; showActions = true } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 8) {
                                            if let id = categoriaIdResuelta(for: est), let cat = categoriaManager.categoria(byId: id) {
                                                Image(systemName: cat.icono)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .padding(6)
                                                    .background(cat.color)
                                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                            } else {
                                                let color = Color(hex: config.lista_NoCategoryColorHex) ?? .gray
                                                Image(systemName: config.lista_NoCategoryIcon)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .padding(6)
                                                    .background(color)
                                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                            }
                                            Text(est.establecimiento_nombre)
                                                .font(themeManager.body)
                                                .fontWeight(.bold)
                                                .foregroundColor(themeManager.textPrimary)
                                            Spacer()
                                            if let d = distanciaDesdeUsuario(para: est) {
                                                Text(String(format: "%.1f km", d)).font(.caption).foregroundColor(themeManager.textSecondary)
                                            }
                                            Image(systemName: "heart.fill").foregroundColor(.red).font(.caption)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(themeManager.cardBackground)
                                    .cornerRadius(themeManager.cornerRadius)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, themeManager.paddingMedium)
                            }
                        }
                        .padding(.vertical, themeManager.spacing)
                    }
                }
            }
        }
        .background(themeManager.background)
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
        .navigationBarHidden(true)
        .overlay(
            GV_ActionOverlay(
                isPresented: $showActions,
                showWebsite: (selected?.establecimiento_url?.isEmpty == false),
                isFavorite: true,
                onGo: { if let est = selected { irA(est) } },
                onRoute: { if let est = selected { rutaA(est) } },
                onPromos: { if selected != nil { navegarAPromos = true } },
                onQuickPromos: { if let est = selected { quickPromoEst = est; showQuickPromo = true } },
                onToggleFavorite: { if let est = selected { favoritosManager.toggleFavorite(establecimientoId: est.establecimiento_id) } },
                onWebsite: { if let est = selected { abrirSitioWeb(est) } }
            )
        )
        .navigationDestination(isPresented: $navegarAPromos) {
            if let est = selected {
                GV_SRC_vg_EstablecimientoPromociones(establecimientoId: est.establecimiento_id)
            }
        }
        .navigationDestination(isPresented: $navegarAlMapa) {
            GV_GreatMap(isTodoMexico: false, initialFocusCoordinate: focoMapaCoord)
        }
        .sheet(isPresented: $showQuickPromo) { quickPromosSheet }
    }

    // MARK: - Acciones y helpers
    @State private var selected: GV_modeloCont_Establecimientos? = nil
    @State private var showActions = false
    @State private var navegarAPromos = false
    @State private var navegarAlMapa = false
    @State private var focoMapaCoord: CLLocationCoordinate2D? = nil
    @State private var showQuickPromo = false
    @State private var quickPromoEst: GV_modeloCont_Establecimientos? = nil
    
    private func categoriaIdResuelta(for est: GV_modeloCont_Establecimientos) -> Int? {
        if let id = est.categoria_id, categoriaManager.categoria(byId: id) != nil { return id }
        if let nombre = est.categoria_nombre, let cat = categoriaManager.categoria(byNombre: nombre) { return cat.categoria_id }
        return nil
    }
    private func distanciaDesdeUsuario(para est: GV_modeloCont_Establecimientos) -> Double? {
        guard let userLat = locationService.latitude, let userLon = locationService.longitude,
              let lat = est.direccion_latitud, let lon = est.direccion_longitud else { return nil }
        let user = CLLocation(latitude: userLat, longitude: userLon)
        let dest = CLLocation(latitude: lat, longitude: lon)
        return user.distance(from: dest) / 1000.0
    }
    private func distancia(_ est: GV_modeloCont_Establecimientos, user: CLLocationCoordinate2D?) -> Double {
        guard let u = user, let lat = est.direccion_latitud, let lon = est.direccion_longitud else { return .infinity }
        let userLoc = CLLocation(latitude: u.latitude, longitude: u.longitude)
        return userLoc.distance(from: CLLocation(latitude: lat, longitude: lon))
    }
    private func irA(_ est: GV_modeloCont_Establecimientos) {
        guard let lat = est.direccion_latitud, let lon = est.direccion_longitud else { return }
        focoMapaCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        navegarAlMapa = true
    }
    private func rutaA(_ est: GV_modeloCont_Establecimientos) {
        guard let lat = est.direccion_latitud, let lon = est.direccion_longitud,
              let url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d") else { return }
        UIApplication.shared.open(url)
    }
    private func abrirSitioWeb(_ est: GV_modeloCont_Establecimientos) {
        guard let s = est.establecimiento_url, let url = URL(string: s) else { return }
        UIApplication.shared.open(url)
    }
    private var quickPromosSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                if let est = quickPromoEst {
                    GV_QuickPromosView(establecimientoId: est.establecimiento_id, establecimientoNombre: est.establecimiento_nombre)
                }
            }
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .toolbar { ToolbarItem(placement: .primaryAction) { Button("Cerrar") { showQuickPromo = false } } }
        }
    }
}

#Preview {
    NavigationStack {
        GV_SCR_vg_FavoritosView()
    }
}
