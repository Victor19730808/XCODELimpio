//
//  GV_Banner_ConfigSource.swift
//  limpioCS
//
//  Created by Victor on 2025-10-10.
//  Sistema de carga de configuraciones de banners desde Plist
//  Incluye validación automática de fechas
//

import Foundation

/// Loader de configuraciones de banners desde Plist
class GV_Banner_ConfigSource {
    static let shared = GV_Banner_ConfigSource()
    
    /// Nombre del archivo Plist
    private let plistFileName = "GV_Banners_Config"
    
    /// Cache de banners cargados
    private var cachedBanners: [GV_Banner_Config]?
    
    private init() {}
    
    // MARK: - Carga de Banners
    
    /// Carga todos los banners desde el Plist
    /// - Returns: Array de banners (puede estar vacío si hay error)
    func loadAllBanners() -> [GV_Banner_Config] {
        // Si ya están en cache, devolverlos
        if let cached = cachedBanners {
            print("📦 Banners cargados desde cache (\(cached.count) banners)")
            return cached
        }
        
        // Buscar el Plist
        guard let plistPath = Bundle.main.path(forResource: plistFileName, ofType: "plist") else {
            print("❌ Error: No se encontró el archivo \(plistFileName).plist")
            return []
        }
        
        guard let plistData = FileManager.default.contents(atPath: plistPath) else {
            print("❌ Error: No se pudo leer \(plistFileName).plist")
            return []
        }
        
        // Parsear el Plist
        do {
            guard let plist = try PropertyListSerialization.propertyList(
                from: plistData,
                options: [],
                format: nil
            ) as? [String: Any] else {
                print("❌ Error: Formato de Plist inválido")
                return []
            }
            
            guard let bannersArray = plist["banners"] as? [[String: Any]] else {
                print("❌ Error: No se encontró el array 'banners' en el Plist")
                return []
            }
            
            // Convertir diccionarios a objetos GV_Banner_Config
            var banners: [GV_Banner_Config] = []
            for (index, bannerDict) in bannersArray.enumerated() {
                if let banner = GV_Banner_Config.fromDictionary(bannerDict) {
                    banners.append(banner)
                    print("✅ Banner \(index + 1) cargado: '\(banner.nombre)'")
                } else {
                    print("⚠️ Banner \(index + 1) no pudo ser cargado (error en datos)")
                }
            }
            
            print("📊 Total banners cargados: \(banners.count)/\(bannersArray.count)")
            
            // Guardar en cache
            cachedBanners = banners
            
            return banners
            
        } catch {
            print("❌ Error al parsear Plist: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Carga solo los banners activos (dentro del rango de fechas)
    /// - Returns: Array de banners activos ordenados
    func loadActiveBanners() -> [GV_Banner_Config] {
        let allBanners = loadAllBanners()
        let activeBanners = allBanners.filter { $0.estaActivo }
        
        print("🎯 Banners activos: \(activeBanners.count)/\(allBanners.count)")
        
        // Log de banners inactivos (para debug)
        let inactiveBanners = allBanners.filter { !$0.estaActivo }
        if !inactiveBanners.isEmpty {
            print("⏸️ Banners fuera de fecha:")
            for banner in inactiveBanners {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                print("   • '\(banner.nombre)' - Válido: \(formatter.string(from: banner.fechaInicio)) a \(formatter.string(from: banner.fechaFin))")
            }
        }
        
        return activeBanners
    }
    
    /// Fuerza recarga del Plist (limpia cache)
    func reloadBanners() {
        cachedBanners = nil
        print("🔄 Cache de banners limpiado - próxima carga será desde Plist")
    }
    
    /// Información sobre la fuente de configuración
    static func currentSourceInfo() -> String {
        return "🏷️ Configuración Banners: PLIST (GV_Banners_Config.plist)"
    }
}

