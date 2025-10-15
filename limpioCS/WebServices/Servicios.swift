import Foundation

// Filtros para Establecimientos
struct FiltrosEstablecimientos {
    var municipio: String? = nil
    var estado: String? = nil
    var categoria: String? = nil
    var nombreContains: String? = nil   // <-- NUEVO: filtro por nombre de establecimiento
}

final class Servicios {
    private let api = APIClient()

    // MARK: - Utilidad de comparación
    private func containsCI(_ value: String?, _ needle: String?) -> Bool {
        guard let n = needle, !n.trimmingCharacters(in: .whitespaces).isEmpty else { return true }
        guard let v = value else { return false }
        return v.range(of: n, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    // MARK: - 1) Establecimientos con filtros locales
    func obtenerEstablecimientos(
        limit: Int = 10000,
        filtros: FiltrosEstablecimientos = FiltrosEstablecimientos()
    ) async throws -> [Establecimiento] {
        let todos = try await api.getEstablecimientos(limit: limit)
        return todos.filter { e in
            containsCI(e.direccion_municipio, filtros.municipio) &&
            containsCI(e.direccion_estado, filtros.estado) &&
            containsCI(e.categoria_nombre, filtros.categoria) &&
            containsCI(e.establecimiento_nombre, filtros.nombreContains)
        }
    }

    // MARK: - 2) Promociones por establecimiento con filtros locales en título/descr.
    func obtenerPromociones(
        establecimientoId: Int,
        tituloContains: String? = nil,
        descripcionContains: String? = nil
    ) async throws -> [Promocion] {
        let todos = try await api.getPromociones(establecimientoId: establecimientoId)
        return todos.filter { p in
            containsCI(p.promocion_titulo, tituloContains) &&
            containsCI(p.promocion_descripcion, descripcionContains)
        }
    }
}
