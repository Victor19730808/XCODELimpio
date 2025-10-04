import SwiftUI

struct ccp_WS_EstablecimientosView: View {
    @State private var nombre: String = ""      // <-- NUEVO
    @State private var municipio: String = ""
    @State private var estado: String = ""
    @State private var categoria: String = ""
    @State private var resultados: [Establecimiento] = []
    @State private var cargando = false
    @State private var errorMsg: String? = nil

    let servicios = Servicios()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CCP — Establecimientos")
                .font(.title.bold())

            Group {
                TextField("Nombre de establecimiento (opcional)", text: $nombre)   // <-- NUEVO
                    .textFieldStyle(.roundedBorder)
                TextField("Municipio (opcional)", text: $municipio)
                    .textFieldStyle(.roundedBorder)
                TextField("Estado (opcional)", text: $estado)
                    .textFieldStyle(.roundedBorder)
                TextField("Categoría (opcional)", text: $categoria)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Buscar") { cargar() }
                    .buttonStyle(.borderedProminent)
                if cargando { ProgressView().padding(.leading, 4) }
            }

            if let errorMsg { Text(errorMsg).foregroundStyle(.red) }

            Text("Resultados: \(resultados.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List(resultados.prefix(50)) { e in
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.establecimiento_nombre).font(.headline)
                    Text("\(e.direccion_municipio ?? "?"), \(e.direccion_estado ?? "?") — Cat: \(e.categoria_nombre ?? "-")")
                        .font(.caption).foregroundStyle(.secondary)
                    if let lat = e.direccion_latitud, let lon = e.direccion_longitud {
                        Text(String(format: "Lat/Lon: %.6f, %.6f", lat, lon))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("ccp_WS_Establecimientos")
    }

    private func cargar() {
        errorMsg = nil
        cargando = true
        Task {
            do {
                let filtros = FiltrosEstablecimientos(
                    municipio: municipio,
                    estado: estado,
                    categoria: categoria,
                    nombreContains: nombre            // <-- NUEVO
                )
                let data = try await servicios.obtenerEstablecimientos(filtros: filtros)
                await MainActor.run {
                    resultados = data
                    cargando = false
                }
                Logger.ccpPrint("Establecimientos encontrados: \(data.count) [nombre=\(nombre), muni=\(municipio), edo=\(estado), cat=\(categoria)]")
            } catch {
                await MainActor.run {
                    errorMsg = error.localizedDescription
                    cargando = false
                }
                Logger.ccpPrint("Error establecimientos: \(error.localizedDescription)")
            }
        }
    }
}
