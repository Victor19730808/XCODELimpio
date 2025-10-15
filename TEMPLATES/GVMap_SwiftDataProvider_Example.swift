//
//  GVMap_SwiftDataProvider_Example.swift
//  Ejemplo mínimo de entidad SwiftData + DataProvider para la plantilla del mapa
//  (Archivo de ejemplo, no agregado al target por defecto)
//

import SwiftUI
import SwiftData
import MapKit

// MARK: - Ejemplo de entidad SwiftData
@Model
final class MyPlaceModel {
    @Attribute(.unique) var placeId: Int
    var name: String
    var latitude: Double?
    var longitude: Double?
    var categoryId: Int?
    var categoryName: String?
    var siteURL: String?

    init(placeId: Int,
         name: String,
         latitude: Double? = nil,
         longitude: Double? = nil,
         categoryId: Int? = nil,
         categoryName: String? = nil,
         siteURL: String? = nil) {
        self.placeId = placeId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.siteURL = siteURL
    }
}

// Conformidad a la interfaz del mapa
extension MyPlaceModel: GVMapEntity {
    public var id: Int { placeId }
    public var nombre: String { name }
    public var categoriaId: Int? { categoryId }
    public var categoriaNombre: String? { categoryName }
    public var urlSitio: String? { siteURL }
}

// MARK: - DataProvider basado en SwiftData
struct MyPlaceSwiftDataProvider: GVMapDataProvider {
    typealias Entity = MyPlaceModel
    let context: ModelContext

    func fetch(in region: MKCoordinateRegion, limit: Int) async throws -> [MyPlaceModel] {
        // 1) Traer con coordenadas no nulas y ordenar por nombre (límite)
        let predicate = #Predicate<MyPlaceModel> { $0.latitude != nil && $0.longitude != nil }
        var descriptor = FetchDescriptor<MyPlaceModel>(predicate: predicate,
                                                       sortBy: [SortDescriptor(\.name, comparator: .localizedStandard)])
        descriptor.fetchLimit = limit
        let all = try context.fetch(descriptor)
        // 2) Filtrar por bounding-box de la región (buffer ligero)
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        return all.filter { place in
            guard let lat = place.latitude, let lon = place.longitude else { return false }
            return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
        }
    }

    func search(byName name: String, limit: Int) async throws -> [MyPlaceModel] {
        let term = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return [] }
        // SwiftData no soporta contains con case-insensitive nativo, así que filtramos en memoria
        var descriptor = FetchDescriptor<MyPlaceModel>(sortBy: [SortDescriptor(\.name, comparator: .localizedStandard)])
        descriptor.fetchLimit = max(limit, 200)
        let all = try context.fetch(descriptor)
        return all.filter { $0.name.lowercased().contains(term) }
    }
}

// MARK: - Ejemplo de CategoryStyler
struct MyCategoryStyler: GVCategoryStyler {
    // Mapea id o nombre a color + ícono (SF Symbol)
    let styleById: [Int: GVCategoryStyle]
    let styleByName: [String: GVCategoryStyle]

    init(styleById: [Int: GVCategoryStyle] = [:], styleByName: [String: GVCategoryStyle] = [:]) {
        self.styleById = styleById
        self.styleByName = styleByName
    }

    func style(forCategoriaId id: Int?) -> GVCategoryStyle? {
        guard let id = id else { return nil }
        return styleById[id]
    }

    func style(forCategoriaNombre nombre: String?) -> GVCategoryStyle? {
        guard let n = nombre?.lowercased() else { return nil }
        return styleByName[n]
    }
}

// MARK: - Ejemplo de composición en una vista
struct MyPlacesMap_Preview: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        GV_GreatMap_Template<MyPlaceModel>(
            dataProvider: MyPlaceSwiftDataProvider(context: context),
            categoryStyler: MyCategoryStyler(
                styleById: [1: .init(color: .blue, icon: "building.2.fill")],
                styleByName: ["cafetería": .init(color: .brown, icon: "cup.and.saucer.fill")]
            ),
            maxResults: 300
        )
    }
}

#Preview {
    MyPlacesMap_Preview()
        .modelContainer(for: [MyPlaceModel.self])
}


