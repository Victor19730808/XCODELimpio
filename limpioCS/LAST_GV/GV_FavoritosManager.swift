//
//  GV_FavoritosManager.swift
//  limpioCS
//
//  Created: 2025-01-10
//  Sistema: GV (Gestión de Favoritos)
//

import Foundation
import Combine

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
        print("🏠 GV_FavoritosManager inicializado con \(favoriteIds.count) favoritos")
    }
    
    private func loadFavorites() -> Set<Int> {
        if let data = UserDefaults.standard.data(forKey: favoritosKey),
           let decodedIds = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            print("📂 Favoritos cargados: \(decodedIds)")
            return decodedIds
        }
        print("📂 No hay favoritos guardados, iniciando con set vacío")
        return []
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteIds) {
            UserDefaults.standard.set(encoded, forKey: favoritosKey)
            print("💾 Favoritos guardados: \(favoriteIds)")
        }
    }
    
    func isFavorite(establecimientoId: Int) -> Bool {
        return favoriteIds.contains(establecimientoId)
    }
    
    func toggleFavorite(establecimientoId: Int) {
        if favoriteIds.contains(establecimientoId) {
            favoriteIds.remove(establecimientoId)
            print("❌ Removido de favoritos: \(establecimientoId)")
        } else {
            favoriteIds.insert(establecimientoId)
            print("✅ Agregado a favoritos: \(establecimientoId)")
        }
    }
    
    func addFavorite(establecimientoId: Int) {
        if !favoriteIds.contains(establecimientoId) {
            favoriteIds.insert(establecimientoId)
            print("✅ Agregado a favoritos: \(establecimientoId)")
        }
    }
    
    func removeFavorite(establecimientoId: Int) {
        if favoriteIds.contains(establecimientoId) {
            favoriteIds.remove(establecimientoId)
            print("❌ Removido de favoritos: \(establecimientoId)")
        }
    }
    
    func getFavoriteCount() -> Int {
        return favoriteIds.count
    }
    
    func getAllFavorites() -> [Int] {
        return Array(favoriteIds).sorted()
    }
}
