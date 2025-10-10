//
//  GV_Banner_Config.swift
//  limpioCS
//
//  Created by Victor on 2025-10-10.
//  Sistema de Banners para el Framework GV
//  Modelo de datos para configuración de banners rotativos
//

import Foundation
import SwiftUI

/// Estructura que define la configuración completa de un banner
struct GV_Banner_Config: Identifiable {
    let id: UUID
    
    // MARK: - Información Básica
    let nombre: String
    
    // MARK: - Configuración del Header/Caption
    let headerTitulo: String        // Texto del header o "VG_NO_PATROCINADOR" para ocultarlo
    let headerIcono: String         // Ícono SF Symbol para el header
    
    // MARK: - Imagen/Fotografía (exclusivas - preferencia: Assets)
    let fotografiaAssets: String?   // Nombre de la imagen en Assets.xcassets (ej: "BF", "HM")
    let fotografiaURL: String?      // URL de la imagen remota
    
    let textoAlternativo: String    // Texto si no hay imagen disponible
    
    // MARK: - Configuración de Tiempo
    let tiempoExposicionSegundos: Int  // Cuántos segundos se muestra antes de rotar
    
    // MARK: - Validación de Fechas
    let fechaInicio: Date
    let fechaFin: Date
    
    // MARK: - Enlace (exclusivos)
    let tieneEnlace: Bool           // true = clickeable, false = solo visual
    let url: String?                // URL de destino (si tieneEnlace = true)
    
    // MARK: - Comportamiento de Navegación
    let abrirFueraDeApp: Bool       // true = Safari, false = WebView interno
    
    // MARK: - Computed Properties
    
    /// Verifica si debe mostrar el header/caption
    var mostrarHeader: Bool {
        return headerTitulo != "VG_NO_PATROCINADOR"
    }
    
    /// Verifica si el banner está activo según las fechas
    var estaActivo: Bool {
        let ahora = Date()
        return ahora >= fechaInicio && ahora <= fechaFin
    }
    
    /// Devuelve el nombre de la imagen desde Assets (si existe)
    var imagenAssets: String? {
        return fotografiaAssets
    }
    
    /// Devuelve la URL de la imagen remota (si existe y no hay Assets)
    var imagenURL: URL? {
        guard fotografiaAssets == nil || fotografiaAssets?.isEmpty == true else {
            return nil  // Assets tiene preferencia
        }
        guard let urlString = fotografiaURL, !urlString.isEmpty else {
            return nil
        }
        return URL(string: urlString)
    }
    
    /// Verifica si tiene imagen disponible (Assets o URL)
    var tieneImagen: Bool {
        if let assets = fotografiaAssets, !assets.isEmpty {
            return true
        }
        if let urlString = fotografiaURL, !urlString.isEmpty {
            return true
        }
        return false
    }
    
    /// URL de destino válida (si tiene enlace)
    var urlDestino: URL? {
        guard tieneEnlace, let urlString = url, !urlString.isEmpty else {
            return nil
        }
        return URL(string: urlString)
    }
}

// MARK: - Extensión para Debug/Info

extension GV_Banner_Config {
    /// Información formateada del banner (para debug)
    var infoFormateada: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        
        return """
        🏷️ BANNER: \(nombre)
        ══════════════════════
        📸 Imagen Assets: \(fotografiaAssets ?? "ninguna")
        🌐 Imagen URL: \(fotografiaURL ?? "ninguna")
        📝 Texto alternativo: \(textoAlternativo)
        ⏱️ Tiempo exposición: \(tiempoExposicionSegundos)s
        📅 Período: \(formatter.string(from: fechaInicio)) - \(formatter.string(from: fechaFin))
        🔗 Tiene enlace: \(tieneEnlace ? "Sí" : "No")
        🌍 URL: \(url ?? "ninguna")
        📱 Abre fuera de app: \(abrirFueraDeApp ? "Sí (Safari)" : "No (WebView)")
        ✅ Activo ahora: \(estaActivo ? "SÍ" : "NO")
        ══════════════════════
        """
    }
}

// MARK: - Factory para crear desde Diccionario (Plist)

extension GV_Banner_Config {
    /// Crea un banner desde un diccionario del Plist
    /// - Parameter dict: Diccionario con los datos del banner
    /// - Returns: Banner configurado o nil si hay error
    static func fromDictionary(_ dict: [String: Any]) -> GV_Banner_Config? {
        // Validar campos requeridos
        guard let nombre = dict["nombre"] as? String else {
            print("❌ Error: Banner sin nombre")
            return nil
        }
        
        // Header/Caption (opcional - default: "PATROCINADORES" + "megaphone.fill")
        let headerTitulo = dict["headerTitulo"] as? String ?? "PATROCINADORES"
        let headerIcono = dict["headerIcono"] as? String ?? "megaphone.fill"
        
        // Imagen (opcional - prioridad: Assets > URL)
        let fotografiaAssets = dict["fotografiaAssets"] as? String
        let fotografiaURL = dict["fotografiaURL"] as? String
        
        // Texto alternativo (requerido)
        guard let textoAlternativo = dict["textoAlternativo"] as? String else {
            print("❌ Error: Banner '\(nombre)' sin texto alternativo")
            return nil
        }
        
        // Tiempo de exposición (requerido)
        guard let tiempoExposicion = dict["tiempoExposicionSegundos"] as? Int else {
            print("❌ Error: Banner '\(nombre)' sin tiempo de exposición")
            return nil
        }
        
        // Fechas (requeridas)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let fechaInicioString = dict["fechaInicio"] as? String,
              let fechaInicio = dateFormatter.date(from: fechaInicioString) else {
            print("❌ Error: Banner '\(nombre)' sin fecha de inicio válida")
            return nil
        }
        
        guard let fechaFinString = dict["fechaFin"] as? String,
              let fechaFin = dateFormatter.date(from: fechaFinString) else {
            print("❌ Error: Banner '\(nombre)' sin fecha de fin válida")
            return nil
        }
        
        // Enlace
        let tieneEnlace = dict["tieneEnlace"] as? Bool ?? true  // Default: true
        let url = dict["url"] as? String
        
        // Comportamiento de navegación
        let abrirFueraDeApp = dict["abrirFueraDeApp"] as? Bool ?? true  // Default: Safari
        
        return GV_Banner_Config(
            id: UUID(),
            nombre: nombre,
            headerTitulo: headerTitulo,
            headerIcono: headerIcono,
            fotografiaAssets: fotografiaAssets,
            fotografiaURL: fotografiaURL,
            textoAlternativo: textoAlternativo,
            tiempoExposicionSegundos: tiempoExposicion,
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
            tieneEnlace: tieneEnlace,
            url: url,
            abrirFueraDeApp: abrirFueraDeApp
        )
    }
}

