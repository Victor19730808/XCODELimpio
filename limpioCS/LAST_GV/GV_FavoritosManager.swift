//
//  GV_FavoritosManager.swift
//  limpioCS
//
//  Created: 2025-01-10
//  Sistema: GV (Gestión de Favoritos)
//

import Foundation
import Combine

// TEMPORALMENTE DESHABILITADO PARA DEBUGGING
// class GV_FavoritosManager: ObservableObject {
class GV_FavoritosManager: ObservableObject {
    static let shared = GV_FavoritosManager()
    private let favoritosKey = "favoriteEstablishmentIds"
    
    @Published var favoriteIds: Set<Int> {
        didSet {
            saveFavorites()
        }
    }
    
    private init() {
        self.favoriteIds = []
        self.favoriteIds = loadFavorites()
        // GV_FavoritosManager inicializado
    }
    
    private func loadFavorites() -> Set<Int> {
        if let data = UserDefaults.standard.data(forKey: favoritosKey),
           let decodedIds = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            // Favoritos cargados
            return decodedIds
        }
        // No hay favoritos guardados
        return []
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteIds) {
            UserDefaults.standard.set(encoded, forKey: favoritosKey)
            // Favoritos guardados
        }
    }
    
    func isFavorite(establecimientoId: Int) -> Bool {
        return favoriteIds.contains(establecimientoId)
    }
    
    func toggleFavorite(establecimientoId: Int) {
        if favoriteIds.contains(establecimientoId) {
            favoriteIds.remove(establecimientoId)
            // Removido de favoritos
        } else {
            favoriteIds.insert(establecimientoId)
            // Agregado a favoritos
        }
    }
    
    func addFavorite(establecimientoId: Int) {
        if !favoriteIds.contains(establecimientoId) {
            favoriteIds.insert(establecimientoId)
            // Agregado a favoritos
        }
    }
    
    func removeFavorite(establecimientoId: Int) {
        if favoriteIds.contains(establecimientoId) {
            favoriteIds.remove(establecimientoId)
            // Removido de favoritos
        }
    }
    
    func getFavoriteCount() -> Int {
        return favoriteIds.count
    }
    
    func getAllFavorites() -> [Int] {
        return Array(favoriteIds).sorted()
    }
}
