//
//  GV_GreatMap_Template.swift
//  Plantilla de mapa reusable (sin agregar al target por defecto)
//
//  Cómo usar:
//  1) Define tu modelo que cumpla con `GVMapEntity`.
//  2) Implementa el proveedor de datos (SwiftData, API, etc.) e inyéctalo en la vista.
//  3) Opcional: conecta gestores de categorías para color/ícono.
//

import SwiftUI
import MapKit

// Protocolo que tu entidad debe implementar para ser mapeable
public protocol GVMapEntity: Identifiable, Hashable {
    var id: Int { get }
    var nombre: String { get }
    var latitude: Double? { get }
    var longitude: Double? { get }
    var categoriaId: Int? { get }
    var categoriaNombre: String? { get }
    var urlSitio: String? { get }
}

// Estructura de estilo para categorías (color + ícono)
public struct GVCategoryStyle {
    public let color: Color
    public let icon: String
    public init(color: Color, icon: String) { self.color = color; self.icon = icon }
}

// Contrato para resolver estilo de categoría (por id o nombre)
public protocol GVCategoryStyler {
    func style(forCategoriaId id: Int?) -> GVCategoryStyle?
    func style(forCategoriaNombre nombre: String?) -> GVCategoryStyle?
}

// Proveedor de datos (inyectable)
public protocol GVMapDataProvider<Entity: GVMapEntity> {
    // Carga entidades para una región (puede incluir buffer interno)
    func fetch(in region: MKCoordinateRegion, limit: Int) async throws -> [Entity]
    // Búsqueda global por nombre (ordenamiento por distancia se hace en la vista si se le pasa la ubicación)
    func search(byName name: String, limit: Int) async throws -> [Entity]
}

public struct GV_GreatMap_Template<Entity: GVMapEntity>: View {
    // Dependencias
    private let dataProvider: any GVMapDataProvider<Entity>
    private let categoryStyler: (any GVCategoryStyler)?
    private let maxResults: Int

    // Estados
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var currentRegion: MKCoordinateRegion? = nil
    @State private var entities: [Entity] = []
    @State private var isLoading = false
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var searchResults: [Entity] = []
    @State private var selected: Entity? = nil

    public init(dataProvider: any GVMapDataProvider<Entity>,
                categoryStyler: (any GVCategoryStyler)? = nil,
                maxResults: Int = 300) {
        self.dataProvider = dataProvider
        self.categoryStyler = categoryStyler
        self.maxResults = maxResults
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                map
            }
        }
        .onAppear { cargarInicial() }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Mapa")
                    .font(.title2.bold())
                Spacer()
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                TextField("Buscar por nombre", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                if !searchText.isEmpty {
                    Button { searchText = ""; debouncedSearchText = ""; searchResults = [] } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
            .padding(10)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .onChange(of: searchText) { _, new in
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                debouncedSearchText = new
                await performSearch()
            }
        }
    }

    // MARK: - Map
    private var map: some View {
        Map(position: $cameraPosition) {
            ForEach(visibleData(), id: \._mapId) { item in
                if let lat = item.latitude, let lon = item.longitude {
                    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    Annotation(item.nombre, coordinate: coord) {
                        pin(for: item)
                            .onTapGesture { selected = item }
                    }
                }
            }
        }
        .onMapCameraChange { ctx in
            currentRegion = ctx.region
            Task { await loadRegion(ctx.region) }
        }
        .overlay(alignment: .bottom) {
            if !searchResults.isEmpty {
                resultsOverlay
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - UI helpers
    private func pin(for item: Entity) -> some View {
        let style = categoryStyler?.style(forCategoriaId: item.categoriaId) ??
                    categoryStyler?.style(forCategoriaNombre: item.categoriaNombre)
        let color = style?.color ?? .gray
        let icon = style?.icon ?? "mappin.circle.fill"
        return ZStack {
            Circle().fill(color.opacity(0.18)).frame(width: 44, height: 44)
            Circle().fill(color).frame(width: 40, height: 40)
            Circle().stroke(.white, lineWidth: 2).frame(width: 40, height: 40)
            Image(systemName: icon).foregroundColor(.white).font(.system(size: 18, weight: .bold))
        }
    }

    private var resultsOverlay: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(searchResults, id: \._mapId) { item in
                    Button {
                        if let lat = item.latitude, let lon = item.longitude {
                            let r = MKCoordinateRegion(center: .init(latitude: lat, longitude: lon),
                                                       span: .init(latitudeDelta: 0.05, longitudeDelta: 0.05))
                            withAnimation(.easeInOut(duration: 0.6)) { cameraPosition = .region(r) }
                        }
                        selected = item
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: categoryStyler?.style(forCategoriaId: item.categoriaId)?.icon ?? "tag.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(6)
                                .background((categoryStyler?.style(forCategoriaId: item.categoriaId)?.color ?? .gray))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.nombre).font(.caption).foregroundColor(.primary)
                                if let cat = item.categoriaNombre { Text(cat).font(.caption2).foregroundColor(.secondary) }
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: - Data
    private func cargarInicial() { if let region = currentRegion { Task { await loadRegion(region) } } }

    private func loadRegion(_ region: MKCoordinateRegion) async {
        guard !isLoading else { return }
        isLoading = true
        do {
            let data = try await dataProvider.fetch(in: region, limit: maxResults)
            await MainActor.run { entities = data; isLoading = false }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    private func performSearch() async {
        let term = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { searchResults = []; return }
        do {
            let data = try await dataProvider.search(byName: term, limit: maxResults)
            await MainActor.run { searchResults = data }
        } catch {
            await MainActor.run { searchResults = [] }
        }
    }

    private func visibleData() -> [Entity] {
        if !searchResults.isEmpty { return searchResults }
        return entities
    }
}

// Identidad estable
private extension GVMapEntity {
    var _mapId: String { "\(id)@\(latitude ?? 0)-\(longitude ?? 0)" }
}


