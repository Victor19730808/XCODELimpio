//
//  GV_CategoriaManager.swift
//  limpioCS
//
//  Manager singleton para gestión de categorías desde Plist
//  Creado: 2025-01-11
//

import Foundation
import SwiftUI

/// Manager singleton para cargar y gestionar categorías desde Plist
@Observable
class GV_CategoriaManager {
    
    // MARK: - Singleton
    static let shared = GV_CategoriaManager()
    
    // MARK: - Properties
    
    /// Todas las categorías cargadas desde el Plist
    private(set) var categorias: [GV_Categoria] = []
    
    /// Diccionario para búsqueda rápida por ID
    private var categoriasDict: [Int: GV_Categoria] = [:]
    
    /// Estado de carga
    private(set) var isLoaded: Bool = false
    private(set) var loadError: String?
    
    // MARK: - Initialization
    
    private init() {
        loadCategorias()
    }
    
    // MARK: - Loading
    
    /// Carga las categorías desde el Plist
    private func loadCategorias() {
        guard let url = Bundle.main.url(forResource: "GV_Categorias", withExtension: "plist") else {
            loadError = "No se encontró el archivo GV_Categorias.plist"
            print("❌ Error: \(loadError!)")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            let wrapper = try decoder.decode(CategoriasWrapper.self, from: data)
            
            self.categorias = wrapper.categorias
            self.categoriasDict = Dictionary(uniqueKeysWithValues: categorias.map { ($0.id, $0) })
            self.isLoaded = true
            
            print("✅ Categorías cargadas: \(categorias.count)")
            
        } catch {
            loadError = "Error al cargar categorías: \(error.localizedDescription)"
            print("❌ \(loadError!)")
        }
    }
    
    /// Recarga las categorías desde el Plist
    func reload() {
        categorias.removeAll()
        categoriasDict.removeAll()
        isLoaded = false
        loadError = nil
        loadCategorias()
    }
    
    // MARK: - Búsqueda y Filtrado
    
    /// Obtiene una categoría por su ID
    /// - Parameter id: ID de la categoría
    /// - Returns: Categoría o nil si no existe
    func categoria(byId id: Int) -> GV_Categoria? {
        return categoriasDict[id]
    }
    
    /// Obtiene una categoría por su nombre
    /// - Parameter nombre: Nombre de la categoría
    /// - Returns: Categoría o nil si no existe
    func categoria(byNombre nombre: String) -> GV_Categoria? {
        return categorias.first { $0.categoria_nombre.lowercased() == nombre.lowercased() }
    }
    
    /// Filtra categorías por evento
    /// - Parameter eventoId: ID del evento
    /// - Returns: Array de categorías del evento
    func categorias(byEvento eventoId: Int) -> [GV_Categoria] {
        return categorias.filter { $0.evento_id == eventoId }
    }
    
    /// Filtra categorías por taxonomía
    /// - Parameter taxonomia: Taxonomía a buscar
    /// - Returns: Array de categorías con esa taxonomía
    func categorias(byTaxonomia taxonomia: String) -> [GV_Categoria] {
        return categorias.filter { $0.categoria_taxonomia.lowercased() == taxonomia.lowercased() }
    }
    
    /// Busca categorías que coincidan con un término
    /// - Parameter searchTerm: Término de búsqueda
    /// - Returns: Array de categorías que coinciden
    func search(_ searchTerm: String) -> [GV_Categoria] {
        guard !searchTerm.isEmpty else { return categorias }
        return categorias.filter { $0.matches(searchTerm: searchTerm) }
    }
    
    // MARK: - Helpers para UI
    
    /// Obtiene el color de una categoría por su ID
    /// - Parameter id: ID de la categoría
    /// - Returns: Color de SwiftUI
    func color(forCategoriaId id: Int) -> Color {
        return categoria(byId: id)?.color ?? .gray
    }
    
    /// Obtiene el icono de una categoría por su ID
    /// - Parameter id: ID de la categoría
    /// - Returns: Nombre del SF Symbol
    func icono(forCategoriaId id: Int) -> String {
        return categoria(byId: id)?.icono ?? "tag.fill"
    }
    
    /// Obtiene el nombre de una categoría por su ID
    /// - Parameter id: ID de la categoría
    /// - Returns: Nombre de la categoría
    func nombre(forCategoriaId id: Int) -> String {
        return categoria(byId: id)?.categoria_nombre ?? "Desconocida"
    }
    
    // MARK: - Estadísticas
    
    /// Número total de categorías
    var totalCategorias: Int {
        categorias.count
    }
    
    /// Número de eventos únicos
    var totalEventos: Int {
        Set(categorias.map { $0.evento_id }).count
    }
    
    /// Número de taxonomías únicas
    var totalTaxonomias: Int {
        Set(categorias.map { $0.categoria_taxonomia }).count
    }
}

// MARK: - Wrapper para decodificación del Plist

private struct CategoriasWrapper: Codable {
    let categorias: [GV_Categoria]
}

// MARK: - View Extension para fácil acceso

extension View {
    /// Aplica estilo de categoría a un Text
    /// - Parameter categoria: Categoría a aplicar
    /// - Returns: View modificado
    func categoriaTag(_ categoria: GV_Categoria) -> some View {
        self
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(categoria.colorOpaco)
            .foregroundColor(categoria.color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    /// Aplica estilo de categoría por ID
    /// - Parameter categoriaId: ID de la categoría
    /// - Returns: View modificado
    func categoriaTag(byId categoriaId: Int) -> some View {
        let categoria = GV_CategoriaManager.shared.categoria(byId: categoriaId)
        return HStack(spacing: 4) {
            if let cat = categoria {
                cat.iconoView(size: 12)
            } else {
                Image(systemName: "tag.fill")
                    .font(.caption2)
            }
            self
        }
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(categoria?.colorOpaco ?? Color.gray.opacity(0.1))
        .foregroundColor(categoria?.color ?? .gray)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

