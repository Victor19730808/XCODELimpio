//
//  ccp_DB_SeedAndBrowseView.swift (PATCH 4)
//  - Botón "Insertar mock" para validar DB local sin red.
//  - Mensajes de error en rojo y más detalle de diagnóstico.
//

import SwiftUI
import SwiftData

public struct ccp_DB_SeedAndBrowseView: View {
    @Environment(\.modelContext) private var context

    @State private var endpoint: String = "https://canacocard-ms-backend.azurewebsites.net/api/evento/1/establecimientos/10000"
    @State private var isLoading: Bool = false
    @State private var message: String? = nil
    @State private var isError: Bool = false

    @State private var filtroNombre: String = ""
    @State private var filtroMunicipio: String = ""
    @State private var filtroEstado: String = ""

    @State private var resultados: [EstablecimientoLocal] = []

    private let api = DBAPIClient()

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            GroupBox("Descarga y carga en DB") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Endpoint API", text: $endpoint)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    HStack {
                        Button { Task { await seed() } } label: {
                            Label("Descargar y guardar", systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent).disabled(isLoading)

                        Button(role: .destructive) {
                            do {
                                try LocalDBService(context: context).deleteAll()
                                isError = false; message = "Base limpia."; resultados.removeAll()
                            } catch { isError = true; message = error.localizedDescription }
                        } label: { Label("Borrar todo", systemImage: "trash") }
                        .buttonStyle(.bordered).disabled(isLoading)

                        Button { Task { await buscar() } } label: {
                            Label("Contar/Buscar", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.bordered).disabled(isLoading)

                        Button { insertMock() } label: {
                            Label("Insertar mock", systemImage: "plus.circle")
                        }
                        .buttonStyle(.bordered)
                    }

                    if isLoading { ProgressView().padding(.top, 4) }
                    if let message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(isError ? .red : .secondary)
                            .textSelection(.enabled)
                            .lineLimit(5)
                    }
                }
            }

            GroupBox("Filtros rápidos") {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        TextField("Nombre contiene…", text: $filtroNombre).textFieldStyle(.roundedBorder)
                        TextField("Municipio…", text: $filtroMunicipio).textFieldStyle(.roundedBorder)
                        TextField("Estado…", text: $filtroEstado).textFieldStyle(.roundedBorder)
                        Button { Task { await buscar() } } label: { Label("Aplicar", systemImage: "line.3.horizontal.decrease.circle") }
                            .buttonStyle(.bordered)
                    }
                }
            }

            if resultados.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").font(.largeTitle)
                    Text("Sin resultados").font(.headline)
                    Text("Usa los filtros o descarga desde la API.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(resultados) { e in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.nombre).font(.headline)
                        HStack(spacing: 8) {
                            Text(e.municipio ?? "?"); Text("·"); Text(e.estado ?? "?")
                            if let lat = e.lat, let lon = e.lon {
                                Text("· (\(String(format: "%.4f", lat)), \(String(format: "%.4f", lon)))")
                            }
                        }.font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Seed & Browse")
        .task { await buscar() }
    }

    private func seed() async {
        isLoading = true; isError = false; defer { isLoading = false }
        do {
            let remotos = try await api.fetchEstablecimientos(from: endpoint)
            message = "Descargados: \(remotos.count). Guardando…"
            let count = try LocalDBService(context: context).upsert(estabs: remotos)
            message = "Insertados/Actualizados: \(count)"; isError = false
            await buscar()
        } catch {
            isError = true
            message = "Error: \(error.localizedDescription)"
        }
    }

    private func buscar() async {
        do {
            resultados = try LocalDBService(context: context)
                .search(nombreContains: filtroNombre, municipio: filtroMunicipio, estado: filtroEstado, limit: 300)
            let total = try LocalDBService(context: context).count()
            isError = false
            message = "Total en DB: \(total). Mostrando: \(resultados.count)"
        } catch { isError = true; message = "Error: \(error.localizedDescription)" }
    }

    private func insertMock() {
        let base = [
            EstablecimientoRemote(registro_evento_id: 1, establecimiento_id: 900001, establecimiento_nombre: "Demo Chio Deportes", direccion_completa: "Altamirano 17, Centro", direccion_municipio: "Xalapa", direccion_estado: "Veracruz", direccion_latitud: "19.0", direccion_longitud: "-96.9", categoria_id: 1, categoria_nombre: "Deportes"),
            EstablecimientoRemote(registro_evento_id: 1, establecimiento_id: 900002, establecimiento_nombre: "Demo La Parrilla", direccion_completa: "Av. Siempre Viva 742", direccion_municipio: "CDMX", direccion_estado: "CDMX", direccion_latitud: "19.4", direccion_longitud: "-99.1", categoria_id: 2, categoria_nombre: "Restaurante"),
            EstablecimientoRemote(registro_evento_id: 1, establecimiento_id: 900003, establecimiento_nombre: "Demo Librería Hidalgo", direccion_completa: "Hidalgo 123", direccion_municipio: "Guadalajara", direccion_estado: "Jalisco", direccion_latitud: "20.6", direccion_longitud: "-103.3", categoria_id: 3, categoria_nombre: "Librería")
        ]
        do {
            let n = try LocalDBService(context: context).upsert(estabs: base)
            message = "Insertados mock: \(n)"; isError = false
            Task { await buscar() }
        } catch {
            isError = true; message = "Mock error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack { ccp_DB_SeedAndBrowseView() }
        .modelContainer(for: [EstablecimientoLocal.self], inMemory: true)
}