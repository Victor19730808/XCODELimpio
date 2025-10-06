import SwiftUI
import SwiftData

/// Vista de prueba simplificada para validar la DB incremental
struct ccp_BDF_DBIncrementalTestView: View {
    @EnvironmentObject private var location: LocationService
    @Environment(\.modelContext) private var context

    // Listas separadas para mostrar la diferencia
    @State private var establecimientosConCoordenadas: [lmpBDF_EstablecimientoLocal] = []
    @State private var establecimientosSinCoordenadas: [lmpBDF_EstablecimientoLocal] = []
    @State private var cargando = false
    @State private var msg: String?
    @State private var isError = false
    @State private var mostrarVistaCompletaSinCoordenadas = false
    @State private var mostrarVistaCompletaConCoordenadas = false

    // Corrida masiva
    @State private var cargandoTodos = false
    @State private var bulkCancel = false
    @State private var bulkIndex = 0
    private var bulkTotal: Int { ESTADOS_MX.count }
    @State private var estadoActualEnCarga: String = ""

    private let servicios: Servicios = Servicios()

    private let ESTADOS_MX: [String] = [
        "Aguascalientes","Baja California","Baja California Sur","Campeche","Chiapas",
        "Chihuahua","Ciudad de México","Coahuila","Colima","Durango","Estado de México",
        "Guanajuato","Guerrero","Hidalgo","Jalisco","Michoacán","Morelos","Nayarit",
        "Nuevo León","Oaxaca","Puebla","Querétaro","Quintana Roo","San Luis Potosí",
        "Sinaloa","Sonora","Tabasco","Tamaulipas","Tlaxcala","Veracruz","Yucatán","Zacatecas"
    ]

    private var estadoActivo: String {
        return location.estado
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // ACCIONES PRINCIPALES
                GroupBox("Acciones Principales") {
                    VStack(spacing: 12) {
                        // PRIMERA FILA
                        HStack(spacing: 8) {
                            Button("100 Cercanos") {
                                cargar100MasCercanos()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(cargando || cargandoTodos)
                            
                            Button("Refrescar") {
                                refrescarLista()
                            }
                            .buttonStyle(.bordered)
                            .disabled(cargandoTodos)
                            
                            Button("Borrar", role: .destructive) {
                                borrarTodo()
                            }
                            .buttonStyle(.bordered)
                            .disabled(cargando || cargandoTodos)
                        }
                        
                        // SEGUNDA FILA
                        HStack(spacing: 8) {
                            Button("Cargar Todos") {
                                cargarTodosLosDatos()
                            }
                            .buttonStyle(.bordered)
                            .disabled(cargando || cargandoTodos)
                            
                            Button("Incremental") {
                                cargaIncremental()
                            }
                            .buttonStyle(.bordered)
                            .disabled(cargando || cargandoTodos)
                        }
                        
                        // TERCERA FILA - Diagnóstico
                        HStack(spacing: 8) {
                            Button("Diagnosticar") {
                                diagnosticarBaseDatos()
                            }
                            .buttonStyle(.bordered)
                            .disabled(cargando || cargandoTodos)
                            
                            Button("Buscar Nulos") {
                                buscarCoordenadasNulas()
                            }
                            .buttonStyle(.bordered)
                            .disabled(cargando || cargandoTodos)
                            
                            Button("Verificar Geo") {
                                verificarConsistenciaGeografica()
                            }
                            .buttonStyle(.bordered)
                            .disabled(cargando || cargandoTodos)
                        }
                        
                        if cargandoTodos {
                            Button("Cancelar Carga", role: .cancel) {
                                bulkCancel = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // BARRA DE PROGRESO
                if cargandoTodos {
                    VStack(spacing: 8) {
                        Text("Cargando todos los estados...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ProgressView(value: Double(bulkIndex), total: Double(bulkTotal))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 2.0)
                        
                        Text("\(estadoActualEnCarga) (\(bulkIndex)/\(bulkTotal))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.opacity(0.1))
                    )
                }

                // LISTA DE ESTABLECIMIENTOS CON COORDENADAS
                GroupBox("Establecimientos con Coordenadas (\(establecimientosConCoordenadas.count))") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Con ubicación geográfica")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            
                            if !establecimientosConCoordenadas.isEmpty {
                                Button {
                                    mostrarVistaCompletaConCoordenadas = true
                                } label: {
                                    Image(systemName: "list.bullet")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        
                        if establecimientosConCoordenadas.isEmpty {
                            Text("Sin establecimientos con coordenadas")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 4) {
                                ForEach(establecimientosConCoordenadas.prefix(10)) { e in
                                    HStack(spacing: 8) {
                                        Text("\(e.id)")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(.green)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(e.nombre)
                                                .font(.caption2.bold())
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                            
                                            Text("\(e.municipio ?? "N/A"), \(e.estado ?? "N/A")")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if let lat = e.lat, let lon = e.lon {
                                            VStack(alignment: .trailing, spacing: 1) {
                                                Text(String(format: "%.4f", lat))
                                                    .font(.caption2.bold())
                                                    .foregroundStyle(.green)
                                                Text(String(format: "%.4f", lon))
                                                    .font(.caption2.bold())
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.green.opacity(0.05))
                                    )
                                }
                                
                                if establecimientosConCoordenadas.count > 10 {
                                    Button {
                                        mostrarVistaCompletaConCoordenadas = true
                                    } label: {
                                        Text("Ver todos los \(establecimientosConCoordenadas.count) establecimientos")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.green)
                                    }
                                    .buttonStyle(.bordered)
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                }

                // LISTA DE ESTABLECIMIENTOS SIN COORDENADAS
                GroupBox("Establecimientos sin Coordenadas (\(establecimientosSinCoordenadas.count))") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Sin ubicación geográfica")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            
                            if !establecimientosSinCoordenadas.isEmpty {
                                Button {
                                    mostrarVistaCompletaSinCoordenadas = true
                                } label: {
                                    Image(systemName: "list.bullet")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        
                        if establecimientosSinCoordenadas.isEmpty {
                            Text("Todos los establecimientos tienen coordenadas")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 4) {
                                ForEach(establecimientosSinCoordenadas.prefix(5)) { e in
                                    HStack(spacing: 8) {
                                        Text("\(e.id)")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(.orange)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(e.nombre)
                                                .font(.caption2.bold())
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                            
                                            Text("\(e.municipio ?? "N/A"), \(e.estado ?? "N/A")")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if let categoria = e.categoria {
                                            Text(categoria)
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(
                                                    Capsule()
                                                        .fill(.orange.opacity(0.1))
                                                )
                                        }
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.orange.opacity(0.05))
                                    )
                                }
                                
                                if establecimientosSinCoordenadas.count > 5 {
                                    Button {
                                        mostrarVistaCompletaSinCoordenadas = true
                                    } label: {
                                        Text("Ver todos los \(establecimientosSinCoordenadas.count) establecimientos")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.orange)
                                    }
                                    .buttonStyle(.bordered)
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                }
                
                // Mensaje de estado
                if let msg = msg {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mensaje de Diagnóstico")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        ScrollView {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(isError ? .red : .secondary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isError ? .red.opacity(0.1) : .blue.opacity(0.1))
                        )
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .navigationTitle("DB MORSA ADM")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            location.start()
            refrescarLista()
            cargarAutomaticamenteSiEsNecesario()
        }
        .sheet(isPresented: $mostrarVistaCompletaSinCoordenadas) {
            VistaCompletaSinCoordenadas(establecimientos: establecimientosSinCoordenadas)
        }
        .sheet(isPresented: $mostrarVistaCompletaConCoordenadas) {
            VistaCompletaConCoordenadas(establecimientos: establecimientosConCoordenadas)
        }
    }

    // MARK: - Funciones de carga
    
    private func cargar100MasCercanos() {
        Task {
            cargando = true
            do {
                let n = try await cargarEstablecimientosCercanos()
                await MainActor.run {
                    refrescarLista()
                    isError = false
                    msg = "Cargados \(n) establecimientos más cercanos"
                    cargando = false
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
    
    private func cargarTodosLosDatos() {
        Task {
            cargandoTodos = true
            bulkCancel = false
            bulkIndex = 0
            
            do {
                for (index, estado) in ESTADOS_MX.enumerated() {
                    if bulkCancel { break }
                    
                    await MainActor.run {
                        estadoActualEnCarga = estado
                        bulkIndex = index + 1
                    }
                    
                    let filtros = FiltrosEstablecimientos(estado: estado)
                    let remotos = try await servicios.obtenerEstablecimientos(limit: 1000, filtros: filtros)
                    let _ = try lmpBDF_LocalDBService(context: context).upsert(estabs: remotos)
                }
                
                await MainActor.run {
                    refrescarLista()
                    isError = false
                    msg = "Carga masiva completada. Total: \(bulkIndex) estados procesados"
                    cargandoTodos = false
                }
            } catch {
                await MainActor.run {
                    isError = true
                    msg = "Error en carga masiva: \(error.localizedDescription)"
                    cargandoTodos = false
                }
            }
        }
    }
    
    private func cargaIncremental() {
        Task {
            cargando = true
            do {
                let n = try await cargarIncrementalEstablecimientos()
                await MainActor.run {
                    refrescarLista()
                    isError = false
                    msg = "Carga incremental completada. \(n) registros actualizados"
                    cargando = false
                }
            } catch {
                await MainActor.run {
                    isError = true
                    msg = "Error en carga incremental: \(error.localizedDescription)"
                    cargando = false
                }
            }
        }
    }
    
    private func refrescarLista() {
        do {
            let svc: lmpBDF_LocalDBService = lmpBDF_LocalDBService(context: context)
            let total = try svc.countAll()
            let todos: [lmpBDF_EstablecimientoLocal] = try context.fetch(FetchDescriptor<lmpBDF_EstablecimientoLocal>())
            
            establecimientosConCoordenadas = todos.filter { $0.lat != nil && $0.lon != nil }
            establecimientosSinCoordenadas = todos.filter { $0.lat == nil || $0.lon == nil }
            
            isError = false
            msg = "Total en DB: \(total) · Con coordenadas: \(establecimientosConCoordenadas.count) · Sin coordenadas: \(establecimientosSinCoordenadas.count)"
        } catch {
            isError = true
            msg = "Error al refrescar: \(error.localizedDescription)"
        }
    }
    
    private func borrarTodo() {
        do {
            try lmpBDF_LocalDBService(context: context).deleteAll()
            establecimientosConCoordenadas = []
            establecimientosSinCoordenadas = []
            isError = false
            msg = "Base local vaciada."
        } catch {
            isError = true
            msg = "No se pudo borrar: \(error.localizedDescription)"
        }
    }
    
    private func cargarAutomaticamenteSiEsNecesario() {
        Task {
            do {
                let total = try lmpBDF_LocalDBService(context: context).countAll()
                if total == 0 && !location.estado.isEmpty {
                    _ = try await cargarEstablecimientosCercanos()
                    await MainActor.run {
                        refrescarLista()
                    }
                }
            } catch {
                // Silenciar errores en carga automática
            }
        }
    }
    
    // MARK: - Funciones de carga de datos
    
    private func cargarEstablecimientosCercanos() async throws -> Int {
        guard let latitude = location.latitude, let longitude = location.longitude else {
            throw NSError(domain: "LocationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Ubicación no disponible"])
        }
        
        let filtros = FiltrosEstablecimientos(estado: estadoActivo)
        let remotos = try await servicios.obtenerEstablecimientos(limit: 10000, filtros: filtros)
        
        // Filtrar solo los que tienen coordenadas válidas
        let conCoordenadas = remotos.filter { est in
            guard let lat = est.direccion_latitud, let lon = est.direccion_longitud,
                  lat != 0, lon != 0 else { return false }
            return true
        }
        
        // Calcular distancias y ordenar
        let conDistancia = conCoordenadas.map { est in
            let distancia = calcularDistancia(
                lat1: latitude,
                lon1: longitude,
                lat2: est.direccion_latitud!,
                lon2: est.direccion_longitud!
            )
            return (est, distancia)
        }
        
        let masCercanos = conDistancia
            .sorted { $0.1 < $1.1 }
            .prefix(100)
            .map { $0.0 }
        
        return try lmpBDF_LocalDBService(context: context).upsert(estabs: Array(masCercanos))
    }
    
    private func cargarIncrementalEstablecimientos() async throws -> Int {
        _ = UserDefaults.standard.double(forKey: "ultimaActualizacionIncremental")
        let filtros = FiltrosEstablecimientos(estado: estadoActivo)
        let remotos = try await servicios.obtenerEstablecimientos(limit: 50000, filtros: filtros)
        let n = try lmpBDF_LocalDBService(context: context).upsert(estabs: remotos)
        
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "ultimaActualizacionIncremental")
        return n
    }
    
    private func calcularDistancia(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
    
    // MARK: - Funciones de diagnóstico
    
    private func diagnosticarBaseDatos() {
        do {
            let svc: lmpBDF_LocalDBService = lmpBDF_LocalDBService(context: context)
            let total = try svc.countAll()
            let todos: [lmpBDF_EstablecimientoLocal] = try context.fetch(FetchDescriptor<lmpBDF_EstablecimientoLocal>())
            
            var mensaje = "🔍 DIAGNÓSTICO DE BASE DE DATOS:\n"
            mensaje += "• Total registros: \(total)\n"
            mensaje += "• Establecimientos obtenidos: \(todos.count)\n\n"
            
            if todos.isEmpty {
                mensaje += "❌ NO HAY DATOS EN LA BASE DE DATOS\n"
                mensaje += "• Usa 'Cargar Todos' o '100 Cercanos' para importar datos\n"
            } else {
                let conCoordenadas = todos.filter { $0.lat != nil && $0.lon != nil }
                let sinCoordenadas = todos.filter { $0.lat == nil || $0.lon == nil }
                
                mensaje += "• Con coordenadas: \(conCoordenadas.count)\n"
                mensaje += "• Sin coordenadas: \(sinCoordenadas.count)\n\n"
                
                if sinCoordenadas.isEmpty {
                    mensaje += "✅ TODOS los establecimientos tienen coordenadas\n"
                } else {
                    mensaje += "⚠️ ESTABLECIMIENTOS SIN COORDENADAS (\(sinCoordenadas.count) total):\n\n"
                    mensaje += "🔢 IDs DE ESTABLECIMIENTOS SIN COORDENADAS:\n"
                    let ids = sinCoordenadas.map { $0.id }.sorted()
                    mensaje += "\(ids.map(String.init).joined(separator: ", "))\n\n"
                }
            }
            
            isError = false
            msg = mensaje
            refrescarLista()
            
        } catch {
            isError = true
            msg = "Error en diagnóstico: \(error.localizedDescription)"
        }
    }
    
    private func buscarCoordenadasNulas() {
        do {
            let todos: [lmpBDF_EstablecimientoLocal] = try context.fetch(FetchDescriptor<lmpBDF_EstablecimientoLocal>())
            
            var mensaje = "🔍 BÚSQUEDA EXHAUSTIVA DE COORDENADAS:\n\n"
            mensaje += "• Total de registros analizados: \(todos.count)\n\n"
            
            let latNula = todos.filter { $0.lat == nil }
            let lonNula = todos.filter { $0.lon == nil }
            let ambasNulas = todos.filter { $0.lat == nil && $0.lon == nil }
            let latCero = todos.filter { $0.lat == 0.0 }
            let lonCero = todos.filter { $0.lon == 0.0 }
            let ambasCero = todos.filter { $0.lat == 0.0 && $0.lon == 0.0 }
            
            mensaje += "📊 ANÁLISIS EXHAUSTIVO:\n"
            mensaje += "• Latitud nula: \(latNula.count)\n"
            mensaje += "• Longitud nula: \(lonNula.count)\n"
            mensaje += "• Ambas nulas: \(ambasNulas.count)\n"
            mensaje += "• Latitud = 0: \(latCero.count)\n"
            mensaje += "• Longitud = 0: \(lonCero.count)\n"
            mensaje += "• Ambas = 0: \(ambasCero.count)\n\n"
            
            let problemas = Set(latNula.map { $0.id } + lonNula.map { $0.id } + latCero.map { $0.id } + lonCero.map { $0.id })
            let establecimientosConProblemas = todos.filter { problemas.contains($0.id) }
            
            mensaje += "⚠️ ESTABLECIMIENTOS CON PROBLEMAS DE COORDENADAS (\(establecimientosConProblemas.count) total):\n\n"
            
            if establecimientosConProblemas.isEmpty {
                mensaje += "✅ NO SE ENCONTRARON PROBLEMAS DE COORDENADAS\n"
                mensaje += "• Todos los establecimientos tienen coordenadas válidas\n"
            } else {
                mensaje += "🔢 IDs CON PROBLEMAS:\n"
                let ids = establecimientosConProblemas.map { $0.id }.sorted()
                mensaje += "\(ids.map(String.init).joined(separator: ", "))\n\n"
            }
            
            isError = false
            msg = mensaje
            refrescarLista()
            
        } catch {
            isError = true
            msg = "Error en búsqueda de coordenadas nulas: \(error.localizedDescription)"
        }
    }
    
    private func verificarConsistenciaGeografica() {
        do {
            let todos: [lmpBDF_EstablecimientoLocal] = try context.fetch(FetchDescriptor<lmpBDF_EstablecimientoLocal>())
            
            var mensaje = "🗺️ VERIFICACIÓN DE CONSISTENCIA GEOGRÁFICA:\n\n"
            mensaje += "• Total de registros analizados: \(todos.count)\n\n"
            
            let mexicoLatMin: Double = 14.5
            let mexicoLatMax: Double = 32.7
            let mexicoLonMin: Double = -118.4
            let mexicoLonMax: Double = -86.7
            
            let cdmxLatMin: Double = 19.0
            let cdmxLatMax: Double = 19.6
            let cdmxLonMin: Double = -99.4
            let cdmxLonMax: Double = -98.9
            
            var inconsistencias: [lmpBDF_EstablecimientoLocal] = []
            var fueraDeMexico: [lmpBDF_EstablecimientoLocal] = []
            
            for est in todos {
                guard let lat = est.lat, let lon = est.lon else { continue }
                
                if lat < mexicoLatMin || lat > mexicoLatMax || lon < mexicoLonMin || lon > mexicoLonMax {
                    fueraDeMexico.append(est)
                    continue
                }
                
                let estado = est.estado?.lowercased() ?? ""
                if estado.contains("ciudad") || estado.contains("méxico") || estado.contains("mexico") {
                    if lat < cdmxLatMin || lat > cdmxLatMax || lon < cdmxLonMin || lon > cdmxLonMax {
                        inconsistencias.append(est)
                    }
                }
            }
            
            mensaje += "📊 ANÁLISIS DE CONSISTENCIA:\n"
            mensaje += "• Inconsistencias geográficas: \(inconsistencias.count)\n"
            mensaje += "• Fuera del territorio mexicano: \(fueraDeMexico.count)\n\n"
            
            if !inconsistencias.isEmpty {
                mensaje += "⚠️ INCONSISTENCIAS GEOGRÁFICAS (\(inconsistencias.count) total):\n\n"
                let ids = inconsistencias.map { $0.id }.sorted()
                mensaje += "🔢 IDs CON INCONSISTENCIAS:\n"
                mensaje += "\(ids.map(String.init).joined(separator: ", "))\n\n"
            }
            
            if !fueraDeMexico.isEmpty {
                mensaje += "🌍 FUERA DEL TERRITORIO MEXICANO (\(fueraDeMexico.count) total):\n\n"
                let ids = fueraDeMexico.map { $0.id }.sorted()
                mensaje += "🔢 IDs FUERA DE MÉXICO:\n"
                mensaje += "\(ids.map(String.init).joined(separator: ", "))\n\n"
            }
            
            if inconsistencias.isEmpty && fueraDeMexico.isEmpty {
                mensaje += "✅ TODAS LAS COORDENADAS SON CONSISTENTES\n"
            }
            
            isError = false
            msg = mensaje
            refrescarLista()
            
        } catch {
            isError = true
            msg = "Error en verificación geográfica: \(error.localizedDescription)"
        }
    }
}

// MARK: - Vistas de pantalla completa

struct VistaCompletaSinCoordenadas: View {
    let establecimientos: [lmpBDF_EstablecimientoLocal]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(establecimientos) { establecimiento in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(establecimiento.id)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.orange)
                            )
                        
                        Text(establecimiento.nombre)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                    
                    Text("\(establecimiento.municipio ?? "N/A"), \(establecimiento.estado ?? "N/A")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let categoria = establecimiento.categoria {
                        Text("Categoría: \(categoria)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.orange.opacity(0.05))
                )
            }
            .navigationTitle("Establecimientos sin Coordenadas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VistaCompletaConCoordenadas: View {
    let establecimientos: [lmpBDF_EstablecimientoLocal]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(establecimientos) { establecimiento in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(establecimiento.id)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.green)
                            )
                        
                        Text(establecimiento.nombre)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                    
                    Text("\(establecimiento.municipio ?? "N/A"), \(establecimiento.estado ?? "N/A")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let lat = establecimiento.lat, let lon = establecimiento.lon {
                        Text("Coordenadas: \(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.green.opacity(0.05))
                )
            }
            .navigationTitle("Establecimientos con Coordenadas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
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
