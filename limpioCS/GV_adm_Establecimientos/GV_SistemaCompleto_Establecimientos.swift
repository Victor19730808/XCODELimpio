import Foundation
import SwiftData
import SwiftUI

// MARK: - ✅ MODELO DE DATOS
@Model
final class GV_modeloCont_Establecimientos {
    @Attribute(.unique) var establecimiento_id: Int
    var user_id: Int?
    var usuario_id: Int?
    var indice_id: Int?
    var registro_evento_id: Int?
    var establecimiento_nombre: String
    var establecimiento_logo: String?
    var establecimiento_url: String?
    var usuario_phone_number: String?
    var usuario_email: String?
    var direccion_completa: String?
    var direccion_municipio: String?
    var direccion_estado: String?
    var direccion_latitud: Double?
    var direccion_longitud: Double?
    var categoria_id: Int?
    var categoria_nombre: String?
    
    init(
        establecimiento_id: Int,
        user_id: Int? = nil,
        usuario_id: Int? = nil,
        indice_id: Int? = nil,
        registro_evento_id: Int? = nil,
        establecimiento_nombre: String,
        establecimiento_logo: String? = nil,
        establecimiento_url: String? = nil,
        usuario_phone_number: String? = nil,
        usuario_email: String? = nil,
        direccion_completa: String? = nil,
        direccion_municipio: String? = nil,
        direccion_estado: String? = nil,
        direccion_latitud: Double? = nil,
        direccion_longitud: Double? = nil,
        categoria_id: Int? = nil,
        categoria_nombre: String? = nil
    ) {
        self.establecimiento_id = establecimiento_id
        self.user_id = user_id
        self.usuario_id = usuario_id
        self.indice_id = indice_id
        self.registro_evento_id = registro_evento_id
        self.establecimiento_nombre = establecimiento_nombre
        self.establecimiento_logo = establecimiento_logo
        self.establecimiento_url = establecimiento_url
        self.usuario_phone_number = usuario_phone_number
        self.usuario_email = usuario_email
        self.direccion_completa = direccion_completa
        self.direccion_municipio = direccion_municipio
        self.direccion_estado = direccion_estado
        self.direccion_latitud = direccion_latitud
        self.direccion_longitud = direccion_longitud
        self.categoria_id = categoria_id
        self.categoria_nombre = categoria_nombre
    }
}

// MARK: - ✅ SISTEMA DE SINCRONIZACIÓN
final class GV_ep_Establecimientos {
    
    enum ModoCargaBD: String {
        case full, add, inc
    }
    
    enum OrdenResultados: String {
        case asc, desc
    }
    
    enum TipoRegreso: String {
        case id, full
    }
    
    private let modelContext: ModelContext
    private var errorCounter: Int = 1000
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func Load_API_Stream_EstabalecimeintosV(xEndPoint: String, xNo: Int) -> (resultado: String, codigoError: Int) {
        let url = "\(xEndPoint)/\(xNo)"
        guard let requestURL = URL(string: url) else {
            return ("Error: URL inválida", -1)
        }
        
        do {
            let (data, response) = try URLSession.shared.synchronousDataTask(with: requestURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                return ("Error HTTP", -1)
            }
            
            guard let jsonString = String(data: data, encoding: .utf8) else {
                return ("Error: No se pudo convertir respuesta", -1)
            }
            
            return (jsonString, 0)
            
        } catch {
            return ("Error de red: \(error.localizedDescription)", -1)
        }
    }
    
    func Load_Stream_BDL(xStream: String, flagIncremental: ModoCargaBD) -> (resultado: String, codigoError: Int) {
        let fechaInicio = obtenerFechaFormateada()
        
        do {
            guard let data = xStream.data(using: .utf8),
                  let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return ("Error: JSON inválido", -1)
            }
            
            // Variables para tracking de errores
            var insertados = 0
            var actualizados = 0
            var errores = 0
            var duplicados: [Int: Int] = [:] // ID -> cantidad de veces
            
            switch flagIncremental {
            case .full:
                print("🗑️ MODO FULL: Borrando registros existentes...")
                // Borrar todos
                let descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>()
                let existentes = try modelContext.fetch(descriptor)
                print("🗑️ Registros existentes encontrados: \(existentes.count)")
                for est in existentes {
                    modelContext.delete(est)
                }
                
                print("➕ Insertando \(jsonArray.count) nuevos registros...")
                
                // Primero, analizar duplicados en el JSON del API
                var idsProcesados: Set<Int> = []
                for json in jsonArray {
                    if let id = json["establecimiento_id"] as? Int {
                        if idsProcesados.contains(id) {
                            duplicados[id, default: 0] += 1
                        } else {
                            idsProcesados.insert(id)
                        }
                    }
                }
                
                // Insertar nuevos uno por uno para evitar conflictos
                for (index, json) in jsonArray.enumerated() {
                    do {
                        if let est = try? crearEstablecimientoDesdeJSON(json) {
                            // Verificar si ya existe antes de insertar
                            let descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>()
                            let todos = try modelContext.fetch(descriptor)
                            let existentes = todos.filter { $0.establecimiento_id == est.establecimiento_id }
                            
                            if existentes.isEmpty {
                                modelContext.insert(est)
                                try modelContext.save() // Guardar inmediatamente
                                insertados += 1
                                if index < 3 { // Log de los primeros 3
                                    print("   ✅ Insertado #\(index + 1): ID \(est.establecimiento_id) - \(est.establecimiento_nombre)")
                                }
                            } else {
                                print("   ⚠️ Duplicado en BD #\(index + 1): ID \(est.establecimiento_id) ya existe")
                            }
                        } else {
                            errores += 1
                            print("   ❌ Error creando registro #\(index + 1)")
                        }
                    } catch {
                        errores += 1
                        print("   ❌ Error insertando registro #\(index + 1): \(error.localizedDescription)")
                    }
                }
                print("📊 Total insertados: \(insertados) de \(jsonArray.count) | Errores: \(errores)")
                
            case .add:
                print("➕ MODO ADD: Agregando registros...")
                for json in jsonArray {
                    if let est = try? crearEstablecimientoDesdeJSON(json) {
                        modelContext.insert(est)
                        insertados += 1
                    } else {
                        errores += 1
                    }
                }
                print("📊 Modo ADD - Insertados: \(insertados) | Errores: \(errores)")
                
            case .inc:
                print("🔄 MODO INC: Actualizando/Insertando registros...")
                let descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>()
                let existentes = try modelContext.fetch(descriptor)
                let existentesPorId = Dictionary(uniqueKeysWithValues: existentes.map { ($0.establecimiento_id, $0) })
                
                for json in jsonArray {
                    let id = json["establecimiento_id"] as? Int ?? -1
                    if let existente = existentesPorId[id] {
                        actualizarEstablecimiento(existente, desde: json)
                        actualizados += 1
                    } else if let nuevo = try? crearEstablecimientoDesdeJSON(json) {
                        modelContext.insert(nuevo)
                        insertados += 1
                    } else {
                        errores += 1
                    }
                }
                print("📊 Modo INC - Actualizados: \(actualizados) | Insertados: \(insertados) | Errores: \(errores)")
            }
            
            print("💾 Contexto ya guardado individualmente...")
            print("✅ Proceso completado")
            
            // Verificar que se guardó
            let verificacion = try modelContext.fetch(FetchDescriptor<GV_modeloCont_Establecimientos>())
            print("🔍 Verificación post-guardado: \(verificacion.count) registros en BD")
            
            let fechaFin = obtenerFechaFormateada()
            let codigoResultado = errores > 0 ? -2 : 0 // -2 = error parcial, 0 = éxito total
            
            // 1ERA PARTE: Resumen general
            let resumenGeneral = errores > 0 ? 
                "⚠️ Carga PARCIAL\nInicio: \(fechaInicio)\nFin: \(fechaFin)\nRegistros procesados: \(jsonArray.count)\n✅ Insertados: \(insertados)\n🔄 Actualizados: \(actualizados)\n❌ Errores: \(errores)\nVerificación: \(verificacion.count) en BD" :
                "✅ Carga exitosa\nInicio: \(fechaInicio)\nFin: \(fechaFin)\nRegistros procesados: \(jsonArray.count)\n✅ Insertados: \(insertados)\n🔄 Actualizados: \(actualizados)\nVerificación: \(verificacion.count) en BD"
            
            // 2DA PARTE: Lista de registros en formato CSV
            var listaRegistros = "\n\n📋 LISTA DE REGISTROS INSERTADOS (CSV):\n"
            let descriptorConsulta = FetchDescriptor<GV_modeloCont_Establecimientos>(sortBy: [SortDescriptor(\GV_modeloCont_Establecimientos.establecimiento_id, order: .forward)])
            let registrosInsertados = try modelContext.fetch(descriptorConsulta)
            
            for (index, est) in registrosInsertados.enumerated() {
                let municipio = est.direccion_municipio ?? "N/A"
                let estado = est.direccion_estado ?? "N/A"
                let categoria = est.categoria_nombre ?? "N/A"
                listaRegistros += "\(index + 1). \(est.establecimiento_id), \(est.establecimiento_nombre), \(municipio), \(estado), \(categoria)\n"
            }
            
            // 3ERA PARTE: Análisis de duplicados
            var analisisDuplicados = ""
            if !duplicados.isEmpty {
                analisisDuplicados = "\n\n📊 ANÁLISIS DE DUPLICADOS:\n"
                let duplicadosOrdenados = duplicados.sorted { $0.value > $1.value }
                for (id, cantidad) in duplicadosOrdenados {
                    analisisDuplicados += "ID \(id) - \(cantidad) veces\n"
                }
            } else {
                analisisDuplicados = "\n\n📊 ANÁLISIS DE DUPLICADOS:\n✅ No se encontraron duplicados en el JSON del API"
            }
            
            // 4TA PARTE: Análisis de errores
            var analisisErrores = ""
            if errores > 0 {
                analisisErrores = "\n\n❌ ANÁLISIS DE ERRORES:\n"
                analisisErrores += "Total de errores: \(errores)\n"
                analisisErrores += "Tipo: Errores de creación/inserción de registros\n"
                analisisErrores += "Recomendación: Revisar logs de consola para detalles específicos"
            } else {
                analisisErrores = "\n\n✅ ANÁLISIS DE ERRORES:\n✅ No se encontraron errores durante el proceso"
            }
            
            // Combinar todas las partes
            let mensajeResultado = resumenGeneral + listaRegistros + analisisDuplicados + analisisErrores
            
            return (mensajeResultado, codigoResultado)
            
        } catch {
            return ("Error: \(error.localizedDescription)", -1)
        }
    }
    
    func Limpiar_BaseDatos() -> (resultado: String, codigoError: Int) {
        let fechaInicio = obtenerFechaFormateada()
        
        do {
            let descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>()
            let existentes = try modelContext.fetch(descriptor)
            let totalRegistros = existentes.count
            
            print("🗑️ LIMPIEZA: Borrando \(totalRegistros) registros...")
            
            for est in existentes {
                modelContext.delete(est)
            }
            
            try modelContext.save()
            
            let fechaFin = obtenerFechaFormateada()
            let mensaje = """
            ✅ BASE DE DATOS LIMPIADA
            Inicio: \(fechaInicio)
            Fin: \(fechaFin)
            Registros eliminados: \(totalRegistros)
            Estado: Base de datos vacía
            """
            
            print("✅ Limpieza completada: \(totalRegistros) registros eliminados")
            
            return (mensaje, 0)
            
        } catch {
            let mensaje = """
            ❌ ERROR AL LIMPIAR BASE DE DATOS
            Inicio: \(fechaInicio)
            Error: \(error.localizedDescription)
            """
            print("❌ Error limpiando BD: \(error.localizedDescription)")
            return (mensaje, -1)
        }
    }
    
    func Get_Establecimientos(xNo: Int, incDec: OrdenResultados, cRegresa: TipoRegreso) -> (resultado: String, codigoError: Int) {
        do {
            let sortDescriptor = SortDescriptor(\GV_modeloCont_Establecimientos.establecimiento_id, order: incDec == .asc ? .forward : .reverse)
            let descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>(sortBy: [sortDescriptor])
            let establecimientos = try modelContext.fetch(descriptor)
            let resultados = Array(establecimientos.prefix(xNo))
            
            if resultados.isEmpty {
                return ("⚠️ BASE DE DATOS VACÍA\nNo hay registros para mostrar.\nPrimero debes cargar datos desde el API.", -1)
            }
            
            let fecha = obtenerFechaFormateada()
            var texto = "📊 ESTABLECIMIENTOS EN BD - \(fecha)\n"
            texto += "📈 Total: \(resultados.count) | Orden: \(incDec.rawValue.uppercased()) | Tipo: \(cRegresa.rawValue.uppercased())\n\n"
            
            for (index, est) in resultados.enumerated() {
                if cRegresa == .id {
                    // Solo ID - formato simple con numerador
                    texto += "\(index + 1). \(est.establecimiento_id)\n"
                } else {
                    // Formato CSV completo: ID, Nombre, Municipio, Estado, Categoría, Latitud, Longitud con numerador
                    let municipio = est.direccion_municipio ?? "N/A"
                    let estado = est.direccion_estado ?? "N/A"
                    let categoria = est.categoria_nombre ?? "N/A"
                    let latitud = est.direccion_latitud != nil ? String(est.direccion_latitud!) : "N/A"
                    let longitud = est.direccion_longitud != nil ? String(est.direccion_longitud!) : "N/A"
                    
                    texto += "\(index + 1). \(est.establecimiento_id), \(est.establecimiento_nombre), \(municipio), \(estado), \(categoria), \(latitud), \(longitud)\n"
                }
            }
            
            texto += "\n✅ CONSULTA COMPLETADA"
            
            return (texto, 0)
            
        } catch {
            return ("❌ ERROR EN CONSULTA\n\(error.localizedDescription)", -1)
        }
    }
    
    /// Genera JSON para el archivo seed desde la BD actual
    /// Retorna JSON listo para copiar y pegar en establecimientos_seed.json
    /// - Parameter limite: Número de registros a incluir. Si es 0 o nil, trae TODOS
    func Generar_Seed_JSON(limite: Int = 0) -> (jsonString: String, totalRegistros: Int, registrosConCoordenadas: Int, codigoError: Int) {
        do {
            let descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>(sortBy: [SortDescriptor(\GV_modeloCont_Establecimientos.establecimiento_id)])
            let todosLosEstablecimientos = try modelContext.fetch(descriptor)
            
            if todosLosEstablecimientos.isEmpty {
                return ("[]", 0, 0, -1)
            }
            
            // Si limite es 0 o negativo, tomar TODOS. Si no, tomar solo 'limite' registros
            let establecimientos = (limite > 0) ? Array(todosLosEstablecimientos.prefix(limite)) : todosLosEstablecimientos
            
            var registrosConCoordenadas = 0
            var jsonArray: [[String: Any]] = []
            
            for est in establecimientos {
                var registro: [String: Any] = [
                    "establecimiento_id": est.establecimiento_id,
                    "establecimiento_nombre": est.establecimiento_nombre
                ]
                
                // Agregar campos opcionales solo si existen
                if let userId = est.user_id { registro["user_id"] = userId }
                if let usuarioId = est.usuario_id { registro["usuario_id"] = usuarioId }
                if let indiceId = est.indice_id { registro["indice_id"] = indiceId }
                if let eventoId = est.registro_evento_id { registro["registro_evento_id"] = eventoId }
                if let logo = est.establecimiento_logo { registro["establecimiento_logo"] = logo }
                if let url = est.establecimiento_url { registro["establecimiento_url"] = url }
                if let phone = est.usuario_phone_number { registro["usuario_phone_number"] = phone }
                if let email = est.usuario_email { registro["usuario_email"] = email }
                if let direccion = est.direccion_completa { registro["direccion_completa"] = direccion }
                if let municipio = est.direccion_municipio { registro["direccion_municipio"] = municipio }
                if let estado = est.direccion_estado { registro["direccion_estado"] = estado }
                
                // ⭐️ COORDENADAS - Lo más importante
                if let lat = est.direccion_latitud {
                    registro["direccion_latitud"] = lat
                    if let lon = est.direccion_longitud {
                        registro["direccion_longitud"] = lon
                        registrosConCoordenadas += 1
                    }
                }
                
                if let categoriaId = est.categoria_id { registro["categoria_id"] = categoriaId }
                if let categoriaNombre = est.categoria_nombre { registro["categoria_nombre"] = categoriaNombre }
                
                jsonArray.append(registro)
            }
            
            // Convertir a JSON
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "[]"
            
            let limiteTexto = (limite > 0) ? "primeros \(limite)" : "TODOS (\(todosLosEstablecimientos.count))"
            print("🌱 SEED JSON GENERADO:")
            print("   📊 Total en BD: \(todosLosEstablecimientos.count)")
            print("   📝 Registros en seed: \(establecimientos.count) - \(limiteTexto)")
            print("   📍 Con coordenadas: \(registrosConCoordenadas)")
            print("   📦 Tamaño JSON: \(jsonString.count) caracteres")
            
            return (jsonString, establecimientos.count, registrosConCoordenadas, 0)
            
        } catch {
            print("❌ ERROR generando seed JSON: \(error.localizedDescription)")
            return ("[]", 0, 0, -1)
        }
    }
    
    // MARK: - Helpers
    
    private func crearEstablecimientoDesdeJSON(_ json: [String: Any]) throws -> GV_modeloCont_Establecimientos {
        guard let id = json["establecimiento_id"] as? Int else {
            throw NSError(domain: "", code: 1001, userInfo: [NSLocalizedDescriptionKey: "ID faltante"])
        }
        
        // 🔍 DEBUGGING: Logs desactivados para producción
        // Si necesitas reactivar los logs para debugging, descomenta las líneas siguientes:
        /*
        let nombre = json["establecimiento_nombre"] as? String ?? "Sin nombre"
        print("🔍 [DEBUG] Procesando: \(nombre) (ID: \(id))")
        let latRaw = json["direccion_latitud"]
        let lonRaw = json["direccion_longitud"]
        print("🔍 [DEBUG] Lat raw: \(latRaw ?? "nil") (\(type(of: latRaw)))")
        print("🔍 [DEBUG] Lon raw: \(lonRaw ?? "nil") (\(type(of: lonRaw)))")
        */
        
        // Conversión de coordenadas (sin logs)
        let latConverted = {
            if let latString = json["direccion_latitud"] as? String {
                return Double(latString)
            } else {
                return json["direccion_latitud"] as? Double
            }
        }()
        
        let lonConverted = {
            if let lonString = json["direccion_longitud"] as? String {
                return Double(lonString)
            } else {
                return json["direccion_longitud"] as? Double
            }
        }()
        
        return GV_modeloCont_Establecimientos(
            establecimiento_id: id,
            user_id: json["user_id"] as? Int,
            usuario_id: json["usuario_id"] as? Int,
            indice_id: json["indice_id"] as? Int,
            registro_evento_id: json["registro_evento_id"] as? Int,
            establecimiento_nombre: (json["establecimiento_nombre"] as? String) ?? "Sin nombre",
            establecimiento_logo: json["establecimiento_logo"] as? String,
            establecimiento_url: json["establecimiento_url"] as? String,
            usuario_phone_number: json["usuario_phone_number"] as? String,
            usuario_email: json["usuario_email"] as? String,
            direccion_completa: json["direccion_completa"] as? String,
            direccion_municipio: json["direccion_municipio"] as? String,
            direccion_estado: json["direccion_estado"] as? String,
            direccion_latitud: latConverted,
            direccion_longitud: lonConverted,
            categoria_id: json["categoria_id"] as? Int,
            categoria_nombre: json["categoria_nombre"] as? String
        )
    }
    
    private func actualizarEstablecimiento(_ est: GV_modeloCont_Establecimientos, desde json: [String: Any]) {
        est.establecimiento_nombre = (json["establecimiento_nombre"] as? String) ?? est.establecimiento_nombre
        est.direccion_municipio = json["direccion_municipio"] as? String
        est.direccion_estado = json["direccion_estado"] as? String
        est.categoria_nombre = json["categoria_nombre"] as? String
    }
    
    private func obtenerFechaFormateada() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyy HH:mm:ss"
        return formatter.string(from: Date())
    }
}

// MARK: - ✅ EXTENSIÓN URLSession
extension URLSession {
    func synchronousDataTask(with url: URL) throws -> (Data, URLResponse) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = self.dataTask(with: url) {
            data = $0
            response = $1
            error = $2
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        if let error = error {
            throw error
        }
        
        return (data!, response!)
    }
}

// MARK: - 🧪 VISTA DE PRUEBA ANTIGUA (DEPRECADA - Usar GV_VistaSimple_Test en su lugar)
/*
struct GB_test_GV_ep_EstablecimientosView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var epEstablecimientos: GV_ep_Establecimientos?
    @State private var resultadoAPI: String = ""
    @State private var resultadoBD: String = ""
    @State private var codigoErrorAPI: Int = 0
    @State private var codigoErrorBD: Int = 0
    @State private var isLoading: Bool = false
    @State private var mostrarResultado: Bool = false
    @State private var numeroRegistros: Int = 5
    @State private var jsonCache: String = ""
    
    private let endpointPrueba = "https://canacocard-ms-backend.azurewebsites.net/api/evento/1/establecimientos"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header
                    headerView
                    
                    // Control de registros
                    controlRegistrosView
                    
                    // SECCIÓN 1: API
                    seccionAPIView
                    
                    // SECCIÓN 2: Carga a BD
                    seccionCargaBDView
                    
                    // SECCIÓN 3: Consultas
                    seccionConsultasView
                    
                    // SECCIÓN 4: Pruebas rápidas
                    seccionPruebasRapidasView
                    
                    // Indicador de carga
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Procesando...")
                                .font(.caption)
                        }
                        .padding()
                    }
                    
                    // Resultados
                    if mostrarResultado {
                        if !resultadoAPI.isEmpty {
                            resultadoCard(
                                titulo: "📡 Resultado API",
                                contenido: resultadoAPI,
                                color: codigoErrorAPI == 0 ? .green : .red
                            )
                        }
                        
                        if !resultadoBD.isEmpty {
                            resultadoCard(
                                titulo: "💾 Resultado BD",
                                contenido: resultadoBD,
                                color: codigoErrorBD == 0 ? .green : .red
                            )
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("🧪 Test Sistema")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            epEstablecimientos = GV_ep_Establecimientos(modelContext: modelContext)
            print("✅ Sistema inicializado")
        }
    }
    
    // MARK: - Vistas de Secciones
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Sistema de Sincronización")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Prueba completa de todos los métodos")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var controlRegistrosView: some View {
        VStack(spacing: 8) {
            Text("Registros a procesar: \(numeroRegistros)")
                .font(.headline)
            
            HStack(spacing: 20) {
                Button("5") { numeroRegistros = 5 }
                    .buttonStyle(.bordered)
                    .tint(numeroRegistros == 5 ? .blue : .gray)
                
                Button("10") { numeroRegistros = 10 }
                    .buttonStyle(.bordered)
                    .tint(numeroRegistros == 10 ? .blue : .gray)
                
                Button("20") { numeroRegistros = 20 }
                    .buttonStyle(.bordered)
                    .tint(numeroRegistros == 20 ? .blue : .gray)
                
                Button("50") { numeroRegistros = 50 }
                    .buttonStyle(.bordered)
                    .tint(numeroRegistros == 50 ? .blue : .gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var seccionAPIView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📡 SECCIÓN 1: Carga desde API")
                .font(.headline)
                .foregroundColor(.blue)
            
            Button(action: probarAPI) {
                HStack {
                    Image(systemName: "network")
                    Text("Load_API_Stream_EstabalecimeintosV")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading)
            
            Text("Carga JSON desde el endpoint con validación de campos vacíos")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var seccionCargaBDView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💾 SECCIÓN 2: Carga a Base de Datos")
                .font(.headline)
                .foregroundColor(.green)
            
            Button(action: { cargarBD(modo: .full) }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Modo FULL (Borra todo + carga nuevo)")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading || jsonCache.isEmpty)
            
            Button(action: { cargarBD(modo: .add) }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Modo ADD (Solo agrega, permite duplicados)")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading || jsonCache.isEmpty)
            
            Button(action: { cargarBD(modo: .inc) }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Modo INC (Incremental, actualiza existentes)")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading || jsonCache.isEmpty)
            
            if jsonCache.isEmpty {
                Text("⚠️ Primero debes cargar datos desde la API")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var seccionConsultasView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔍 SECCIÓN 3: Consultas a BD")
                .font(.headline)
                .foregroundColor(.purple)
            
            HStack(spacing: 12) {
                Button(action: { consultarBD(orden: .asc, tipo: .id) }) {
                    VStack {
                        Image(systemName: "arrow.up")
                        Text("ASC\nSolo IDs")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                Button(action: { consultarBD(orden: .desc, tipo: .id) }) {
                    VStack {
                        Image(systemName: "arrow.down")
                        Text("DESC\nSolo IDs")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
            
            HStack(spacing: 12) {
                Button(action: { consultarBD(orden: .asc, tipo: .full) }) {
                    VStack {
                        Image(systemName: "arrow.up.doc.fill")
                        Text("ASC\nCompleto")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                Button(action: { consultarBD(orden: .desc, tipo: .full) }) {
                    VStack {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("DESC\nCompleto")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var seccionPruebasRapidasView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚡️ SECCIÓN 4: Pruebas Rápidas")
                .font(.headline)
                .foregroundColor(.pink)
            
            Button(action: probarCompleta) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("API → BD FULL (Completo)")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading)
            
            Button(action: limpiarResultados) {
                HStack {
                    Image(systemName: "trash")
                    Text("Limpiar Resultados")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.pink.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func resultadoCard(titulo: String, contenido: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.headline)
                .foregroundColor(color)
            
            ScrollView {
                Text(contenido)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 1))
    }
    
    // MARK: - Métodos de Prueba
    
    private func probarAPI() {
        guard let ep = epEstablecimientos else { return }
        
        isLoading = true
        mostrarResultado = true
        
        Task {
            let (resultado, codigo) = ep.Load_API_Stream_EstabalecimeintosV(
                xEndPoint: endpointPrueba,
                xNo: numeroRegistros
            )
            
            await MainActor.run {
                if codigo == 0 {
                    self.jsonCache = resultado
                    self.resultadoAPI = "✅ JSON cargado exitosamente\n📦 Tamaño: \(resultado.count) caracteres\n🔗 Guardado en cache para cargar a BD"
                } else {
                    self.resultadoAPI = resultado
                }
                self.codigoErrorAPI = codigo
                self.isLoading = false
            }
        }
    }
    
    private func cargarBD(modo: GV_ep_Establecimientos.ModoCargaBD) {
        guard let ep = epEstablecimientos, !jsonCache.isEmpty else { return }
        
        isLoading = true
        mostrarResultado = true
        
        Task {
            let (resultado, codigo) = ep.Load_Stream_BDL(
                xStream: jsonCache,
                flagIncremental: modo
            )
            
            await MainActor.run {
                self.resultadoBD = "🔄 Modo: \(modo.rawValue.uppercased())\n\n\(resultado)"
                self.codigoErrorBD = codigo
                self.isLoading = false
            }
        }
    }
    
    private func consultarBD(orden: GV_ep_Establecimientos.OrdenResultados, tipo: GV_ep_Establecimientos.TipoRegreso) {
        guard let ep = epEstablecimientos else { return }
        
        isLoading = true
        mostrarResultado = true
        
        Task {
            let (resultado, codigo) = ep.Get_Establecimientos(
                xNo: numeroRegistros,
                incDec: orden,
                cRegresa: tipo
            )
            
            await MainActor.run {
                self.resultadoBD = resultado
                self.codigoErrorBD = codigo
                self.isLoading = false
            }
        }
    }
    
    private func probarCompleta() {
        guard let ep = epEstablecimientos else { return }
        
        isLoading = true
        mostrarResultado = true
        
        Task {
            // 1. Cargar desde API
            let (apiResultado, apiCodigo) = ep.Load_API_Stream_EstabalecimeintosV(
                xEndPoint: endpointPrueba,
                xNo: numeroRegistros
            )
            
            var bdResultado = ""
            var bdCodigo = 0
            
            // 2. Si API exitoso, cargar a BD en modo FULL
            if apiCodigo == 0 {
                let (bdResult, bdCode) = ep.Load_Stream_BDL(
                    xStream: apiResultado,
                    flagIncremental: .full
                )
                bdResultado = "🔄 Modo: FULL\n\n\(bdResult)"
                bdCodigo = bdCode
                
                await MainActor.run {
                    self.jsonCache = apiResultado
                }
            } else {
                bdResultado = "⚠️ No se cargó a BD porque la API falló"
                bdCodigo = -1
            }
            
            await MainActor.run {
                self.resultadoAPI = "✅ JSON cargado\n📦 Tamaño: \(apiResultado.count) caracteres"
                self.codigoErrorAPI = apiCodigo
                self.resultadoBD = bdResultado
                self.codigoErrorBD = bdCodigo
                self.isLoading = false
            }
        }
    }
    
    private func limpiarResultados() {
        resultadoAPI = ""
        resultadoBD = ""
        codigoErrorAPI = 0
        codigoErrorBD = 0
        mostrarResultado = false
        jsonCache = ""
    }
}

#Preview {
    GB_test_GV_ep_EstablecimientosView()
        .modelContainer(for: [GV_modeloCont_Establecimientos.self])
}
*/

