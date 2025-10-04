import SwiftData

/// Modelo de datos local para la base incremental de establecimientos.
/// Cada registro representa un establecimiento único identificado por `id`.
/// Se acumulan registros de distintos estados conforme se visitan.
@Model
final class lmpBDF_EstablecimientoLocal {
    /// Identificador único (proviene del backend).
    @Attribute(.unique) var id: Int

    /// Nombre comercial del establecimiento.
    var nombre: String

    /// Municipio donde se encuentra (opcional).
    var municipio: String?

    /// Estado donde se encuentra (opcional).
    var estado: String?

    /// Categoría (ej. restaurante, librería, deportes).
    var categoria: String?

    /// Latitud geográfica.
    var lat: Double?

    /// Longitud geográfica.
    var lon: Double?

    /// 🔸 NUEVO: bandera de favorito
    var esFavorito: Bool = false

    /// Inicializador para crear un establecimiento local.
    init(
        id: Int,
        nombre: String,
        municipio: String? = nil,
        estado: String? = nil,
        categoria: String? = nil,
        lat: Double? = nil,
        lon: Double? = nil,
        esFavorito: Bool = false
    ) {
        self.id = id
        self.nombre = nombre
        self.municipio = municipio
        self.estado = estado
        self.categoria = categoria
        self.lat = lat
        self.lon = lon
        self.esFavorito = esFavorito
    }
}
