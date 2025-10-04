//
//  ccp_UI_EstablecimientoRow.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Descripción:
//  ----------------------------------------------------------------
//  • Componente visual reutilizable para mostrar un establecimiento
//    con su información básica y un botón para marcarlo como favorito.
//  • Vinculado al modelo SwiftData: lmpBDF_EstablecimientoLocal
//  • Permite alternar la propiedad esFavorito y guardar cambios.
//
//  Fecha: 2025-10-04
//

import SwiftUI
import SwiftData

struct ccp_UI_EstablecimientoRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var est: lmpBDF_EstablecimientoLocal

    var body: some View {
        HStack(spacing: 12) {
            // Avatar simple con inicial
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 42, height: 42)
                Text(String(est.nombre.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(est.nombre)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(est.municipio ?? "-"), \(est.estado ?? "-")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                est.esFavorito.toggle()
                do {
                    try modelContext.save()
                } catch {
                    print("⚠️ Error al guardar favorito:", error.localizedDescription)
                }
            } label: {
                Image(systemName: est.esFavorito ? "star.fill" : "star")
                    .imageScale(.large)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(est.esFavorito ? .yellow : .secondary)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.yellow.opacity(est.esFavorito ? 0.18 : 0.08))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(est.esFavorito ? "Quitar de favoritos" : "Agregar a favoritos")
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    // Previsualización con datos de ejemplo
    let ejemplo = lmpBDF_EstablecimientoLocal(
        id: 101,
        nombre: "Cafetería Central",
        municipio: "Querétaro",
        estado: "QRO",
        categoria: "Restaurante",
        lat: 20.6,
        lon: -100.4,
        esFavorito: true
    )
    ccp_UI_EstablecimientoRow(est: ejemplo)
        .padding()
        .previewLayout(.sizeThatFits)
}
