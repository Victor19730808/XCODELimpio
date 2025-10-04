import SwiftUI
import SwiftData

/// Vista de prueba (ccp) para validar la DB incremental:
/// - Permite importar por el estado detectado por ubicación.
/// - Permite importar manualmente por cualquiera de los 32 estados de México.
/// - Permite importar **todos** los estados en una corrida masiva (con progreso y cancelación).
/// - Lista lo guardado para el estado actualmente seleccionado (manual o ubicación).
struct ccp_BDF_DBIncrementalTestView: View {
    @EnvironmentObject private var location: LocationService
    @Environment(\.modelContext) private var context

    // Lista local mostrada (para el estado activo)
    @State private var mostrando: [lmpBDF_EstablecimientoLocal] = []
    @State private var cargando = false               // carga individual
    @State private var msg: String?
    @State private var isError = false

    // Estado elegido manualmente (si está vacío, se usa el de LocationService)
    @State private var estadoManual: String = ""

    // Corrida masiva (todos los estados)
    @State private var cargandoTodos = false
    @State private var bulkCancel = false
    @State private var bulkIndex = 0
    private var bulkTotal: Int { ESTADOS_MX.count }
    @State private var estadoActualEnCarga: String = ""

    private let servicios = Servicios()

    private let ESTADOS_MX: [String] = [
        "Aguascalientes","Baja California","Baja California Sur","Campeche","Chiapas",
        "Chihuahua","Ciudad de México","Coahuila","Colima","Durango","Estado de México",
        "Guanajuato","Guerrero","Hidalgo","Jalisco","Michoacán","Morelos","Nayarit",
        "Nuevo León","Oaxaca","Puebla","Querétaro","Quintana Roo","San Luis Potosí",
        "Sinaloa","Sonora","Tabasco","Tamaulipas","Tlaxcala","Veracruz","Yucatán","Zacatecas"
    ]

    // Estado “activo” = manual si está elegido, si no, el de ubicación
    private var estadoActivo: String {
        if !estadoManual.isEmpty { return estadoManual }
        return location.estado
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prueba · DB Incremental (ccp)")
                .font(.title3.bold())

            // ACCIONES PRINCIPALES
            GroupBox("Acciones rápidas") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Button {
                            guardarIncrementales(para: location.estado)
                        } label: {
                            Label("Guardar (mi estado)", systemImage: "location.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(cargando || cargandoTodos || location.estado.isEmpty)

                        Button {
                            refrescarLista()
                        } label: {
                            Label("Refrescar", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .disabled(cargandoTodos)

                        Button(role: .destructive) {
                            borrarTodo()
                        } label: {
                            Label("Borrar todo", systemImage: "trash.fill")
                        }
                        .buttonStyle(.bordered)
                        .disabled(cargando || cargandoTodos)
                    }

                    // Botón NUEVO: Cargar TODOS los estados
                    HStack(spacing: 10) {
                        Button {
                            iniciarCargaTodosLosEstados()
                        } label: {
                            Label("Cargar TODOS los estados", systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(cargando || cargandoTodos)

                        if cargandoTodos {
                            Button(role: .cancel) {
                                bulkCancel = true
                            } label: {
                                Label("Cancelar", systemImage: "xmark.circle")
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // Progreso visual de la corrida masiva
                    if cargandoTodos {
                        VStack(alignment: .leading, spacing: 6) {
                            ProgressView(value: Double(bulkIndex), total: Double(bulkTotal))
                            Text("Importando \(estadoActualEnCarga)  •  \(bulkIndex)/\(bulkTotal)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)
                    }

                    if cargando { ProgressView().padding(.top, 2) }

                    Text("Estado por ubicación: \(location.estado.isEmpty ? "—" : location.estado)")
                        .font(.footnote).foregroundStyle(.secondary)

                    if let msg {
                        Text(msg)
                            .font(.footnote)
                            .foregroundStyle(isError ? .red : .secondary)
                            .textSelection(.enabled)
                            .lineLimit(8)
                    }
                }
            }

            // ESTADOS DE PRUEBA (MANUAL)
            GroupBox("Estados de la República — pruebas manuales") {
                VStack(alignment: .leading, spacing: 8) {
                    // Picker del estado manual (útil en simulador)
                    Picker("Selecciona un estado", selection: $estadoManual) {
                        Text("— Ninguno (usar ubicación) —").tag("")
                        ForEach(ESTADOS_MX, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .disabled(cargandoTodos)

                    HStack(spacing: 10) {
                        Button {
                            guardarIncrementales(para: estadoManual)
                        } label: {
                            Label("Guardar (estado elegido)", systemImage: "tray.and.arrow.down.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(cargando || cargandoTodos || estadoManual.isEmpty)

                        Button {
                            refrescarLista()
                        } label: {
                            Label("Ver en DB", systemImage: "eye")
                        }
                        .buttonStyle(.bordered)
                        .disabled(cargandoTodos)
                    }

                    Text("Estado activo para la lista: \(estadoActivo.isEmpty ? "—" : estadoActivo)")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            // LISTA DE LO GUARDADO (PARA EL ESTADO ACTIVO)
            GroupBox("Establecimientos guardados (estado activo)") {
                if mostrando.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                        Text("Sin datos guardados para este estado")
                            .font(.headline)
                        Text("Usa alguno de los botones Guardar para importar.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 160)
                } else {
                    List(mostrando) { e in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.nombre).font(.headline)
                            Text("\(e.municipio ?? "?"), \(e.estado ?? "?") · \(e.categoria ?? "-")")
                                .font(.caption).foregroundStyle(.secondary)
                            if let lat = e.lat, let lon = e.lon {
                                Text(String(format: "Lat/Lon: %.5f, %.5f", lat, lon))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle("DB Incremental (ccp)")
        .onAppear {
            location.start()
            refrescarLista()
        }
    }

    // MARK: - Acciones públicas (botones)

    /// Guarda incrementalmente los establecimientos de un estado dado (modo individual).
    /// Si `estado` es vacío, no hace nada.
    private func guardarIncrementales(para estado: String) {
        guard !estado.isEmpty else {
            isError = true
            msg = "Define un estado (manual) o espera a la ubicación."
            return
        }
        cargando = true
        isError = false
        msg = "Consultando servicio para \(estado)…"

        Task {
            do {
                let insertados = try await cargarEstado(estado)
                await MainActor.run {
                    msg = "Insertados/actualizados: \(insertados) en \(estado)"
                    cargando = false
                    if estado == estadoActivo { refrescarLista() }
                }
            } catch {
                await MainActor.run {
                    isError = true
                    msg = "Error: \(error.localizedDescription)"
                    cargando = false
                }
            }
        }
    }

    /// Inicia corrida masiva sobre los 32 estados (con progreso y cancelación).
    private func iniciarCargaTodosLosEstados() {
        guard !cargando && !cargandoTodos else { return }
        cargandoTodos = true
        bulkCancel = false
        bulkIndex = 0
        estadoActualEnCarga = ""
        isError = false
        msg = "Iniciando importación masiva de \(bulkTotal) estados…"

        Task {
            var totalInsertados = 0
            var errores: [(String, String)] = []  // (estado, mensaje)

            for (i, edo) in ESTADOS_MX.enumerated() {
                if bulkCancel { break }
                await MainActor.run {
                    estadoActualEnCarga = edo
                    bulkIndex = i
                    msg = "Importando \(edo)… (\(i+1)/\(bulkTotal))"
                }
                do {
                    let n = try await cargarEstado(edo)
                    totalInsertados += n
                } catch {
                    errores.append((edo, error.localizedDescription))
                }
                // Pequeño respiro para no saturar (opcional)
                try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s
            }

            await MainActor.run {
                cargandoTodos = false
                estadoActualEnCarga = ""
                bulkIndex = bulkTotal
                if bulkCancel {
                    msg = "Importación masiva cancelada por el usuario. Insertados acumulados: \(totalInsertados)."
                } else if errores.isEmpty {
                    msg = "Importación masiva finalizada. Insertados/actualizados acumulados: \(totalInsertados)."
                } else {
                    let listado = errores.prefix(6).map { "• \($0.0): \($0.1)" }.joined(separator: "\n")
                    msg = """
                    Importación masiva terminada con algunos errores.
                    Insertados/actualizados: \(totalInsertados)
                    Errores (\(errores.count)):
                    \(listado)
                    """
                    isError = true
                }
                // Refresca la lista del estado activo si aplica
                refrescarLista()
            }
        }
    }

    // MARK: - Lógica reusable

    /// Carga (consulta WS + upsert) para **un** estado. Devuelve el número de filas insertadas/actualizadas.
    private func cargarEstado(_ estado: String) async throws -> Int {
        let filtros = FiltrosEstablecimientos(estado: estado)
        let remotos = try await servicios.obtenerEstablecimientos(filtros: filtros)
        let n = try lmpBDF_LocalDBService(context: context).upsert(estabs: remotos)
        return n
    }

    /// Vuelve a consultar la DB local para el estado activo (manual si hay, de lo contrario el de ubicación).
    private func refrescarLista() {
        guard !estadoActivo.isEmpty else {
            mostrando = []
            msg = "Sin estado activo para listar."
            return
        }
        do {
            let svc = lmpBDF_LocalDBService(context: context)
            mostrando = try svc.fetchByEstado(estadoActivo, limit: 800)
            let total = try svc.countAll()
            isError = false
            msg = "Total en DB (todos los estados): \(total) · Mostrando \(mostrando.count) de \(estadoActivo)"
        } catch {
            isError = true
            msg = "Error al refrescar: \(error.localizedDescription)"
        }
    }

    /// Borra toda la base local (pruebas).
    private func borrarTodo() {
        do {
            try lmpBDF_LocalDBService(context: context).deleteAll()
            mostrando = []
            isError = false
            msg = "Base local vaciada."
        } catch {
            isError = true
            msg = "No se pudo borrar: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        ccp_BDF_DBIncrementalTestView()
            .environmentObject(LocationService())
            .modelContainer(for: [lmpBDF_EstablecimientoLocal.self], inMemory: true)
    }
}
