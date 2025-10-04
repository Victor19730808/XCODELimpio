import Foundation
import SwiftData

/// Servicio de persistencia para `lmpBDF_EstablecimientoLocal`.
/// - Inserción/actualización incremental (no borra).
/// - Consultas por estado y conteos.
struct lmpBDF_LocalDBService {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    // MARK: - Inserción incremental (Upsert)
    @discardableResult
    func upsert(estabs: [Establecimiento]) throws -> Int {
        var changed = 0

        for r in estabs {
            // 1) Buscar si ya existe por ID
            let pred = #Predicate<lmpBDF_EstablecimientoLocal> { $0.id == r.establecimiento_id }
            var fd   = FetchDescriptor<lmpBDF_EstablecimientoLocal>(predicate: pred)
            fd.fetchLimit = 1
            let existing = try context.fetch(fd).first

            // 2) Mapear campos
            let nombre    = r.establecimiento_nombre
            let municipio = r.direccion_municipio
            let estado    = r.direccion_estado
            let categoria = r.categoria_nombre
            let lat       = r.direccion_latitud
            let lon       = r.direccion_longitud

            // 3) Insertar o actualizar
            if let e = existing {
                var didChange = false
                if e.nombre    != nombre    { e.nombre = nombre;       didChange = true }
                if e.municipio != municipio { e.municipio = municipio; didChange = true }
                if e.estado    != estado    { e.estado = estado;       didChange = true }
                if e.categoria != categoria { e.categoria = categoria; didChange = true }
                if e.lat       != lat       { e.lat = lat;             didChange = true }
                if e.lon       != lon       { e.lon = lon;             didChange = true }
                if didChange { changed += 1 }
            } else {
                let nuevo = lmpBDF_EstablecimientoLocal(
                    id: r.establecimiento_id,
                    nombre: nombre,
                    municipio: municipio,
                    estado: estado,
                    categoria: categoria,
                    lat: lat,
                    lon: lon
                )
                context.insert(nuevo)
                changed += 1
            }
        }

        if changed > 0 { try context.save() }
        return changed
    }

    // MARK: - Consultas
    func fetchByEstado(_ edo: String, limit: Int = 300) throws -> [lmpBDF_EstablecimientoLocal] {
        let pred = #Predicate<lmpBDF_EstablecimientoLocal> { ($0.estado ?? "") == edo }
        var fd   = FetchDescriptor<lmpBDF_EstablecimientoLocal>(predicate: pred)
        fd.fetchLimit = limit
        fd.sortBy = [SortDescriptor(\.nombre, comparator: .localizedStandard)]
        return try context.fetch(fd)
    }

    func countAll() throws -> Int {
        // En SwiftData no hace falta (ni existe) propertiesToFetch aquí.
        try context.fetch(FetchDescriptor<lmpBDF_EstablecimientoLocal>()).count
    }

    func deleteAll() throws {
        let all = try context.fetch(FetchDescriptor<lmpBDF_EstablecimientoLocal>())
        for e in all { context.delete(e) }
        try context.save()
    }
}
