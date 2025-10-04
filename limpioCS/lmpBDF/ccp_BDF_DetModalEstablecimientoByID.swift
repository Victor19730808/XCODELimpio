//
//  ccp_BDF_DetModalEstablecimientoByID.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Cliente: Concanaco ServyTur
//  Performed by: Grupo VAL Human TECH
//
//  Descripción:
//  ----------------------------------------------------------------
//  • Vista reusable para mostrar detalle simple de un establecimiento.
//  • Wrapper que permite abrir el detalle pasando solo un ID (Int64).
//  • Usa SwiftData (@Query) para resolver el modelo por ID exacto.
//  • Botón “Promociones” que presenta una sheet independiente.
//  • iOS 17+
//
//  Fecha: 2025-10-04
//

import SwiftUI
import SwiftData
import MapKit

// MARK: - 1) Vista reusable (recibe el modelo completo)

struct EstablecimientoDetalleSheetSimple: View {
    let est: lmpBDF_EstablecimientoLocal

    @State private var showPromos = false

    init(est: lmpBDF_EstablecimientoLocal) {
        self.est = est
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // “Grip” superior del sheet
            Capsule()
                .fill(.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)

            // Título
            Text(est.nombre)
                .font(.title2.bold())

            // Datos básicos
            Group {
                HStack { Text("Estado:").bold(); Text(est.estado ?? "—") }
                HStack { Text("Municipio:").bold(); Text(est.municipio ?? "—") }
                HStack { Text("Categoría:").bold(); Text(est.categoria ?? "—") }

                if let lat = est.lat, let lon = est.lon {
                    Text(String(format: "Lat/Lon: %.5f, %.5f", lat, lon))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Acciones
            HStack(spacing: 12) {
                // En lugar de NavigationLink, usamos una sheet propia
                Button {
                    showPromos = true
                } label: {
                    pill(icon: "tag.fill", text: "Promociones", tint: .blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        // Sheet que se presenta encima del detalle (con su propio NavigationStack)
        .sheet(isPresented: $showPromos) {
            NavigationStack {
                ccp_BDF_PromocionesView(establecimientoIdInicial: est.id)
            }
        }
    }

    // MARK: - UI helper
    private func pill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text).fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(tint.opacity(0.15)))
        .foregroundStyle(tint)
    }
}

// MARK: - 2) Wrapper que resuelve por ID (SwiftData)

struct ccp_BDF_DetModalEstablecimientoByID: View {
    private let estabId: Int64
    @Query private var encontrados: [lmpBDF_EstablecimientoLocal]

    init(estabId: Int64) {
        self.estabId = estabId

        // Si tu modelo usa Int (no Int64) para 'id', convierte aquí:
        let idInt = Int(exactly: estabId) ?? -1

        _encontrados = Query(
            filter: #Predicate<lmpBDF_EstablecimientoLocal> { $0.id == idInt },
            sort: [SortDescriptor(\.nombre, comparator: .localizedStandard)]
        )
    }

    var body: some View {
        if let est = encontrados.first {
            EstablecimientoDetalleSheetSimple(est: est)
        } else {
            VStack {
                Text("No encontrado")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("ID: \(estabId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
