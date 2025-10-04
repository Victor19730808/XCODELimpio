//
//  ccp_BDF_FavoritosView.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Descripción:
//  ----------------------------------------------------------------
//  • Lista de establecimientos marcados como favoritos (esFavorito == true).
//  • Reutiliza el componente ccp_UI_EstablecimientoRow para cada fila.
//  • Ordenado por nombre ascendente.
//  • Muestra estado vacío si no hay favoritos.
//
//  Fecha: 2025-10-04
//

import SwiftUI
import SwiftData

struct ccp_BDF_FavoritosView: View {
    // Trae únicamente favoritos
    @Query(
        filter: #Predicate<lmpBDF_EstablecimientoLocal> { $0.esFavorito == true },
        sort: \.nombre,
        order: .forward
    )
    private var favoritos: [lmpBDF_EstablecimientoLocal]

    var body: some View {
        Group {
            if favoritos.isEmpty {
                ContentUnavailableView(
                    "Aún no tienes favoritos",
                    systemImage: "star",
                    description: Text("Marca establecimientos con la estrella para verlos aquí.")
                )
            } else {
                List(favoritos) { est in
                    ccp_UI_EstablecimientoRow(est: est)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Mis Favoritos")
    }
}

#Preview {
    NavigationStack {
        ccp_BDF_FavoritosView()
    }
}
