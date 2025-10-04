import Foundation
import CoreLocation
import Combine

/// Servicio centralizado de ubicación para toda la app.
/// - iOS < 26  → CLGeocoder (CoreLocation)
/// - iOS ≥ 26  → Reverse geocoding HTTP (Nominatim/OSM)
@MainActor
public final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Estado público
    @Published public var latitude: Double?
    @Published public var longitude: Double?
    @Published public var estado: String = ""
    @Published public var municipio: String = ""
    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var lastLog: String = "—"

    // MARK: - Config ajustable
    /// Segundos mínimos entre consultas de reverse geocoding (throttle).
    public var minRGInterval: TimeInterval = 2.0
    /// Distancia mínima en metros para volver a consultar.
    public var minMoveMeters: CLLocationDistance = 50
    /// Precisión del cache (número de decimales de lat/lon).
    public var cachePrecisionDigits: Int = 4
    /// Idioma preferido en Nominatim (p. ej. "es", "es-MX", "en").
    public var acceptLanguage: String = "es"
    /// Identidad del cliente para Nominatim (requerido).
    public var userAgent: String = "CONSERVI2/1.0 (soporte@tuempresa.com)"

    // MARK: - Internos
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()         // solo para iOS < 26
    private var hasStarted = false

    // Throttle / movimiento
    private var lastRGAt: Date?
    private var lastRGCoord: CLLocationCoordinate2D?

    // Cache (memoria + disco)
    private struct CacheValue: Codable { let state: String; let municipality: String }
    private var cache: [String: CacheValue] = [:]
    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("reverse_geo_cache.json")
    }

    // MARK: - Init
    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        // Carga cache de disco (rápido; dataset pequeño)
        if let data = try? Data(contentsOf: cacheURL),
           let map = try? JSONDecoder().decode([String: CacheValue].self, from: data) {
            self.cache = map
        }
    }

    // MARK: - API
    public func start() {
        guard !hasStarted else {
            manager.startUpdatingLocation()
            manager.requestLocation()
            return
        }
        hasStarted = true

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            manager.requestLocation()
        case .restricted, .denied:
            lastLog = "Permisos restringidos/denegados."
        @unknown default:
            break
        }
    }

    public func snapshotString() -> String {
        let lat = latitude != nil ? String(format: "%.6f", latitude!) : "nil"
        let lon = longitude != nil ? String(format: "%.6f", longitude!) : "nil"
        let est = estado.isEmpty ? "nil" : estado
        let mun = municipio.isEmpty ? "nil" : municipio
        return "Lat: \(lat), Lon: \(lon), Estado: \(est), Municipio: \(mun)"
    }

    /// Limpia el cache (memoria + disco).
    public func clearCache() {
        cache.removeAll()
        try? FileManager.default.removeItem(at: cacheURL)
        lastLog = "Cache de reverse geocoding eliminado."
    }

    // MARK: - CLLocationManagerDelegate
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
            manager.requestLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let c = last.coordinate

        // Actualiza lat/lon
        latitude  = c.latitude
        longitude = c.longitude

        // 1) Intenta resolver por cache
        let key = cacheKey(lat: c.latitude, lon: c.longitude)
        if let hit = cache[key] {
            estado = hit.state
            municipio = hit.municipality
            lastLog = snapshotString() + " (cache)"
            print("[LOC] \(lastLog)")
            // Decide si aún así quieres refrescar en background -> opcional
            return
        }

        // 2) Throttle por tiempo y distancia
        let now = Date()
        if let t = lastRGAt, now.timeIntervalSince(t) < minRGInterval {
            lastLog = "RG omitido por intervalo mínimo (\(minRGInterval)s)."
            print("[LOC] \(lastLog)")
            return
        }
        if let prev = lastRGCoord {
            let d = CLLocation(latitude: c.latitude, longitude: c.longitude)
                .distance(from: CLLocation(latitude: prev.latitude, longitude: prev.longitude))
            if d < minMoveMeters {
                lastLog = "RG omitido (< \(Int(minMoveMeters)) m de movimiento)."
                print("[LOC] \(lastLog)")
                return
            }
        }
        lastRGAt = now
        lastRGCoord = c

        // 3) Hacer reverse geocoding según versión
        if #available(iOS 26.0, *) {
            Task {
                do {
                    let (state, muni) = try await reverseGeocodeHTTP(lat: c.latitude, lon: c.longitude)
                    await MainActor.run {
                        self.estado = state
                        self.municipio = muni
                        self.lastLog = self.snapshotString()
                        print("[LOC] \(self.lastLog)")
                        self.putCache(key: key, state: state, municipality: muni)
                    }
                } catch {
                    await MainActor.run {
                        self.lastLog = "RG HTTP error: \(error.localizedDescription)"
                        print("[LOC] \(self.lastLog)")
                    }
                }
            }
        } else {
            geocoder.reverseGeocodeLocation(last) { [weak self] placemarks, error in
                guard let self = self else { return }
                Task { @MainActor in
                    if let error = error {
                        self.lastLog = "RG error: \(error.localizedDescription)"
                        print("[LOC] \(self.lastLog)")
                        return
                    }
                    guard let p = placemarks?.first else { return }
                    let state = p.administrativeArea ?? ""
                    let muni  = p.subAdministrativeArea ?? p.locality ?? ""
                    self.estado = state
                    self.municipio = muni
                    self.lastLog = self.snapshotString()
                    print("[LOC] \(self.lastLog)")
                    self.putCache(key: key, state: state, municipality: muni)
                }
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastLog = "Error: \(error.localizedDescription)"
            print("[LOC] \(self.lastLog)")
        }
    }

    // MARK: - Cache helpers
    private func cacheKey(lat: Double, lon: Double) -> String {
        let p = max(0, cachePrecisionDigits)
        let fmt = "%.\(p)f"
        let latR = String(format: fmt, lat)
        let lonR = String(format: fmt, lon)
        return "\(latR),\(lonR)"
    }

    private func putCache(key: String, state: String, municipality: String) {
        cache[key] = CacheValue(state: state, municipality: municipality)
        // Persistimos en background
        let snapshot = cache
        let url = cacheURL
        Task.detached {
            if let data = try? JSONEncoder().encode(snapshot) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    // MARK: - Reverse Geocoding HTTP (Nominatim) para iOS 26+
    private struct NominatimResponse: Decodable {
        let address: Address?
        struct Address: Decodable {
            let state: String?
            let region: String?
            let municipality: String?
            let county: String?
            let city: String?
            let town: String?
            let village: String?
            let suburb: String?
            let cityDistrict: String?
            let stateDistrict: String?

            enum CodingKeys: String, CodingKey {
                case state, region, municipality, county, city, town, village, suburb
                case cityDistrict = "city_district"
                case stateDistrict = "state_district"
            }
        }
    }

    private func reverseGeocodeHTTP(lat: Double, lon: Double) async throws -> (String, String) {
        var comps = URLComponents(string: "https://nominatim.openstreetmap.org/reverse")!
        comps.queryItems = [
            .init(name: "lat", value: String(lat)),
            .init(name: "lon", value: String(lon)),
            .init(name: "format", value: "json"),
            .init(name: "addressdetails", value: "1")
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")       // requerido por Nominatim
        req.setValue(acceptLanguage, forHTTPHeaderField: "Accept-Language")
        req.timeoutInterval = 8

        let (data, _) = try await URLSession.shared.data(for: req)
        let decoded = try JSONDecoder().decode(NominatimResponse.self, from: data)
        let a = decoded.address

        // Estado → primer candidato no vacío
        let state: String = {
            if let s = a?.state, !s.isEmpty { return s }
            if let r = a?.region, !r.isEmpty { return r }
            if let sd = a?.stateDistrict, !sd.isEmpty { return sd }
            return ""
        }()

        // Municipio → primer candidato no vacío
        let muni: String = {
            let candidates: [String?] = [
                a?.municipality, a?.county, a?.city, a?.town,
                a?.village, a?.cityDistrict, a?.suburb
            ]
            return candidates
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first(where: { !$0.isEmpty }) ?? ""
        }()

        return (state, muni)
    }
}

