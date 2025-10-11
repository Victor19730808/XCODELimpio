//
//  GV_Taxonomia.swift
//  limpioCS
//
//  Sistema de taxonomías con iconos y colores
//  Creado: 2025-01-11
//

import SwiftUI

/// Modelo de taxonomía con metadata visual
struct GV_Taxonomia: Identifiable, Hashable {
    let nombre: String
    let icono: String
    let colorHex: String
    
    // MARK: - Identifiable
    var id: String { nombre }
    
    // MARK: - Computed Properties
    
    /// Color de SwiftUI parseado desde hex
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
    
    /// Color con opacidad para fondos
    var colorOpaco: Color {
        color.opacity(0.15)
    }
    
    /// Vista del icono como SF Symbol
    @ViewBuilder
    func iconoView(size: CGFloat = 20) -> some View {
        Image(systemName: icono)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

// MARK: - Manager Singleton

@Observable
class GV_TaxonomiaManager {
    
    // MARK: - Singleton
    static let shared = GV_TaxonomiaManager()
    
    // MARK: - Properties
    
    /// Diccionario de taxonomías por nombre
    private(set) var taxonomias: [String: GV_Taxonomia] = [:]
    
    /// Estado de carga
    private(set) var isLoaded: Bool = false
    private(set) var loadError: String?
    
    // MARK: - Initialization
    
    private init() {
        loadTaxonomias()
    }
    
    // MARK: - Loading
    
    /// Carga las taxonomías desde el Plist
    private func loadTaxonomias() {
        guard let url = Bundle.main.url(forResource: "GV_Taxonomias", withExtension: "plist") else {
            loadError = "No se encontró el archivo GV_Taxonomias.plist"
            print("❌ Error: \(loadError!)")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            let wrapper = try decoder.decode(TaxonomiasWrapper.self, from: data)
            
            // Convertir a diccionario
            for (nombre, metadata) in wrapper.taxonomias {
                self.taxonomias[nombre] = GV_Taxonomia(
                    nombre: nombre,
                    icono: metadata.icono,
                    colorHex: metadata.colorHex
                )
            }
            
            self.isLoaded = true
            print("✅ Taxonomías cargadas: \(taxonomias.count)")
            
        } catch {
            loadError = "Error al cargar taxonomías: \(error.localizedDescription)"
            print("❌ \(loadError!)")
        }
    }
    
    /// Recarga las taxonomías desde el Plist
    func reload() {
        taxonomias.removeAll()
        isLoaded = false
        loadError = nil
        loadTaxonomias()
    }
    
    // MARK: - Búsqueda
    
    /// Obtiene una taxonomía por su nombre
    /// - Parameter nombre: Nombre de la taxonomía
    /// - Returns: Taxonomía o nil si no existe
    func taxonomia(byNombre nombre: String) -> GV_Taxonomia? {
        return taxonomias[nombre]
    }
    
    /// Obtiene todas las taxonomías como array ordenado
    var todasLasTaxonomias: [GV_Taxonomia] {
        return taxonomias.values.sorted { $0.nombre < $1.nombre }
    }
    
    // MARK: - Helpers para UI
    
    /// Obtiene el color de una taxonomía por su nombre
    /// - Parameter nombre: Nombre de la taxonomía
    /// - Returns: Color de SwiftUI
    func color(forTaxonomia nombre: String) -> Color {
        return taxonomia(byNombre: nombre)?.color ?? .gray
    }
    
    /// Obtiene el icono de una taxonomía por su nombre
    /// - Parameter nombre: Nombre de la taxonomía
    /// - Returns: Nombre del SF Symbol
    func icono(forTaxonomia nombre: String) -> String {
        return taxonomia(byNombre: nombre)?.icono ?? "folder.fill"
    }
    
    // MARK: - Estadísticas
    
    /// Número total de taxonomías
    var totalTaxonomias: Int {
        taxonomias.count
    }
}

// MARK: - Wrapper para decodificación del Plist

private struct TaxonomiasWrapper: Codable {
    let taxonomias: [String: TaxonomiaMetadata]
}

private struct TaxonomiaMetadata: Codable {
    let icono: String
    let colorHex: String
}

// MARK: - View Extension para fácil acceso

extension View {
    /// Aplica estilo de taxonomía a un Text
    /// - Parameter taxonomia: Taxonomía a aplicar
    /// - Returns: View modificado
    func taxonomiaTag(_ taxonomia: GV_Taxonomia) -> some View {
        HStack(spacing: 4) {
            taxonomia.iconoView(size: 12)
            self
        }
        .font(.caption2)
        .fontWeight(.medium)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(taxonomia.colorOpaco)
        .foregroundColor(taxonomia.color)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    /// Aplica estilo de taxonomía por nombre
    /// - Parameter nombre: Nombre de la taxonomía
    /// - Returns: View modificado
    func taxonomiaTag(byNombre nombre: String) -> some View {
        let taxonomia = GV_TaxonomiaManager.shared.taxonomia(byNombre: nombre)
        return HStack(spacing: 4) {
            if let tax = taxonomia {
                tax.iconoView(size: 12)
            } else {
                Image(systemName: "folder.fill")
                    .font(.caption2)
            }
            self
        }
        .font(.caption2)
        .fontWeight(.medium)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(taxonomia?.colorOpaco ?? Color.gray.opacity(0.1))
        .foregroundColor(taxonomia?.color ?? .gray)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

