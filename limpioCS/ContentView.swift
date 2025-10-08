//
//  ContentView.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Cliente: Concanaco ServyTur
//  Performed by: Grupo VAL Human TECH
//
//  Descripción:
//  ------------
//  Portada principal con accesos a:
//  • Web Services (pruebas de endpoints)
//  • Base de Datos (DB incremental CCP)
//  • Mapas (normal y con clusters)
//  • Promociones (ccp) por establecimiento
//  • Migrado al sistema de temas dinámico
//
//  Nota: Asegúrate de inyectar .environmentObject(LocationService())
//  en la jerarquía superior (App) para que la ubicación funcione.
//
//  Fecha: 2025-10-03 la hora de hoy es 15:55
//  Migrado: 2025-01-10
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var location: LocationService
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Web Services
                Section("Web Services") {
                    NavigationLink {
                        ccp_WS_EstablecimientosView()
                    } label: {
                        Label("Establecimientos (normal)", systemImage: "network")
                    }

                    NavigationLink {
                        ccp_WS_EstablecimientosViewFiltrado()
                    } label: {
                        Label("Establecimientos por estado (auto)", systemImage: "location.fill")
                    }
                }

                // MARK: - Base de Datos
                Section("Base de Datos") {
                    NavigationLink {
                        ccp_BDF_DBIncrementalTestView()
                    } label: {
                        Label("Prueba DB Incremental", systemImage: "externaldrive.connected.to.line.below")
                    }
                }

                // MARK: - Mapas
                Section("Mapa") {
                    NavigationLink {
                        ccp_BDF_MapView()
                    } label: {
                        Label("Mapa de BD local", systemImage: "map.fill")
                    }

                    NavigationLink {
                        ccp_BDF_MapClustersView()
                    } label: {
                        Label("Mapa (clusters de establecimientos)", systemImage: "square.stack.3d.up.fill")
                    }
                }

                // MARK: - Promociones
                Section("Promociones") {
                    NavigationLink {
                        // Puedes pasar un ID inicial si quieres que el campo venga prellenado, por ejemplo 41178.
                        ccp_BDF_PromocionesView() // o ccp_BDF_PromocionesView(establecimientoIdInicial: 41178)
                    } label: {
                        Label("Promociones (ccp)", systemImage: "tag.fill")
                    }
                }
            }
            .themed()
            .navigationTitle("Portada")
            .onAppear {
                // Inicia ubicación al entrar a la portada (útil para mapas, etc.)
                location.start()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationService())
}
