//
//  ccp_BDF_MapClustersView.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Cliente: Concanaco ServyTur
//  Performed by: Grupo VAL Human TECH
//
//  Descripción (mapa clusters + filtros + detalle simple):
//  ----------------------------------------------------------------
//  • Clustering nativo de MapKit (agrupa establecimientos cercanos con contador).
//  • Búsqueda global sobre toda la BD local (SIN radio).
//  • Filtros colapsables: Categorías (multi-select con toggles + chips), Nombre, Municipio, Estado.
//  • Sin etiquetas “flotantes” bajo pins/clusters (anti-parpadeo).
//  • Solo se actualizan anotaciones si cambia la lista filtrada (no por pan/zoom).
//  • Botones: Zoom (+/−), “Centrar en mí”, “Ver México”.
//  • Al tocar un pin individual → Sheet con detalle (SIN favoritos).
//
//  Requisitos: iOS 17+
//
//  Fecha: 2025-10-03
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

// MARK: - Vista principal

struct ccp_BDF_MapClustersView: View {

    // Dependencias
    @EnvironmentObject private var location: LocationService
    @Environment(\.modelContext) private var context

    /// SwiftData: todos los establecimientos locales (ordenados por nombre).
    @Query(sort: [SortDescriptor(\lmpBDF_EstablecimientoLocal.nombre, comparator: .localizedStandard)])
    private var todos: [lmpBDF_EstablecimientoLocal]

    // Filtros (SIN radio)
    @State private var filtroCategorias: Set<String> = []         // multi-select (vacío = todas)
    @State private var filtroNombre: String = ""
    @State private var filtroMunicipio: String = ""
    @State private var filtroEstado: String = ""

    // Mostrar/ocultar filtros
    @State private var mostrarFiltros: Bool = true
    @State private var showCategoriasSheet = false

    // Estado del mapa
    @State private var region: MKCoordinateRegion? = nil          // región visible (para zoom/recenter)

    // Selección para sheet de detalle
    @State private var seleccionado: lmpBDF_EstablecimientoLocal? = nil

    // Límites y factores de zoom
    private let minDelta: CLLocationDegrees = 0.002  // ~200 m
    private let maxDelta: CLLocationDegrees = 40.0   // país completo
    private let zoomInFactor: Double  = 0.6          // -40%
    private let zoomOutFactor: Double = 1.6          // +60%

    // “Ver México”
    private let mexicoCenter = CLLocationCoordinate2D(latitude: 23.6345, longitude: -102.5528)
    private let mexicoSpan   = MKCoordinateSpan(latitudeDelta: 28.0, longitudeDelta: 35.0)

    // Paleta fija (claves normalizadas)
    private let fixedPaletteNormalized: [String: Color] = [
        "restaurante": .red,
        "deportes": .blue,
        "libreria": .green,
        "moda": .purple,
        "electronica": .orange,
        "supermercado": .teal
    ]

    // Catálogo de categorías únicas (deduplicado por normalización)
    private var categoriasEnBD: [String] {
        let originales = todos
            .compactMap { $0.categoria?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return uniqueOriginalsByNormalized(originales, normalizer: normalizeCategory)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // Aplicar filtros (global, sin radio)
    private var filtrados: [lmpBDF_EstablecimientoLocal] {
        let categoriasSelNorm = Set(filtroCategorias.map(normalizeCategory))
        let nombre    = normalizeText(filtroNombre)
        let municipio = normalizeText(filtroMunicipio)
        let estado    = normalizeText(filtroEstado)

        return todos.filter { e in
            guard let _ = e.lat, let _ = e.lon else { return false }

            if !categoriasSelNorm.isEmpty {
                let catNorm = normalizeCategory(e.categoria)
                if catNorm.isEmpty || !categoriasSelNorm.contains(catNorm) { return false }
            }
            if !nombre.isEmpty && !normalizeText(e.nombre).contains(nombre) { return false }
            if !municipio.isEmpty && !normalizeText(e.municipio).contains(municipio) { return false }
            if !estado.isEmpty && !normalizeText(e.estado).contains(estado) { return false }

            return true
        }
    }

    var body: some View {
        VStack(spacing: 8) {

            // ---- Filtros (colapsables) ----
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Filtros").font(.headline)
                        Spacer()
                        Button {
                            withAnimation { mostrarFiltros.toggle() }
                        } label: {
                            Label(mostrarFiltros ? "Ocultar" : "Mostrar",
                                  systemImage: mostrarFiltros ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        }
                        .buttonStyle(.bordered)
                    }

                    if mostrarFiltros {
                        VStack(alignment: .leading, spacing: 10) {
                            // Categorías — botón abre sheet con toggles
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

                                // Chips con lo seleccionado (removibles)
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

                            // Texto libre
                            TextField("Nombre contiene…", text: $filtroNombre)
                                .textFieldStyle(.roundedBorder)
                            HStack {
                                TextField("Municipio contiene…", text: $filtroMunicipio)
                                    .textFieldStyle(.roundedBorder)
                                TextField("Estado contiene…", text: $filtroEstado)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Text("Mostrando: \(filtrados.count)  ·  En BD: \(todos.count)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            // ---- Mapa con CLUSTER (UIKit bridge) ----
            ClusterMap(
                items: filtrados,
                region: $region,
                colorResolver: { rawCat in
                    let key = normalizeCategory(rawCat)
                    if let ui = fixedUIColor(for: key) { return ui }
                    return hashedUIColor(from: key)
                },
                onSelect: { est in
                    self.seleccionado = est
                }
            )
            // Botones: Zoom, Ver México, Centrar en mí
            .overlay(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    Button { zoomIn() } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.title2.bold())
                            .padding(8)
                    }
                    .buttonStyle(.borderedProminent)

                    Button { zoomOut() } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.title2.bold())
                            .padding(8)
                    }
                    .buttonStyle(.bordered)

                    Button { zoomToMexico() } label: {
                        Label("", systemImage: "globe.americas.fill")
                            .labelStyle(.iconOnly)
                            .font(.title2.bold())
                            .padding(8)
                    }
                    .buttonStyle(.bordered)
                    .help("Ver toda la República")
                }
                .padding(.top, 12)
                .padding(.trailing, 12)
            }
            .overlay(alignment: .bottomTrailing) {
                VStack(spacing: 8) {
                    Button { recenterOnUser() } label: {
                        Label("Centrar en mí", systemImage: "location.circle.fill")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .frame(minHeight: 320)
        }
        .padding()
        .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }
        .onAppear {
            if let lat = location.latitude, let lon = location.longitude {
                region = MKCoordinateRegion(center: .init(latitude: lat, longitude: lon),
                                            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
            } else {
                zoomToMexico()
            }
        }
        .sheet(item: $seleccionado) { est in
            EstablecimientoDetalleSheetSimple(est: est)
                .environment(\.modelContext, context)
                .presentationDetents([.fraction(0.35), .medium])
        }
        .sheet(isPresented: $showCategoriasSheet) {
            CategoriaToggleSheet(
                categorias: categoriasEnBD,
                seleccion: $filtroCategorias
            )
        }
    }

    // MARK: - Normalización/utilidades

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

    // Convertidores Color → UIColor
    private func fixedUIColor(for normalizedKey: String) -> UIColor? {
        if let c = fixedPaletteNormalized[normalizedKey] {
            return UIColor(c)
        }
        return nil
    }
    private func hashedUIColor(from text: String) -> UIColor {
        guard !text.isEmpty else { return UIColor.gray }
        var hasher = Hasher(); hasher.combine(text)
        let hue = CGFloat(abs(hasher.finalize() % 360)) / 360.0
        return UIColor(hue: hue, saturation: 0.65, brightness: 0.85, alpha: 1)
    }

    // MARK: - Zoom & recenter

    private func zoomIn() {
        guard var r = region else { return }
        r.span.latitudeDelta  = max(minDelta, r.span.latitudeDelta  * zoomInFactor)
        r.span.longitudeDelta = max(minDelta, r.span.longitudeDelta * zoomInFactor)
        withAnimation { region = r }
    }

    private func zoomOut() {
        guard var r = region else { return }
        r.span.latitudeDelta  = min(maxDelta, r.span.latitudeDelta  * zoomOutFactor)
        r.span.longitudeDelta = min(maxDelta, r.span.longitudeDelta * zoomOutFactor)
        withAnimation { region = r }
    }

    private func zoomToMexico() {
        let r = MKCoordinateRegion(center: mexicoCenter, span: mexicoSpan)
        withAnimation { region = r }
    }

    private func recenterOnUser() {
        guard let lat = location.latitude, let lon = location.longitude else { return }
        var r = region ?? MKCoordinateRegion(center: .init(latitude: lat, longitude: lon),
                                             span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        r.center = .init(latitude: lat, longitude: lon)
        withAnimation { region = r }
    }
}

//
// MARK: - SHEET: Detalle simple (sin favoritos)
//



//
// MARK: - SHEET: Multi-selección de categorías con toggles
//

private struct CategoriaToggleSheet: View {
    let categorias: [String]
    @Binding var seleccion: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Todas las categorías", isOn: Binding(
                        get: { seleccion.isEmpty },
                        set: { isOn in if isOn { seleccion.removeAll() } }
                    ))
                }

                Section("Selecciona una o varias") {
                    ForEach(categorias, id: \.self) { cat in
                        Toggle(isOn: Binding(
                            get: { seleccion.contains(cat) },
                            set: { val in
                                if val { seleccion.insert(cat) }
                                else { seleccion.remove(cat) }
                            }
                        )) { Text(cat) }
                    }
                }
            }
            .navigationTitle("Categorías")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Limpiar") { seleccion.removeAll() } // vuelve a "Todas"
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        seleccion = Set(categorias)
                    } label: {
                        Label("Seleccionar todas", systemImage: "checkmark.circle.badge.plus")
                    }
                }
            }
        }
    }
}

//
// MARK: - UIViewRepresentable con MKMapView y clustering (anti-parpadeo)
//

struct ClusterMap: UIViewRepresentable {
    let items: [lmpBDF_EstablecimientoLocal]
    @Binding var region: MKCoordinateRegion?

    /// Resuelve el color (UIColor) en función de la categoría (raw string).
    let colorResolver: (String?) -> UIColor

    /// Callback cuando el usuario toca un pin individual.
    let onSelect: (lmpBDF_EstablecimientoLocal) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.pointOfInterestFilter = .excludingAll
        map.isRotateEnabled = true
        map.isPitchEnabled = true

        map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "pin")
        map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "cluster")

        if let region { map.setRegion(region, animated: false) }

        context.coordinator.setAnnotations(on: map, items: items)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        if let region { map.setRegion(region, animated: false) }
        context.coordinator.updateAnnotationsIfNeeded(on: map, newItems: items)

        let newRegion = map.region
        let needsRegionUpdate =
            region?.center.latitude != newRegion.center.latitude ||
            region?.center.longitude != newRegion.center.longitude ||
            region?.span.latitudeDelta != newRegion.span.latitudeDelta ||
            region?.span.longitudeDelta != newRegion.span.longitudeDelta
        if needsRegionUpdate {
            DispatchQueue.main.async { region = newRegion }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, colorResolver: colorResolver, onSelect: onSelect)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private let parent: ClusterMap
        private let colorResolver: (String?) -> UIColor
        private let onSelect: (lmpBDF_EstablecimientoLocal) -> Void
        private var currentIDs: Set<Int> = []

        init(parent: ClusterMap,
             colorResolver: @escaping (String?) -> UIColor,
             onSelect: @escaping (lmpBDF_EstablecimientoLocal) -> Void) {
            self.parent = parent
            self.colorResolver = colorResolver
            self.onSelect = onSelect
        }

        func setAnnotations(on map: MKMapView, items: [lmpBDF_EstablecimientoLocal]) {
            let anns = buildAnnotations(from: items)
            currentIDs = Set(anns.map { $0.estabID })
            map.addAnnotations(anns)
        }

        func updateAnnotationsIfNeeded(on map: MKMapView, newItems: [lmpBDF_EstablecimientoLocal]) {
            let newAnns = buildAnnotations(from: newItems)
            let newIDs  = Set(newAnns.map { $0.estabID })
            guard newIDs != currentIDs else { return }

            let toRemove = map.annotations.compactMap { ann -> MKAnnotation? in
                if let a = ann as? EstabAnnotation, !newIDs.contains(a.estabID) { return a }
                return nil
            }
            if !toRemove.isEmpty { map.removeAnnotations(toRemove) }

            let existingIDs = Set(map.annotations.compactMap { ($0 as? EstabAnnotation)?.estabID })
            let missing = newAnns.filter { !existingIDs.contains($0.estabID) }
            if !missing.isEmpty { map.addAnnotations(missing) }

            currentIDs = newIDs
        }

        private func buildAnnotations(from items: [lmpBDF_EstablecimientoLocal]) -> [EstabAnnotation] {
            items.compactMap { e in
                guard let lat = e.lat, let lon = e.lon else { return nil }
                return EstabAnnotation(
                    estabID: Int(e.id),
                    title: e.nombre,
                    subtitle: e.categoria ?? "",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    categoryRaw: e.categoria,
                    source: e
                )
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if let cluster = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "cluster", for: annotation) as! MKMarkerAnnotationView
                view.displayPriority = .defaultHigh
                view.markerTintColor = UIColor.systemIndigo
                view.glyphText = "\(cluster.memberAnnotations.count)"
                view.titleVisibility = .hidden
                view.subtitleVisibility = .hidden
                view.canShowCallout = false
                view.animatesWhenAdded = false
                return view
            }

            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "pin", for: annotation) as! MKMarkerAnnotationView
            if let estabAnn = annotation as? EstabAnnotation {
                view.clusteringIdentifier = "estab"
                view.markerTintColor = colorResolver(estabAnn.categoryRaw)
                view.titleVisibility = .hidden
                view.subtitleVisibility = .hidden
                view.canShowCallout = true
                view.animatesWhenAdded = false
            }
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // CLUSTER → auto-zoom a sus miembros
            if let cluster = view.annotation as? MKClusterAnnotation {
                mapView.showAnnotations(cluster.memberAnnotations, animated: true)
                return
            }
            // PIN individual → notificar selección al parent para abrir sheet
            if let estabAnn = view.annotation as? EstabAnnotation {
                onSelect(estabAnn.source)
            }
        }
    }
}

//
// MARK: - Modelo de anotación
//

final class EstabAnnotation: NSObject, MKAnnotation {
    let estabID: Int
    let titleText: String
    let subtitleText: String
    let categoryRaw: String?
    let source: lmpBDF_EstablecimientoLocal   // referencia al modelo original

    dynamic var coordinate: CLLocationCoordinate2D
    var title: String? { titleText }
    var subtitle: String? { subtitleText }

    init(estabID: Int,
         title: String,
         subtitle: String,
         coordinate: CLLocationCoordinate2D,
         categoryRaw: String?,
         source: lmpBDF_EstablecimientoLocal) {
        self.estabID = estabID
        self.titleText = title
        self.subtitleText = subtitle
        self.coordinate = coordinate
        self.categoryRaw = categoryRaw
        self.source = source
        super.init()
    }
}

//
// MARK: - Helper UI (chips multilínea)
//

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

//
// MARK: - Utilidades
//

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

private func normalizeText(_ raw: String?) -> String {
    (raw ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(options: .diacriticInsensitive, locale: .current)
        .lowercased()
}
private func normalizeCategory(_ raw: String?) -> String { normalizeText(raw) }
