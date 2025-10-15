//
//  GV_Banner_Manager.swift
//  limpioCS
//
//  Created by Victor on 2025-10-10.
//  Gestor de banners con auto-rotación y control de reproducción
//

import SwiftUI
import Combine

/// Manager para gestionar banners rotativos con control de reproducción
// TEMPORALMENTE DESHABILITADO PARA DEBUGGING
// class GV_Banner_Manager: ObservableObject {
class GV_Banner_Manager: ObservableObject {
    static let shared = GV_Banner_Manager()
    
    // MARK: - Published Properties
    
    /// Banners activos (filtrados por fecha)
    @Published private(set) var bannersActivos: [GV_Banner_Config] = []
    
    /// Índice del banner actual
    @Published var bannerActualIndex: Int = 0
    
    /// Estado de reproducción (true = rotando, false = pausado)
    @Published var estaReproduciendo: Bool = true
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        cargarBanners()
        iniciarRotacion()
    }
    
    // MARK: - Carga de Banners
    
    /// Carga los banners activos desde el Plist
    func cargarBanners() {
        bannersActivos = GV_Banner_ConfigSource.shared.loadActiveBanners()
        
        if bannersActivos.isEmpty {
            // print("⚠️ No hay banners activos para mostrar")
        } else {
            // print("✅ \(bannersActivos.count) banners activos cargados")
        }
    }
    
    /// Recarga los banners (útil si el Plist cambia)
    func recargarBanners() {
        GV_Banner_ConfigSource.shared.reloadBanners()
        cargarBanners()
        bannerActualIndex = 0
        reiniciarRotacion()
    }
    
    // MARK: - Control de Rotación
    
    /// Inicia la rotación automática de banners
    private func iniciarRotacion() {
        guard !bannersActivos.isEmpty else { return }
        
        // Detener timer anterior si existe
        timer?.invalidate()
        
        // Crear nuevo timer solo si está reproduciendo
        if estaReproduciendo {
            programarSiguienteRotacion()
        }
    }
    
    /// Programa el siguiente cambio de banner
    private func programarSiguienteRotacion() {
        guard estaReproduciendo, !bannersActivos.isEmpty else { return }
        
        let bannerActual = bannersActivos[bannerActualIndex]
        let tiempoExposicion = TimeInterval(bannerActual.tiempoExposicionSegundos)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tiempoExposicion, repeats: false) { [weak self] _ in
            self?.siguienteBanner()
        }
        
        // print("⏱️ Banner '\(bannerActual.nombre)' visible por \(tiempoExposicion)s")
    }
    
    /// Avanza al siguiente banner
    func siguienteBanner() {
        guard !bannersActivos.isEmpty else { return }
        
        // Actualizar sin animación para evitar "Publishing changes" errors
        bannerActualIndex = (bannerActualIndex + 1) % bannersActivos.count
        
        if estaReproduciendo {
            programarSiguienteRotacion()
        }
    }
    
    /// Retrocede al banner anterior
    func bannerAnterior() {
        guard !bannersActivos.isEmpty else { return }
        
        // Actualizar sin animación para evitar "Publishing changes" errors
        bannerActualIndex = (bannerActualIndex - 1 + bannersActivos.count) % bannersActivos.count
        
        if estaReproduciendo {
            programarSiguienteRotacion()
        }
    }
    
    /// Salta a un banner específico
    /// - Parameter index: Índice del banner al que saltar
    func saltarABanner(_ index: Int) {
        guard index >= 0 && index < bannersActivos.count else { return }
        
        // Actualizar sin animación para evitar "Publishing changes" errors
        bannerActualIndex = index
        
        if estaReproduciendo {
            programarSiguienteRotacion()
        }
    }
    
    // MARK: - Control Play/Pause
    
    /// Alterna entre reproducción y pausa
    func toggleReproduccion() {
        estaReproduciendo.toggle()
        
        if estaReproduciendo {
            ProductionLogger.bannerLog("▶️ Rotación de banners reanudada")
            programarSiguienteRotacion()
        } else {
            ProductionLogger.bannerLog("⏸️ Rotación de banners pausada")
            timer?.invalidate()
        }
    }
    
    /// Pausa la rotación
    func pausar() {
        if estaReproduciendo {
            estaReproduciendo = false
            timer?.invalidate()
            ProductionLogger.bannerLog("⏸️ Rotación pausada")
        }
    }
    
    /// Reanuda la rotación
    func reproducir() {
        if !estaReproduciendo {
            estaReproduciendo = true
            programarSiguienteRotacion()
            ProductionLogger.bannerLog("▶️ Rotación reanudada")
        }
    }
    
    /// Reinicia la rotación desde el principio
    private func reiniciarRotacion() {
        timer?.invalidate()
        if estaReproduciendo {
            iniciarRotacion()
        }
    }
    
    // MARK: - Acceso a Banner Actual
    
    /// Banner que se está mostrando actualmente
    var bannerActual: GV_Banner_Config? {
        guard !bannersActivos.isEmpty,
              bannerActualIndex >= 0,
              bannerActualIndex < bannersActivos.count else {
            return nil
        }
        return bannersActivos[bannerActualIndex]
    }
    
    /// Verifica si hay banners disponibles
    var hayBanners: Bool {
        return !bannersActivos.isEmpty
    }
    
    // MARK: - Control de Visibilidad (Optimización)
    
    /// Control de visibilidad de la vista (optimización)
    func vistaSeVolvioVisible() {
        ProductionLogger.bannerLog("👁️ Vista se volvió visible - reanudando banners")
        reproducir()
    }
    
    func vistaSeVolvioInvisible() {
        ProductionLogger.bannerLog("👁️ Vista se volvió invisible - pausando banners")
        pausar()
    }
    
    // MARK: - Cleanup
    
    deinit {
        timer?.invalidate()
    }
}

