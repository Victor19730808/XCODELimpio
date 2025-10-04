//
//  ccp_BDF_MapView.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Cliente: Concanaco ServyTur
//  Performed by: Grupo VAL Human TECH
//
//  Versión: Radio solo desde el **centro del mapa** + **Botones de Zoom** (+/−)
//  --------------------------------------------------------------------------
//  • Radio 1 … 50 km medido SIEMPRE desde el centro de la pantalla.
//  • Filtros: Categorías (multi-select; comparación normalizada) + Búsqueda por nombre.
//  • Mapa: pin de usuario (referencia visual), mira (crosshair) permanente en el centro,
//          colores por categoría (paleta fija + fallback hash), y **botones de zoom**.
//  • Los botones de zoom actúan sobre la región visible (span) sin perder el centro.
//
//  Fecha: 2025-10-02
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct ccp_BDF_MapView: View {

    // Dependencias
    @EnvironmentObject private var location: LocationService

    /// Consulta a SwiftData: todos los establecimientos locales ordenados por nombre.
    @Query(sort: [SortDescriptor(\lmpBDF_EstablecimientoLocal.nombre, comparator: .localizedStandard)])
    private var todos: [lmpBDF_EstablecimientoLocal]

    // Estado UI / Mapa
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selected: lmpBDF_EstablecimientoLocal? = nil
    @State private var mapCenter: CLLocationCoordinate2D? = nil
    @State private var currentRegion: MKCoordinateRegion? = nil   // región visible actual (para zoom)
    @State private var didAutocenter = false

    // Filtros
    @State private var filtroRadioKm: Double = 10               // radio (km) SIEMPRE desde el centro del mapa
    @State private var filtroCategorias: Set<String> = []       // multi-select (vacío = todas)
    @State private var filtroNombre: String = ""
    @State private var showCategoriasSheet = false

    // Rango del radio
    private let radioMin: Double = 1
    private let radioMax: Double = 50

    // Límites de zoom (span) — más pequeño = más cerca
    private let minDelta: CLLocationDegrees = 0.002  // ~200 m
    private let maxDelta: CLLocationDegrees = 40.0   // país completo aprox.
    private let zoomInFactor: Double  = 0.6          // cada toque reduce ~40% el área
    private let zoomOutFactor: Double = 1.6          // cada toque aumenta ~60% el área

    // Paleta fija (claves normalizadas)
    private let fixedPaletteNormalized: [String: Color] = [
        "restaurante": .red,
        "deportes": .blue,
        "libreria": .green,
        "moda": .purple,
        "electronica": .orange,
        "supermercado": .teal
    ]
    @State private var reportedUnknowns: Set<String> = []

    // Catálogo de categorías (deduplicado por normalización; muestra el primer original)
    private var categoriasEnBD: [String] {
        let originales = todos
            .compactMap { $0.categoria?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return uniqueOriginalsByNormalized(originales, normalizer: normalizeCategory)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // Filtro compuesto (categorías, nombre, radio desde el centro del mapa)
    private var filtrados: [lmpBDF_EstablecimientoLocal] {
        let categoriasSelNorm = Set(filtroCategorias.map(normalizeCategory))
        let nombre = filtroNombre.trimmingCharacters(in: .whitespacesAndNewlines)

        return todos.filter { e in
            guard let lat = e.lat, let lon = e.lon else { return false }

            // Categorías (multi-select, normalizadas)
            if !categoriasSelNorm.isEmpty {
                let catNorm = normalizeCategory(e.categoria)
                if catNorm.isEmpty || !categoriasSelNorm.contains(catNorm) { return false }
            }

            // Nombre contiene
            if !nombre.isEmpty && !e.nombre.localizedCaseInsensitiveContains(nombre) { return false }

            // Radio desde centro del mapa (si ya lo tenemos)
            if let center = mapCenter {
                let d = distanceKm(lat1: center.latitude, lon1: center.longitude, lat2: lat, lon2: lon)
                if d > filtroRadioKm { return false }
            }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 8) {

            // Filtros
            GroupBox("Filtros") {
                VStack(alignment: .leading, spacing: 10) {

                    // Slider del radio (rango 1…50 km) — SIEMPRE desde el centro del mapa
                    HStack {
                        Text("Radio: \(Int(filtroRadioKm)) km")
                        Slider(value: $filtroRadioKm, in: radioMin...radioMax, step: 1)
                    }
                    if mapCenter == nil {
                        Text("Mueve el mapa para fijar el centro (ancla del radio).")
                            .font(.footnote).foregroundStyle(.secondary)
                    }

                    // Categorías (multi-select)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Categorías:")
                            Button { showCategoriasSheet = true } label: {
                                if filtroCategorias.isEmpty {
                                    Label("Todas", systemImage: "line.3.horizontal.decrease.circle")
                                } else {
                                    Label("\(filtroCategorias.count) seleccionadas", systemImage: "line.3.horizontal.decrease.circle")
                                }
                            }
                            .buttonStyle(.bordered)
                        }

                        if !filtroCategorias.isEmpty {
                            WrapChips(items: Array(filtroCategorias).sorted()) { cat in
                                HStack(spacing: 6) {
                                    Text(cat).font(.caption)
                                    Button { filtroCategorias.remove(cat) } label: {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(.thinMaterial)
                                .clipShape(Capsule())
                            }
                            .padding(.top, 2)
                        }
                    }

                    // Búsqueda por nombre
                    TextField("Nombre contiene…", text: $filtroNombre)
                        .textFieldStyle(.roundedBorder)

                    Text("Mostrando: \(filtrados.count)  ·  En BD: \(todos.count)")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            // Mapa
            Map(position: $cameraPosition, interactionModes: .all) {
                // Pin de usuario personalizado (referencia visual)
                if let lat = location.latitude, let lon = location.longitude {
                    Annotation("Mi ubicación", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                        Image(systemName: "location.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundStyle(.blue)
                            .shadow(radius: 3)
                    }
                }

                // Establecimientos filtrados
                ForEach(filtrados) { e in
                    if let lat = e.lat, let lon = e.lon {
                        let color = colorForCategory(e.categoria)
                        Annotation(e.nombre, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            Button { selected = e } label: {
                                ZStack {
                                    Circle().fill(color).frame(width: 18, height: 18)
                                    Circle().stroke(.white, lineWidth: 2).frame(width: 18, height: 18)
                                }
                                .shadow(radius: 2)
                            }
                        }
                    }
                }
            }
            // Capturamos el centro y la región del mapa (iOS 17+)
            .onMapCameraChange { context in
                mapCenter = context.region.center
                currentRegion = context.region
            }
            .mapControls { MapCompass(); MapPitchToggle(); MapScaleView() }

            // Mira SIEMPRE visible (el radio se mide desde aquí)
            .overlay(alignment: .center) {
                CrosshairOverlay().allowsHitTesting(false)
            }

            // Botones de Zoom (+ / −)
            .overlay(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    Button {
                        zoomIn()
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.title2.bold())
                            .padding(8)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        zoomOut()
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.title2.bold())
                            .padding(8)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 12)
                .padding(.trailing, 12)
            }

            // Acciones rápidas (centrar a mi ubicación; NO afecta el origen del radio)
            .overlay(alignment: .bottomTrailing) {
                VStack(spacing: 8) {
                    Button { recenter() } label: {
                        Label("Centrar en mí", systemImage: "location.circle.fill").labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderedProminent)
                    MapUserLocationButton()
                }
                .padding()
            }
            .frame(minHeight: 320)
        }
        .padding()
        .navigationTitle("Mapa (BD local)")
        .onAppear {
            location.start() // Permite mostrar el pin de usuario y autocentrar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { autoCenterIfPossible() }
        }
        // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        // Usar la vista reusabe EstablecimientoDetalleSheetSimple
        .sheet(item: $selected) { est in
            EstablecimientoDetalleSheetSimple(est: est)
                .presentationDetents([.fraction(0.35), .medium])
        }
        // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        .sheet(isPresented: $showCategoriasSheet) {
            CategoriaMultiSelectSheet(
                todasLasCategorias: categoriasEnBD,
                seleccion: $filtroCategorias
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Normalización y utilidades

    private func normalizeText(_ raw: String?) -> String {
        (raw ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }
    private func normalizeCategory(_ raw: String?) -> String { normalizeText(raw) }

    private func uniqueOriginalsByNormalized(_ values: [String], normalizer: (String?) -> String) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for v in values {
            let key = normalizer(v)
            if key.isEmpty { continue }
            if !seen.contains(key) {
                seen.insert(key)
                result.append(v)
            }
        }
        return result
    }

    // Colores por categoría con fallback hash
    private func colorForCategory(_ raw: String?) -> Color {
        let key = normalizeCategory(raw)
        if let fixed = fixedPaletteNormalized[key] { return fixed }
        if !key.isEmpty && !reportedUnknowns.contains(key) {
            reportedUnknowns.insert(key)
            print("🧩 Categoría sin paleta fija (hash color): '\(raw ?? "")' → normalizada '\(key)'")
        }
        return hashedColor(from: key)
    }
    private func hashedColor(from text: String) -> Color {
        guard !text.isEmpty else { return .gray }
        var hasher = Hasher(); hasher.combine(text)
        let hue = Double(abs(hasher.finalize() % 360)) / 360.0
        return Color(hue: hue, saturation: 0.65, brightness: 0.85)
    }

    // MARK: - Zoom helpers

    private func zoomIn() {
        guard var region = currentRegion ?? defaultRegionFromCenter() else { return }
        region.span.latitudeDelta  = max(minDelta, region.span.latitudeDelta  * zoomInFactor)
        region.span.longitudeDelta = max(minDelta, region.span.longitudeDelta * zoomInFactor)
        withAnimation { cameraPosition = .region(region) }
        currentRegion = region
    }

    private func zoomOut() {
        guard var region = currentRegion ?? defaultRegionFromCenter() else { return }
        region.span.latitudeDelta  = min(maxDelta, region.span.latitudeDelta  * zoomOutFactor)
        region.span.longitudeDelta = min(maxDelta, region.span.longitudeDelta * zoomOutFactor)
        withAnimation { cameraPosition = .region(region) }
        currentRegion = region
    }

    private func defaultRegionFromCenter() -> MKCoordinateRegion? {
        guard let c = mapCenter else { return nil }
        return MKCoordinateRegion(center: c,
                                  span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
    }

    // MARK: - Mapa: centrado/auto-centrado y distancia

    private func autoCenterIfPossible() {
        guard !didAutocenter else { return }
        if let lat = location.latitude, let lon = location.longitude {
            let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = MKCoordinateRegion(center: center,
                                            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
            cameraPosition = .region(region)
            currentRegion = region
            didAutocenter = true
        }
    }

    private func recenter() {
        if let lat = location.latitude, let lon = location.longitude {
            let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = MKCoordinateRegion(center: center,
                                            span: currentRegion?.span ?? MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
            withAnimation { cameraPosition = .region(region) }
            currentRegion = region
        }
    }

    private func distanceKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
}

// MARK: - Overlay: mira en el centro del mapa
/// Crosshair permanente que indica el centro del mapa (ancla del radio).
private struct CrosshairOverlay: View {
    var body: some View {
        ZStack {
            Circle().strokeBorder(.blue.opacity(0.5), lineWidth: 2).frame(width: 24, height: 24)
            Circle().fill(.blue.opacity(0.15)).frame(width: 8, height: 8)
        }.shadow(radius: 1)
    }
}

// MARK: - Helper UI: chips con flujo a múltiples líneas
private struct WrapChips<ItemView: View>: View {
    let items: [String]
    let chip: (String) -> ItemView
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in generateContent(in: geometry) }
            .frame(height: totalHeight)
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                chip(item)
                    .padding(.trailing, 6)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > g.size.width) { width = 0; height -= d.height }
                        let result = width
                        if item == items.last { width = 0 } else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { d in
                        let result = height
                        if item == items.last { height = 0 }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo -> Color in
            DispatchQueue.main.async { binding.wrappedValue = geo.size.height }
            return .clear
        }
    }
}

// MARK: - Hoja: selección múltiple de categorías
private struct CategoriaMultiSelectSheet: View {
    let todasLasCategorias: [String]
    @Binding var seleccion: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        seleccion.removeAll() // Todas
                    } label: {
                        Label("Todas las categorías", systemImage: seleccion.isEmpty ? "checkmark.circle.fill" : "circle")
                    }
                }
                Section("Selecciona una o varias") {
                    ForEach(todasLasCategorias, id: \.self) { cat in
                        Button {
                            toggle(cat)
                        } label: {
                            HStack {
                                Text(cat)
                                Spacer()
                                Image(systemName: seleccion.contains(cat) ? "checkmark.circle.fill" : "circle")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Categorías")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Limpiar") { seleccion.removeAll() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Listo") { dismiss() } }
            }
        }
    }

    private func toggle(_ cat: String) {
        if seleccion.contains(cat) { seleccion.remove(cat) } else { seleccion.insert(cat) }
    }
}
