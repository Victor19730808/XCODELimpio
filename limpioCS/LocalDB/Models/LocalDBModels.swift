//
//  LocalDBModels.swift
//  CONSERVI2
//
//  Step 1: Modelo SwiftData para cache local de Establecimientos.
//  Este archivo puede vivir en cualquier target iOS 17+ con SwiftData habilitado.
//

import Foundation
import SwiftData

@Model
public final class EstablecimientoLocal {
    @Attribute(.unique) public var establecimientoId: Int
    public var nombre: String
    public var nombreNormalizado: String
    public var direccionCompleta: String?
    public var municipio: String?
    public var estado: String?
    public var lat: Double?
    public var lon: Double?
    public var categoriaId: Int?
    public var categoriaNombre: String?
    public var updatedAt: Date

    public init(establecimientoId: Int,
                nombre: String,
                direccionCompleta: String? = nil,
                municipio: String? = nil,
                estado: String? = nil,
                lat: Double? = nil,
                lon: Double? = nil,
                categoriaId: Int? = nil,
                categoriaNombre: String? = nil,
                updatedAt: Date = Date()) {
        self.establecimientoId = establecimientoId
        self.nombre = nombre
        self.nombreNormalizado = nombre.normalized()
        self.direccionCompleta = direccionCompleta
        self.municipio = municipio
        self.estado = estado
        self.lat = lat
        self.lon = lon
        self.categoriaId = categoriaId
        self.categoriaNombre = categoriaNombre
        self.updatedAt = updatedAt
    }
}

// MARK: - Normalización simple (ignora acentos y mayúsculas)
public extension String {
    func normalized() -> String {
        self.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}