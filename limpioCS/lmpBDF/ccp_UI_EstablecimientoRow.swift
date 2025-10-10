//
//  ccp_UI_EstablecimientoRow.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Descripción:
//  ----------------------------------------------------------------
//  • Componente visual reutilizable para mostrar un establecimiento
//    con su información básica y un botón para marcarlo como favorito.
//  • Vinculado al modelo SwiftData: lmpBDF_EstablecimientoLocal
//  • Permite alternar la propiedad esFavorito y guardar cambios.
//  • Migrado al sistema de temas dinámico
//
//  Fecha: 2025-10-04
//  Migrado: 2025-01-10
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct ccp_UI_EstablecimientoRow: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationService: LocationService
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    @Bindable var est: lmpBDF_EstablecimientoLocal
    @State private var isPressed = false
    @State private var showPromociones = false
    @State private var showFavoritoConfirmation = false

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                // Nombre del establecimiento
                Text(est.nombre)
                    .font(themeManager.body)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.textPrimary)
                    .lineLimit(2)
                
                // Estado
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(themeManager.caption)
                        .foregroundStyle(themeManager.error)
                    
                    Text(est.estado ?? "N/A")
                        .font(themeManager.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(themeManager.textSecondary)
                }
                
                // Categoría
                if let categoria = est.categoria, !categoria.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .font(themeManager.caption)
                            .foregroundStyle(themeManager.error)
                        
                        Text(categoria)
                            .font(themeManager.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(themeManager.textSecondary)
                    }
                }
                
                // Distancia (solo en favoritos) - clickeable para ir al mapa
                if est.esFavorito && hasValidCoordinates {
                    NavigationLink(destination: MapViewWithLocation(establecimiento: est)) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.circle.fill")
                                .font(themeManager.caption)
                                .foregroundStyle(themeManager.error)
                            
                            Text("A \(distanceFromUser) km")
                                .font(themeManager.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(themeManager.error)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                                .fill(themeManager.error.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                                        .stroke(themeManager.error.opacity(0.3), lineWidth: themeManager.borderWidth)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                // Botón de promociones
                Button {
                    showPromociones = true
                } label: {
                    Image(systemName: "tag.fill")
                        .font(themeManager.title)
                        .foregroundStyle(themeManager.error)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(themeManager.error.opacity(0.1))
                                .overlay(
                                    Circle()
                                        .stroke(themeManager.error.opacity(0.2), lineWidth: themeManager.borderWidth)
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ver promociones")
                
                // Botón de favoritos
                Button {
                    showFavoritoConfirmation = true
                } label: {
                    Image(systemName: est.esFavorito ? "star.fill" : "star")
                        .font(themeManager.title)
                        .foregroundStyle(est.esFavorito ? themeManager.warning : themeManager.textSecondary)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }
                .buttonStyle(.plain)
                .onLongPressGesture(minimumDuration: 0) { pressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressing
                    }
                } perform: {}
                .accessibilityLabel(est.esFavorito ? "Quitar de favoritos" : "Agregar a favoritos")
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                .fill(themeManager.cardBackground)
                .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 4)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .sheet(isPresented: $showPromociones) {
            ccp_BDF_PromocionesView(establecimientoIdInicial: est.id)
        }
        .alert(est.esFavorito ? "Quitar de favoritos" : "Agregar a favoritos", isPresented: $showFavoritoConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button(est.esFavorito ? "Quitar" : "Agregar") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    est.esFavorito.toggle()
                }
                do {
                    try modelContext.save()
                } catch {
                    print("⚠️ Error al guardar favorito:", error.localizedDescription)
                }
            }
        } message: {
            Text(est.esFavorito ? 
                "¿Quieres quitar \"\(est.nombre)\" de tus favoritos?" :
                "¿Quieres agregar \"\(est.nombre)\" a tus favoritos?")
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasValidCoordinates: Bool {
        guard let lat = est.lat, let lon = est.lon else { return false }
        return lat != 0 && lon != 0
    }
    
    private var distanceFromUser: String {
        guard let userLat = locationService.latitude,
              let userLon = locationService.longitude,
              let estLat = est.lat,
              let estLon = est.lon else {
            return "N/A"
        }
        
        let distance = calculateDistance(
            from: (userLat, userLon),
            to: (estLat, estLon)
        )
        
        return String(format: "%.1f", distance)
    }
    
    // MARK: - Helper Functions
    
    private func calculateDistance(from: (lat: Double, lon: Double), to: (lat: Double, lon: Double)) -> Double {
        let earthRadius: Double = 6371 // Radio de la Tierra en kilómetros
        
        let lat1Rad = from.lat * .pi / 180
        let lon1Rad = from.lon * .pi / 180
        let lat2Rad = to.lat * .pi / 180
        let lon2Rad = to.lon * .pi / 180
        
        let deltaLat = lat2Rad - lat1Rad
        let deltaLon = lon2Rad - lon1Rad
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
}

// MARK: - Vista de Mapa con Ubicación Específica

struct MapViewWithLocation: View {
    let establecimiento: lmpBDF_EstablecimientoLocal
    @EnvironmentObject private var locationService: LocationService
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var placemarkInfo: String = ""
    @State private var isLoadingAddress = false
    @State private var isPanelExpanded = true
    
    var body: some View {
        Map(position: $cameraPosition, interactionModes: .all) {
            // Pin del establecimiento específico
            if let lat = establecimiento.lat, let lon = establecimiento.lon {
                Annotation(establecimiento.nombre, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                        
                        Text(establecimiento.nombre)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 2)
                    }
                }
            }
            
            // Pin de tu ubicación actual
            if let userLat = locationService.latitude, let userLon = locationService.longitude {
                Annotation("Mi ubicación", coordinate: CLLocationCoordinate2D(latitude: userLat, longitude: userLon)) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 32, height: 32)
                        )
                        .shadow(radius: 3)
                }
            }
        }
        .mapControls { 
            MapCompass()
            MapPitchToggle()
            MapScaleView()
        }
        .navigationTitle(establecimiento.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        openInMaps()
                    } label: {
                        Label("Abrir en Apple Maps", systemImage: "map")
                    }
                    
                    Button {
                        openInMapsWalking()
                    } label: {
                        Label("Caminando", systemImage: "figure.walk")
                    }
                    
                    Button {
                        openInMapsTransit()
                    } label: {
                        Label("Transporte Público", systemImage: "bus")
                    }
                } label: {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            VStack(spacing: 12) {
                // Botón para abrir en Apple Maps
                Button {
                    openInMaps()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "car.fill")
                            .font(.title2)
                        Text("Ir")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.blue)
                            .shadow(radius: 4)
                    )
                }
                
                // Botón para centrar en el establecimiento
                Button {
                    centerOnEstablecimiento()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                        Text("Centrar")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.green)
                            .shadow(radius: 4)
                    )
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
        .overlay(alignment: .bottom) {
            // Panel de información del participante
            VStack(spacing: 0) {
                if isPanelExpanded {
                    VStack(spacing: 0) {
                        // Header del panel con botón de cerrar
                        HStack {
                            // Barra de arrastre
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(.secondary)
                                .frame(width: 36, height: 5)
                            
                            Spacer()
                            
                            // Botón de cerrar
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPanelExpanded = false
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Header con nombre y categoría
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(establecimiento.nombre)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    if let categoria = establecimiento.categoria, !categoria.isEmpty {
                                        HStack(spacing: 8) {
                                            Image(systemName: "tag.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(.blue)
                                            Text(categoria)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.blue)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.blue.opacity(0.1), in: Capsule())
                                    }
                                }
                                
                                // Información de ubicación
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "location.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.red)
                                        Text("Ubicación")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        if let municipio = establecimiento.municipio, !municipio.isEmpty {
                                            HStack(spacing: 8) {
                                                Image(systemName: "building.2.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                Text(municipio)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        
                                        if let estado = establecimiento.estado, !estado.isEmpty {
                                            HStack(spacing: 8) {
                                                Image(systemName: "flag.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                Text(estado)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        
                                        if let lat = establecimiento.lat, let lon = establecimiento.lon {
                                            HStack(spacing: 8) {
                                                Image(systemName: "globe")
                                                    .font(.caption)
                                                    .foregroundStyle(.tertiary)
                                                Text("\(String(format: "%.6f", lat)), \(String(format: "%.6f", lon))")
                                                    .font(.caption)
                                                    .foregroundStyle(.tertiary)
                                                    .fontDesign(.monospaced)
                                            }
                                        }
                                        
                                        // Dirección completa usando geocodificación inversa
                                        if !placemarkInfo.isEmpty {
                                            HStack(alignment: .top, spacing: 8) {
                                                Image(systemName: "map.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .padding(.top, 2)
                                                Text(placemarkInfo)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                                    .multilineTextAlignment(.leading)
                                            }
                                        } else if isLoadingAddress {
                                            HStack(spacing: 8) {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                Text("Obteniendo dirección...")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                                
                                // Información de contacto
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "phone.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.green)
                                        Text("Contacto")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "phone.fill")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("Información de contacto no disponible")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .italic()
                                    }
                                }
                                
                                // Horarios
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.orange)
                                        Text("Horarios")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock.fill")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("Información de horarios no disponible")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .italic()
                                    }
                                }
                                
                                // Distancia desde tu ubicación
                                if let userLat = locationService.latitude,
                                   let userLon = locationService.longitude,
                                   let estLat = establecimiento.lat,
                                   let estLon = establecimiento.lon {
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "location.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(.blue)
                                            Text("Distancia")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)
                                        }
                                        
                                        let distance = calculateDistance(
                                            from: (userLat, userLon),
                                            to: (estLat, estLon)
                                        )
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: "ruler.fill")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text("A \(String(format: "%.1f", distance)) km de tu ubicación")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        .frame(maxHeight: 350)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
                } else {
                    // Botón para expandir el panel
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPanelExpanded = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(establecimiento.nombre)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                
                                if let categoria = establecimiento.categoria, !categoria.isEmpty {
                                    Text(categoria)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.up")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .onAppear {
            centerOnEstablecimiento()
            loadAddressInfo()
        }
    }
    
    private func centerOnEstablecimiento() {
        guard let lat = establecimiento.lat, let lon = establecimiento.lon else { return }
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(region)
        }
    }
    
    private func openInMaps() {
        openInMapsWithMode(MKLaunchOptionsDirectionsModeDriving)
    }
    
    private func openInMapsWalking() {
        openInMapsWithMode(MKLaunchOptionsDirectionsModeWalking)
    }
    
    private func openInMapsTransit() {
        openInMapsWithMode(MKLaunchOptionsDirectionsModeTransit)
    }
    
    private func openInMapsWithMode(_ mode: String) {
        guard let lat = establecimiento.lat, let lon = establecimiento.lon else { return }
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        
        // Configurar el nombre del establecimiento
        mapItem.name = establecimiento.nombre
        
        // Configurar opciones de navegación según el modo
        var options: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: mode
        ]
        
        // Agregar tráfico solo para modo de conducción
        if mode == MKLaunchOptionsDirectionsModeDriving {
            options[MKLaunchOptionsShowsTrafficKey] = true
        }
        
        // Abrir en Apple Maps con direcciones
        mapItem.openInMaps(launchOptions: options)
    }
    
    private func loadAddressInfo() {
        guard let lat = establecimiento.lat, let lon = establecimiento.lon else { return }
        
        isLoadingAddress = true
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: lat, longitude: lon)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isLoadingAddress = false
                
                if let error = error {
                    print("Error en geocodificación inversa: \(error.localizedDescription)")
                    return
                }
                
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    
                    // Calle y número
                    if let streetNumber = placemark.subThoroughfare,
                       let streetName = placemark.thoroughfare {
                        addressComponents.append("\(streetName) \(streetNumber)")
                    } else if let streetName = placemark.thoroughfare {
                        addressComponents.append(streetName)
                    }
                    
                    // Colonia
                    if let subLocality = placemark.subLocality {
                        addressComponents.append(subLocality)
                    }
                    
                    // Ciudad
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    
                    // Estado
                    if let administrativeArea = placemark.administrativeArea {
                        addressComponents.append(administrativeArea)
                    }
                    
                    // Código postal
                    if let postalCode = placemark.postalCode {
                        addressComponents.append("CP \(postalCode)")
                    }
                    
                    // País
                    if let country = placemark.country {
                        addressComponents.append(country)
                    }
                    
                    self.placemarkInfo = addressComponents.joined(separator: ", ")
                }
            }
        }
    }
    
    private func calculateDistance(from: (lat: Double, lon: Double), to: (lat: Double, lon: Double)) -> Double {
        let earthRadius: Double = 6371 // Radio de la Tierra en kilómetros
        
        let lat1Rad = from.lat * .pi / 180
        let lon1Rad = from.lon * .pi / 180
        let lat2Rad = to.lat * .pi / 180
        let lon2Rad = to.lon * .pi / 180
        
        let deltaLat = lat2Rad - lat1Rad
        let deltaLon = lon2Rad - lon1Rad
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
}

#Preview {
    // Previsualización con datos de ejemplo
    let ejemplo = lmpBDF_EstablecimientoLocal(
        id: 101,
        nombre: "Cafetería Central",
        municipio: "Querétaro",
        estado: "QRO",
        categoria: "Restaurante",
        lat: 20.6,
        lon: -100.4,
        esFavorito: true
    )
    
    let locationService = LocationService()
    locationService.latitude = 20.6
    locationService.longitude = -100.4
    
    return ccp_UI_EstablecimientoRow(est: ejemplo)
        .environmentObject(locationService)
        .padding()
}
