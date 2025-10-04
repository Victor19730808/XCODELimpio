import Foundation

struct Establecimiento: Codable, Identifiable {
    var id: Int { establecimiento_id }
    let registro_evento_id: Int
    let establecimiento_id: Int
    let establecimiento_nombre: String
    let direccion_completa: String?
    let direccion_municipio: String?
    let direccion_estado: String?
    let categoria_id: Int?
    let categoria_nombre: String?
    let direccion_latitud: Double?
    let direccion_longitud: Double?

    enum CodingKeys: String, CodingKey {
        case registro_evento_id, establecimiento_id, establecimiento_nombre, direccion_completa,
             direccion_municipio, direccion_estado, direccion_latitud, direccion_longitud,
             categoria_id, categoria_nombre
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        registro_evento_id = try c.decode(Int.self, forKey: .registro_evento_id)
        establecimiento_id = try c.decode(Int.self, forKey: .establecimiento_id)
        establecimiento_nombre = (try? c.decode(String.self, forKey: .establecimiento_nombre))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        direccion_completa = try? c.decode(String.self, forKey: .direccion_completa)
        direccion_municipio = (try? c.decode(String.self, forKey: .direccion_municipio))?.trimmingCharacters(in: .whitespacesAndNewlines)
        direccion_estado = try? c.decode(String.self, forKey: .direccion_estado)
        categoria_id = try? c.decode(Int.self, forKey: .categoria_id)
        categoria_nombre = try? c.decode(String.self, forKey: .categoria_nombre)
        func toDouble(_ key: CodingKeys) -> Double? {
            if let d = try? c.decode(Double.self, forKey: key) { return d }
            if let s = try? c.decode(String.self, forKey: key) { return Double(s.trimmingCharacters(in: .whitespacesAndNewlines)) }
            return nil
        }
        direccion_latitud = toDouble(.direccion_latitud)
        direccion_longitud = toDouble(.direccion_longitud)
    }
}

struct Promocion: Codable, Identifiable {
    var id: Int { promocion_id ?? establecimiento_id }
    let ev_id: Int?
    let ev_nombre: String?
    let establecimiento_id: Int
    let establecimiento_nombre: String?
    let categoria_id: Int?
    let categoria_nombre: String?
    let promocion_id: Int?
    let promocion_titulo: String?
    let promocion_descripcion: String?
    let promocion_imagen: String?
    let direccion_completa: String?
    let direccion_latitud: Double?
    let direccion_longitud: Double?

    enum CodingKeys: String, CodingKey {
        case ev_id, ev_nombre, establecimiento_id, establecimiento_nombre, categoria_id, categoria_nombre,
             promocion_id, promocion_titulo, promocion_descripcion, promocion_imagen,
             direccion_completa, direccion_latitud, direccion_longitud
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ev_id = try? c.decode(Int.self, forKey: .ev_id)
        ev_nombre = try? c.decode(String.self, forKey: .ev_nombre)
        establecimiento_id = (try? c.decode(Int.self, forKey: .establecimiento_id)) ?? 0
        establecimiento_nombre = try? c.decode(String.self, forKey: .establecimiento_nombre)
        categoria_id = try? c.decode(Int.self, forKey: .categoria_id)
        categoria_nombre = try? c.decode(String.self, forKey: .categoria_nombre)
        promocion_id = try? c.decode(Int.self, forKey: .promocion_id)
        promocion_titulo = try? c.decode(String.self, forKey: .promocion_titulo)
        promocion_descripcion = try? c.decode(String.self, forKey: .promocion_descripcion)
        promocion_imagen = try? c.decode(String.self, forKey: .promocion_imagen)
        direccion_completa = try? c.decode(String.self, forKey: .direccion_completa)
        func toDouble(_ key: CodingKeys) -> Double? {
            if let d = try? c.decode(Double.self, forKey: key) { return d }
            if let s = try? c.decode(String.self, forKey: key) { return Double(s.trimmingCharacters(in: .whitespacesAndNewlines)) }
            return nil
        }
        direccion_latitud = toDouble(.direccion_latitud)
        direccion_longitud = toDouble(.direccion_longitud)
    }
}
