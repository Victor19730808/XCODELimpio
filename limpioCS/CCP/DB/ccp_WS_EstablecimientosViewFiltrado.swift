import SwiftUI

struct ccp_WS_EstablecimientosViewFiltrado: View {
    // Ubicación compartida por la app
    @EnvironmentObject private var location: LocationService

    // Filtros
    @State private var nombre: String = ""
    @State private var municipio: String = ""
    @State private var estado: String = ""
    @State private var categoria: String = ""

    // Para no sobreescribir si el usuario edita el estado
    @State private var userEditedEstado = false

    // Datos / estado de red
    @State private var resultados: [Establecimiento] = []
    @State private var cargando = false
    @State private var errorMsg: String? = nil

    // Servicio
    let servicios = Servicios()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CCP — Establecimientos filtrados")
                .font(.title.bold())

            Group {
                TextField("Nombre de establecimiento (opcional)", text: $nombre)
                    .textFieldStyle(.roundedBorder)

                TextField("Municipio (opcional)", text: $municipio)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    TextField("Estado (auto de ubicación)", text: $estado, onEditingChanged: { began in
                        if began { userEditedEstado = true }
                    })
                    .textFieldStyle(.roundedBorder)

                    Button {
                        estado = location.estado
                        userEditedEstado = true
                    } label: {
                        Label("Usar mi estado", systemImage: "location.fill")
                    }
                    .buttonStyle(.bordered)
                }

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
        .navigationTitle("ccp_WS_EstablecimientosFiltrado")
        .onAppear {
            // Inicia ubicación
            location.start()
            // Copia estado inicial si está vacío
            if estado.isEmpty, !location.estado.isEmpty {
                estado = location.estado
            }
            // Primera carga
            if !estado.isEmpty {
                cargar()
            }
        }
        .onChange(of: location.estado) { new in
            guard !userEditedEstado else { return }
            if !new.isEmpty {
                estado = new
                cargar()
            }
        }
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
                    nombreContains: nombre
                )
                let data = try await servicios.obtenerEstablecimientos(filtros: filtros)
                await MainActor.run {
                    resultados = data
                    cargando = false
                }
                Logger.ccpPrint("Estabs filtrados: \(data.count) [nombre=\(nombre), muni=\(municipio), edo=\(estado), cat=\(categoria)]")
            } catch {
                await MainActor.run {
                    errorMsg = error.localizedDescription
                    cargando = false
                }
                Logger.ccpPrint("Error estabs filtrados: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ccp_WS_EstablecimientosViewFiltrado()
            .environmentObject(LocationService()) // mock para preview
    }
}
