//
//  GV_SeedGenerator.swift
//  limpioCS
//
//  Created by Victor on 2025-01-13.
//  Generador de seed con coordenadas geográficas
//

import Foundation
import SwiftData
import CoreLocation

/// Generador de seed que incluye coordenadas geográficas
class GV_SeedGenerator {
    
    // MARK: - Singleton
    static let shared = GV_SeedGenerator()
    
    private init() {}
    
    // MARK: - Generar Seed con Coordenadas
    
    /// Genera un nuevo seed con coordenadas geográficas
    func generarSeedConCoordenadas(modelContext: ModelContext) async -> (success: Bool, json: String, message: String) {
        
        print("🌱 GENERADOR: Iniciando generación de seed con coordenadas...")
        
        do {
            // 1. Obtener todos los establecimientos de la BD
            let descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>()
            let establecimientos = try modelContext.fetch(descriptor)
            
            print("📊 GENERADOR: Encontrados \(establecimientos.count) establecimientos")
            
            // 2. Convertir a JSON con coordenadas
            var seedData: [[String: Any]] = []
            
            for (index, establecimiento) in establecimientos.enumerated() {
                if index % 100 == 0 {
                    print("🔄 GENERADOR: Procesando \(index)/\(establecimientos.count)")
                }
                
                var registro: [String: Any] = [
                    "establecimiento_id": establecimiento.establecimiento_id,
                    "user_id": establecimiento.user_id,
                    "usuario_id": establecimiento.usuario_id,
                    "indice_id": establecimiento.indice_id,
                    "registro_evento_id": establecimiento.registro_evento_id,
                    "establecimiento_nombre": establecimiento.establecimiento_nombre ?? "",
                    "establecimiento_logo": establecimiento.establecimiento_logo ?? "",
                    "establecimiento_url": establecimiento.establecimiento_url ?? "",
                    "usuario_phone_number": establecimiento.usuario_phone_number ?? "",
                    "usuario_email": establecimiento.usuario_email ?? "",
                    "direccion_completa": establecimiento.direccion_completa ?? "",
                    "direccion_municipio": establecimiento.direccion_municipio ?? "",
                    "direccion_estado": establecimiento.direccion_estado ?? "",
                    "categoria_id": establecimiento.categoria_id,
                    "categoria_nombre": establecimiento.categoria_nombre ?? ""
                ]
                
                // 3. Agregar coordenadas si existen
                if let latitud = establecimiento.direccion_latitud, let longitud = establecimiento.direccion_longitud {
                    registro["direccion_latitud"] = latitud
                    registro["direccion_longitud"] = longitud
                } else {
                    // 4. Generar coordenadas aproximadas basadas en el estado
                    let coordenadas = generarCoordenadasAproximadas(para: establecimiento.direccion_estado ?? "")
                    registro["direccion_latitud"] = coordenadas.latitud
                    registro["direccion_longitud"] = coordenadas.longitud
                }
                
                seedData.append(registro)
            }
            
            // 5. Convertir a JSON
            let jsonData = try JSONSerialization.data(withJSONObject: seedData, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            print("✅ GENERADOR: Seed generado exitosamente")
            print("📊 GENERADOR: \(seedData.count) registros con coordenadas")
            print("📦 GENERADOR: Tamaño JSON: \(jsonData.count) bytes")
            
            return (true, jsonString, "✅ Seed generado con \(seedData.count) registros y coordenadas")
            
        } catch {
            let errorMsg = "❌ Error al generar seed: \(error.localizedDescription)"
            print(errorMsg)
            return (false, "", errorMsg)
        }
    }
    
    // MARK: - Generar Coordenadas Aproximadas
    
    /// Genera coordenadas aproximadas basadas en el estado
    private func generarCoordenadasAproximadas(para estado: String) -> (latitud: Double, longitud: Double) {
        
        // Coordenadas aproximadas por estado (centro del estado)
        let coordenadasPorEstado: [String: (lat: Double, lon: Double)] = [
            "Aguascalientes": (21.8853, -102.2916),
            "Baja California": (30.8406, -115.2838),
            "Baja California Sur": (26.0444, -111.6661),
            "Campeche": (19.8301, -90.5349),
            "Chiapas": (16.7569, -93.1292),
            "Chihuahua": (28.6329, -106.0691),
            "Ciudad de México": (19.4326, -99.1332),
            "Coahuila": (27.0587, -101.7068),
            "Colima": (19.2452, -103.7246),
            "Durango": (24.0227, -104.6537),
            "Guanajuato": (21.0190, -101.2574),
            "Guerrero": (17.4392, -99.5451),
            "Hidalgo": (20.0911, -98.7624),
            "Jalisco": (20.6597, -103.3496),
            "México": (19.4969, -99.7233),
            "Michoacán": (19.5665, -101.7068),
            "Morelos": (18.6813, -99.1013),
            "Nayarit": (21.7514, -104.8455),
            "Nuevo León": (25.5921, -100.3119),
            "Oaxaca": (17.0732, -96.7266),
            "Puebla": (19.0414, -98.2063),
            "Querétaro": (20.5888, -100.3899),
            "Quintana Roo": (19.1817, -88.4791),
            "San Luis Potosí": (22.1565, -100.9855),
            "Sinaloa": (25.1721, -107.4795),
            "Sonora": (29.0729, -110.9559),
            "Tabasco": (17.8409, -92.6189),
            "Tamaulipas": (24.2669, -98.8363),
            "Tlaxcala": (19.3185, -98.2375),
            "Veracruz": (19.1737, -96.1342),
            "Yucatán": (20.7099, -89.0943),
            "Zacatecas": (22.7709, -102.5832)
        ]
        
        // Buscar coordenadas del estado
        if let coordenadas = coordenadasPorEstado[estado] {
            // Agregar variación aleatoria para que no estén todos en el mismo punto
            let variacionLat = Double.random(in: -0.5...0.5)
            let variacionLon = Double.random(in: -0.5...0.5)
            
            return (
                latitud: coordenadas.lat + variacionLat,
                longitud: coordenadas.lon + variacionLon
            )
        }
        
        // Coordenadas por defecto (centro de México)
        return (latitud: 23.6345, longitud: -102.5528)
    }
    
    // MARK: - Validar Seed Generado
    
    /// Valida que el seed generado tenga coordenadas
    func validarSeedConCoordenadas(jsonString: String) -> (valido: Bool, registrosConCoordenadas: Int, totalRegistros: Int) {
        
        guard let data = jsonString.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return (false, 0, 0)
        }
        
        var registrosConCoordenadas = 0
        
        for registro in jsonArray {
            if let lat = registro["direccion_latitud"] as? Double,
               let lon = registro["direccion_longitud"] as? Double,
               lat != 0 && lon != 0 {
                registrosConCoordenadas += 1
            }
        }
        
        let valido = registrosConCoordenadas > 0
        return (valido, registrosConCoordenadas, jsonArray.count)
    }
}


