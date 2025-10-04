//
//  ccp_BDF_PromocionesView.swift
//  LimpioCS
//
//  Vista de prueba para consultar promociones por establecimiento.
//  • Campo para escribir el "establecimiento_id" y botón Consultar.
//  • Lista simple con título, fechas, mini-descripción e imagen (si existe).
//  • Sin bindings innecesarios ni mutaciones de let.
//  • Llama a lmpBDF_ServiciosPromociones.fetchPromos(establecimientoId:).
//
//  Requisitos: iOS 17+
//  Fecha: 2025-10-03 (actualizado para id inicial)
//

import SwiftUI
import Foundation

struct ccp_BDF_PromocionesView: View {

    // Texto del TextField
    @State private var estIdText: String

    // Resultados
    @State private var promos: [PromocionWS] = []

    // Estado
    @State private var loading = false
    @State private var errorMsg: String?

    // Init que permite prellenar el id (viene desde EstablecimientoDetalleSheetSimple)
    init(establecimientoIdInicial: Int? = nil) {
        _estIdText = State(initialValue: establecimientoIdInicial.map(String.init) ?? "")
    }

    var body: some View {
        List {
            /*
            Section("Promociones por establecimiento") {
                HStack {
                    TextField("establecimiento_id", text: $estIdText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await consultar() }
                    } label: {
                        Label("Consultar", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(loading)
                }

                if let errorMsg {
                    Text("Error: \(errorMsg)")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
             
            }*/

            if loading {
                Section {
                    HStack {
                        ProgressView()
                        Text("Cargando…")
                    }
                }
            }

            Section("Resultados (\(promos.count))") {
                if promos.isEmpty && !loading && errorMsg == nil {
                    Text("Sin resultados.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(promos) { p in
                        PromocionRow(promo: p)
                    }
                }
            }
        }
        .navigationTitle("Promociones (ccp)")
        .onAppear {
            // Si venimos con un id válido prellenado, lanzamos la consulta automáticamente
            if Int(estIdText) != nil && !estIdText.isEmpty {
                Task { await consultar() }
            }
        }
    }

    // MARK: - Acciones

    private func consultar() async {
        errorMsg = nil
        promos = []
        guard let estId = Int(estIdText.trimmingCharacters(in: .whitespaces)) else {
            errorMsg = "Escribe un ID numérico válido."
            return
        }

        loading = true
        do {
            let items = try await lmpBDF_ServiciosPromociones
                .fetchPromos(establecimientoId: estId)
            promos = items
        } catch {
            errorMsg = "No se pudo cargar: \(error.localizedDescription)"
        }
        loading = false
    }
}

// MARK: - Row

private struct PromocionRow: View {
    let promo: PromocionWS

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let urlStr = promo.promocion_imagen,
               let url = URL(string: urlStr) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(.secondary.opacity(0.1))
                        ProgressView()
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(promo.promocion_titulo)
                    .font(.headline)

                if let fi = promo.promocion_fi, let ff = promo.promocion_ff {
                    Text("\(fi) – \(ff)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !promo.promocion_descripcion.isEmpty {
                    Text(promo.promocion_descripcion)
                        .lineLimit(3)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ccp_BDF_PromocionesView(establecimientoIdInicial: 41178)
    }
}
