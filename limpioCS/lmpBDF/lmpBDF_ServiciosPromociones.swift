//
//  lmpBDF_ServiciosPromociones.swift
//  LimpioCS
//
//  Servicio y modelo para consultar promociones por establecimiento.
//  Endpoint: https://canacocard-ms-backend.azurewebsites.net/api/evento/1/promociones/establecimiento/{id}
//
//  Requisitos: iOS 17+
//  Fecha: 2025-10-03
//

import Foundation

// MARK: - Modelo (fiel al JSON)
public struct PromocionWS: Identifiable, Decodable {
    // id requerido por SwiftUI
    public var id: Int { promocion_id }

    // Campos principales
    public let ev_id: Int?
    public let ev_nombre: String?
    public let establecimiento_id: Int
    public let establecimiento_nombre: String?
    public let categoria_nombre: String?
    public let promocion_id: Int
    public let promocion_titulo: String
    public let promocion_descripcion: String
    public let promocion_imagen: String?
    public let promocion_fi: String?
    public let promocion_ff: String?
    public let direccion_completa: String?

    // Si después quieres usar lat/lon, puedes agregarlos como String? y convertirlos a Double.
    // public let direccion_latitud: String?
    // public let direccion_longitud: String?
}

// MARK: - Servicio
public enum lmpBDF_ServiciosPromociones {
    private static let base = "https://canacocard-ms-backend.azurewebsites.net/api/evento/1/promociones/establecimiento/"

    /// Descarga promociones por establecimiento.
    /// - Parameter establecimientoId: id del establecimiento (Int).
    /// - Returns: Arreglo de `PromocionWS`.
    public static func fetchPromos(establecimientoId: Int) async throws -> [PromocionWS] {
        guard let url = URL(string: base + String(establecimientoId)) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw URLError(.badServerResponse)
        }

        // El endpoint devuelve un array de objetos
        let decoder = JSONDecoder()
        return try decoder.decode([PromocionWS].self, from: data)
    }
}
