import SwiftUI

struct ccp_WS_PromocionesView: View {
    @State private var establecimientoIdText: String = ""
    @State private var filtroTitulo: String = ""        // <-- NUEVO
    @State private var filtroDescripcion: String = ""   // <-- NUEVO
    @State private var promos: [Promocion] = []
    @State private var cargando = false
    @State private var errorMsg: String? = nil

    let servicios = Servicios()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CCP — Promociones por Establecimiento")
                .font(.title.bold())

            TextField("ID de establecimiento (ej. 41178)", text: $establecimientoIdText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            Group {
                TextField("Filtrar por TÍTULO (opcional)", text: $filtroTitulo)            // <-- NUEVO
                    .textFieldStyle(.roundedBorder)
                TextField("Filtrar por DESCRIPCIÓN (opcional)", text: $filtroDescripcion)  // <-- NUEVO
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Consultar") { cargar() }
                    .buttonStyle(.borderedProminent)
                if cargando { ProgressView().padding(.leading, 4) }
            }

            if let errorMsg { Text(errorMsg).foregroundStyle(.red) }

            Text("Promociones: \(promos.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List(promos.prefix(50)) { p in
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.promocion_titulo ?? "(Sin título)")
                        .font(.headline)
                    Text(p.promocion_descripcion ?? "")
                        .font(.caption)
                        .lineLimit(3)
                }
            }
        }
        .padding()
        .navigationTitle("ccp_WS_Promociones")
    }

    private func cargar() {
        errorMsg = nil
        cargando = true
        Task {
            guard let id = Int(establecimientoIdText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                await MainActor.run {
                    errorMsg = "Ingresa un ID numérico válido."
                    cargando = false
                }
                return
            }
            do {
                let data = try await servicios.obtenerPromociones(
                    establecimientoId: id,
                    tituloContains: filtroTitulo,              // <-- NUEVO
                    descripcionContains: filtroDescripcion     // <-- NUEVO
                )
                await MainActor.run {
                    promos = data
                    cargando = false
                }
                Logger.ccpPrint("Promociones: \(data.count) [id=\(id), título=\(filtroTitulo), desc=\(filtroDescripcion)]")
            } catch {
                await MainActor.run {
                    errorMsg = error.localizedDescription
                    cargando = false
                }
                Logger.ccpPrint("Error promociones: \(error.localizedDescription)")
            }
        }
    }
}
