import Foundation

enum Endpoints {
    static let base = URL(string: "https://canacocard-ms-backend.azurewebsites.net")!
    static func establecimientos(eventoId: Int = 1, limit: Int = 10000) -> URL {
        base.appendingPathComponent("/api/evento/\(eventoId)/establecimientos/\(limit)")
    }
    static func promocionesPorEstablecimiento(eventoId: Int = 1, establecimientoId: Int) -> URL {
        base.appendingPathComponent("/api/evento/\(eventoId)/promociones/establecimiento/\(establecimientoId)")
    }
}
