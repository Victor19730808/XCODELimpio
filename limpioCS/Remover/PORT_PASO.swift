//
//  PORT_PASO.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Descripción:
//  ----------------------------------------------------------------
//  • Portada mínima para pruebas del módulo BDF.
//  • Acceso a:
//      - Lista unificada (Todos / Favoritos)
//      - Mapa base (ccp_BDF_MapView)
//      - Mapa con clusters (ccp_BDF_MapClustersView)
//  • iOS 17+
//
//  Fecha: 2025-10-04
//

import SwiftUI

struct PORT_PASO: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Explorar base de datos") {
                    NavigationLink("Lista unificada (filtro)") {
                        ccp_BDF_EstablecimientosListaView()
                    }
                }

                Section("Mapas") {
                    NavigationLink("Mapa View") {
                        ccp_BDF_MapView()
                    }

                    NavigationLink("Cluster View") {
                        ccp_BDF_MapClustersView()
                    }
                }
            }
            .navigationTitle("Pruebas BDF")
            .listStyle(.insetGrouped)
        }
    }
}

#Preview {
    PORT_PASO()
}
