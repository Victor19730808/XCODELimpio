//
//  GV_ScreenTypes.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Definición de tipos de pantalla para el sistema General Views
//

import SwiftUI

/// Enum que define los tipos de pantalla disponibles en el sistema General Views
enum ScreenType: Int, CaseIterable, Identifiable {
    case splash = 1        // Tipo Portada o Splash
    case content = 2       // Tipo Menú o Content  
    case general = 3       // Tipo Vista General
    case modal = 4         // Tipo Ventanas Modal o Wrapping
    
    var id: Int { self.rawValue }
    
    /// Nombre descriptivo del tipo de pantalla
    var displayName: String {
        switch self {
        case .splash:
            return "Tipo Portada o Splash"
        case .content:
            return "Tipo Menú o Content"
        case .general:
            return "Tipo Vista General"
        case .modal:
            return "Tipo Ventanas Modal o Wrapping"
        }
    }
    
    /// Prefijo de nomenclatura para archivos de este tipo
    var filePrefix: String {
        switch self {
        case .splash:
            return "GV_SCR_tp_"
        case .content:
            return "GV_SCR_tc_"
        case .general:
            return "GV_SCR_vg_"
        case .modal:
            return "GV_SCR_tm_"
        }
    }
    
    /// Descripción corta del tipo de pantalla
    var shortDescription: String {
        switch self {
        case .splash:
            return "Pantalla de bienvenida/inicio"
        case .content:
            return "Pantalla principal con navegación/menú"
        case .general:
            return "Pantallas de contenido principal"
        case .modal:
            return "Pop-ups, modales, sheets"
        }
    }
}

/// Extensión para generar nombres de archivo completos
extension ScreenType {
    /// Genera el nombre completo del archivo con el prefijo correspondiente
    func fileName(for name: String) -> String {
        return "\(filePrefix)\(name).swift"
    }
    
    /// Valida si el nombre del archivo actual coincide con el prefijo del tipo de pantalla.
    /// - Parameter fileName: Nombre del archivo sin extensión (ej: "GV_SCR_tp_prueba2")
    /// - Returns: true si el prefijo coincide con el tipo de pantalla, false en caso contrario
    func validaNombreFileType(fileName: String) -> Bool {
        return fileName.hasPrefix(self.filePrefix)
    }
    
    /// Devuelve un diccionario con todos los valores del tipo de pantalla
    /// - Returns: Diccionario con id, rawValue, displayName, filePrefix, shortDescription
    func showAll() -> [String: Any] {
        return [
            "id": self.id,
            "rawValue": self.rawValue,
            "displayName": self.displayName,
            "filePrefix": self.filePrefix,
            "shortDescription": self.shortDescription
        ]
    }
    
    /// Devuelve toda la información del tipo de pantalla como texto formateado
    /// - Parameter fileName: Nombre del archivo actual (opcional)
    /// - Returns: String formateado con toda la información
    func showAllFormatted(fileName: String? = nil) -> String {
        let currentFile = fileName ?? "No especificado"
        let isValid = fileName != nil ? validaNombreFileType(fileName: fileName!) : false
        let validationStatus = isValid ? "✅ VÁLIDO" : "❌ INVÁLIDO"
        
        // Análisis detallado para casos inválidos
        var analysis = ""
        if !isValid {
            if let fileName = fileName {
                // Caso: archivo especificado pero prefijo incorrecto
                let actualPrefix = String(fileName.prefix(self.filePrefix.count))
                let expectedPrefix = self.filePrefix
                
                analysis = """
                
                🔍 ANÁLISIS DEL ERROR
                ═════════════════════
                
                📂 Archivo recibido: \(fileName)
                🔍 Prefijo encontrado: "\(actualPrefix)"
                🎯 Prefijo esperado: "\(expectedPrefix)"
                
                ❌ PROBLEMA: El prefijo del archivo NO coincide
                💡 SOLUCIÓN: Renombrar el archivo para que use el prefijo correcto
                
                """
            } else {
                // Caso: no se especificó archivo
                analysis = """
                
                🔍 ANÁLISIS DEL ERROR
                ═════════════════════
                
                📂 Archivo recibido: No especificado
                🎯 Prefijo esperado: "\(self.filePrefix)"
                
                ❌ PROBLEMA: No se proporcionó el nombre del archivo
                💡 SOLUCIÓN: Pasar el nombre del archivo como parámetro a showAllFormatted()
                
                """
            }
        }
        
        return """
        📱 INFORMACIÓN DEL TIPO DE PANTALLA
        ════════════════════════════════════
        
        🔢 ID: \(self.id)
        📊 Raw Value: \(self.rawValue)
        📝 Nombre: \(self.displayName)
        🏷️  Prefijo: \(self.filePrefix)
        📄 Descripción: \(self.shortDescription)
        
        📁 VALIDACIÓN DE ARCHIVO
        ════════════════════════
        
        📂 Archivo actual: \(currentFile)
        🎯 Prefijo esperado: \(self.filePrefix)
        ✨ Estado: \(validationStatus)
        \(analysis)
        ════════════════════════════════════
        """
    }
    
    /// Función estática que obtiene automáticamente el nombre del archivo desde #file
    /// - Parameter filePath: La ruta completa del archivo (usar #file)
    /// - Returns: Nombre del archivo sin extensión
    static func extractFileName(from filePath: String) -> String {
        let fileName = (filePath as NSString).lastPathComponent
        let nameWithoutExtension = (fileName as NSString).deletingPathExtension
        return nameWithoutExtension
    }
    
    /// Función de conveniencia que combina showAllFormatted con extracción automática del archivo
    /// - Parameter filePath: La ruta completa del archivo (usar #file)
    /// - Returns: String formateado con toda la información y validación automática
    func showAllFormattedAuto(filePath: String) -> String {
        let fileName = ScreenType.extractFileName(from: filePath)
        return showAllFormatted(fileName: fileName)
    }
}
