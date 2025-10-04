import Foundation

struct APIClient {
    enum APIError: Error { case network(Error), decoding(Error), badStatus(Int) }

    func getEstablecimientos(limit: Int = 10000) async throws -> [Establecimiento] {
        let url = Endpoints.establecimientos(limit: limit)
        return try await fetch(url, as: [Establecimiento].self)
    }

    func getPromociones(establecimientoId: Int) async throws -> [Promocion] {
        let url = Endpoints.promocionesPorEstablecimiento(establecimientoId: establecimientoId)
        return try await fetch(url, as: [Promocion].self)
    }

    private func fetch<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard 200..<300 ~= http.statusCode else { throw APIError.badStatus(http.statusCode) }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch {
            throw APIError.network(error)
        }
    }
}
