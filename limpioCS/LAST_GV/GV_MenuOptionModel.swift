//
//  GV_MenuOptionModel.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Modelo dinámico para opciones de menú desde Plist
//

import SwiftUI

/// Modelo dinámico para opciones de menú cargadas desde Plist
struct GV_MenuOptionModel: Identifiable, Codable {
    let id: String
    let title: String
    let icon: String
    let navigationType: String
    let destinationView: String
    let debugOnly: Bool
    
    /// Convierte el tipo de navegación string a enum
    var navigationTypeEnum: GV_NavigationType {
        switch navigationType.lowercased() {
        case "sheet":
            return .sheet
        case "navigation":
            return .navigation
        case "action":
            return .action
        default:
            return .sheet
        }
    }
    
    /// Crea la vista destino dinámicamente
    @ViewBuilder
    func createDestinationView() -> some View {
        switch destinationView {
        case "GV_Temas_SelectorView":
            GV_Temas_SelectorView()
        case "GV_SCR_vg_EstablecimientosListaView":
            GV_SCR_vg_EstablecimientosListaView()
        case "GV_SCR_vg_FavoritosView":
            GV_SCR_vg_FavoritosView()
        case "GV_SCR_tc_menuprincipal":
            GV_SCR_tc_menuprincipal()
        case "MySettingsView":
            Text("Mis Configuraciones")
                .padding()
        default:
            Text("Vista no encontrada: \(destinationView)")
                .foregroundColor(.red)
                .padding()
        }
    }
}
