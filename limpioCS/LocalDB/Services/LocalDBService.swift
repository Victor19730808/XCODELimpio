//
//  LocalDBService.swift (PATCH 4)
//  - DBAPIClient decodifica formato array y formato { data: [...] }.
//  - Errores con más detalle.
//

import Foundation
import SwiftUI
import SwiftData

public struct EstablecimientoRemote: Decodable {
    public let registro_evento_id: Int?
    public let establecimiento_id: Int
    public let establecimiento_nombre: String
    public let direccion_completa: String?
    public let direccion_municipio: String?
    public let direccion_estado: String?
    public let direccion_latitud: String?
    public let direccion_longitud: String?
    public let categoria_id: Int?
    public let categoria_nombre: String?
}

@MainActor
public final class LocalDBService {
    public let context: ModelContext
    public init(context: ModelContext) { self.context = context }

    @discardableResult
    public func upsert(estabs: [EstablecimientoRemote]) throws -> Int {
        var changed = 0
        for r in estabs {
            let eid = r.establecimiento_id
            if let existing = try fetchById(eid) {
                existing.nombre = r.establecimiento_nombre
                existing.nombreNormalizado = r.establecimiento_nombre.normalized()
                existing.direccionCompleta = r.direccion_completa
                existing.municipio = r.direccion_municipio
                existing.estado = r.direccion_estado
                existing.lat = Double(r.direccion_latitud ?? "")
                existing.lon = Double(r.direccion_longitud ?? "")
                existing.categoriaId = r.categoria_id
                existing.categoriaNombre = r.categoria_nombre
                existing.updatedAt = Date()
                changed += 1
            } else {
                let n = EstablecimientoLocal(
                    establecimientoId: eid,
                    nombre: r.establecimiento_nombre,
                    direccionCompleta: r.direccion_completa,
                    municipio: r.direccion_municipio,
                    estado: r.direccion_estado,
                    lat: Double(r.direccion_latitud ?? ""),
                    lon: Double(r.direccion_longitud ?? ""),
                    categoriaId: r.categoria_id,
                    categoriaNombre: r.categoria_nombre
                )
                context.insert(n); changed += 1
            }
        }
        try context.save()
        return changed
    }

    public func count() throws -> Int {
        try context.fetchCount(FetchDescriptor<EstablecimientoLocal>())
    }

    public func deleteAll() throws {
        let all = try context.fetch(FetchDescriptor<EstablecimientoLocal>())
        for e in all { context.delete(e) }
        try context.save()
    }

    public func fetchById(_ id: Int) throws -> EstablecimientoLocal? {
        var d = FetchDescriptor<EstablecimientoLocal>(
            predicate: #Predicate<EstablecimientoLocal> { $0.establecimientoId == id }
        )
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    public func search(nombreContains: String?,
                       municipio: String?,
                       estado: String?,
                       limit: Int = 200) throws -> [EstablecimientoLocal] {

        var d = FetchDescriptor<EstablecimientoLocal>(
            sortBy: [SortDescriptor(\EstablecimientoLocal.nombreNormalizado)]
        )
        d.fetchLimit = 5000
        var items = try context.fetch(d)

        if let v = nombreContains?.normalized(), !v.isEmpty {
            items = items.filter { $0.nombreNormalizado.contains(v) }
        }
        if let v = municipio?.normalized(), !v.isEmpty {
            items = items.filter { ($0.municipio ?? "").normalized().contains(v) }
        }
        if let v = estado?.normalized(), !v.isEmpty {
            items = items.filter { ($0.estado ?? "").normalized().contains(v) }
        }
        if items.count > limit { items = Array(items.prefix(limit)) }
        return items
    }
}

// MARK: - Descarga desde API genérica (coexiste con otros clientes)
public enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse(Int)
    case decoding(String)
    case emptyData

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida"
        case .invalidResponse(let code): return "HTTP no válido: \(code)"
        case .decoding(let msg): return "Error decodificando: \(msg)"
        case .emptyData: return "Respuesta vacía"
        }
    }
}

public struct DBAPIClient {
    public init() {}

    public func fetchEstablecimientos(from urlString: String) async throws -> [EstablecimientoRemote] {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.invalidResponse(-1) }
        guard (200..<300).contains(http.statusCode) else { throw APIError.invalidResponse(http.statusCode) }
        guard !data.isEmpty else { throw APIError.emptyData }

        // 1) Intenta decodificar array directo
        let decoder = JSONDecoder()
        if let arr = try? decoder.decode([EstablecimientoRemote].self, from: data) {
            return arr
        }

        // 2) Intenta { "data": [ ... ] }
        struct Wrapper: Decodable { let data: [EstablecimientoRemote] }
        if let w = try? decoder.decode(Wrapper.self, from: data) {
            return w.data
        }

        // 3) Si falla, arroja el string de ejemplo (primeros 500 chars) para diagnóstico
        let snippet = String(data: data.prefix(500), encoding: .utf8) ?? "bytes=\(data.count)"
        throw APIError.decoding("Formato inesperado. Inicio: \(snippet)")
    }
}