import SwiftUI
import SwiftData

// 🛠️ VISTA DE ADMINISTRACIÓN COMPLETA - GV_ep_Establecimientos
// Sistema completo para testing, debugging y administración de la BD

struct GV_VistaSimple_Test: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var epEstablecimientos: GV_ep_Establecimientos?
    
    // MARK: - Estados de UI
    @State private var progreso: Double = 0.0
    @State private var mensajeProgreso: String = ""
    @State private var estaCargando: Bool = false
    @State private var mostrarResultado: Bool = false
    @State private var numeroRegistros: String = "50"
    @State private var resultadosConTimestamp: [(id: String, timestamp: Date, metodo: String, resultado: String)] = []
    @State private var resultadoExpandido: String? = nil
    @State private var registrosEnBD: Int = 0
    
    // MARK: - Configuración
    private let endpoint = "https://canacocard-ms-backend.azurewebsites.net/api/evento/1/establecimientos"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // MARK: - INFORMACIÓN GENERAL
                    seccionInfoGeneral
                    
                    // MARK: - SECCIONES PRINCIPALES
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 12) {
                        
                        // 📡 MÉTODOS API
                        seccionMetodosAPI
                        
                        // 💾 MÉTODOS BD
                        seccionMetodosBD
                        
                        // 🔍 MÉTODOS CONSULTA
                        seccionMetodosConsulta
                        
                        // 🛠️ MÉTODOS ADMIN
                        seccionMetodosAdmin
                    }
                    
                    // MARK: - BARRA DE PROGRESO
                    if estaCargando {
                        seccionProgreso
                    }
                    
                    // MARK: - RESULTADOS
                    if mostrarResultado {
                        resultadosView
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .navigationTitle("🛠️ Admin Sistema")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    inicializarSistema()
                    contarRegistrosEnBD()
                }
            }
        }
    }
    
    // MARK: - Secciones de UI
    
    // MARK: - INFORMACIÓN GENERAL
    private var seccionInfoGeneral: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("📊 Estado del Sistema")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Registros en BD: \(registrosEnBD)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                TextField("Registros", text: $numeroRegistros)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 80)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - MÉTODOS API
    private var seccionMetodosAPI: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📡 API")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            VStack(spacing: 6) {
                Button(action: { probarAPI_Raw() }) {
                    Text("Raw API")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                
                Button(action: { probarAPI_Validated() }) {
                    Text("Validated API")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                
                Button(action: { mostrarJSONFormateado() }) {
                    Text("JSON Formateado")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - MÉTODOS BD
    private var seccionMetodosBD: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💾 Base de Datos")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            VStack(spacing: 6) {
                Button(action: { probarBD_Full() }) {
                    Text("FULL")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
                
                Button(action: { probarBD_Add() }) {
                    Text("ADD")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
                
                Button(action: { probarBD_Inc() }) {
                    Text("INCREMENTAL")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - MÉTODOS CONSULTA
    private var seccionMetodosConsulta: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔍 Consultas")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            VStack(spacing: 6) {
                Button(action: { probarConsulta(10, "asc", "full") }) {
                    Text("ASC Full (10)")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }
                
                Button(action: { probarConsulta(50, "desc", "id") }) {
                    Text("DESC ID (50)")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }
                
                Button(action: { probarConsulta(100, "asc", "full") }) {
                    Text("ASC Full (100)")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - MÉTODOS ADMIN
    private var seccionMetodosAdmin: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🛠️ Administración")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            VStack(spacing: 6) {
                Button(action: limpiarBD) {
                    Text("Limpiar BD")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }
                
                Button(action: mostrarEstadisticas) {
                    Text("Estadísticas")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }
                
                Button(action: generarSeedJSON) {
                    Text("📄 Generar Seed JSON")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
                
                Button(action: { mostrarResultado = false }) {
                    Text("Limpiar UI")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.gray)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - BARRA DE PROGRESO
    private var seccionProgreso: some View {
        VStack(spacing: 8) {
            ProgressView(value: progreso, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text(mensajeProgreso)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var resultadosView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerResultados
            listaResultados
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple, lineWidth: 1))
    }
    
    private var headerResultados: some View {
        HStack {
            Text("📊 RESULTADOS")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
            
            Spacer()
            
            Button(action: { mostrarResultado = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var listaResultados: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 12) {
                ForEach(resultadosConTimestamp.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { item in
                    resultadoItem(item)
                }
            }
        }
        .frame(maxHeight: 400)
    }
    
    private func resultadoItem(_ item: (id: String, timestamp: Date, metodo: String, resultado: String)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            headerItem(item)
            contenidoItem(item)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.systemGray5).opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func headerItem(_ item: (id: String, timestamp: Date, metodo: String, resultado: String)) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("🔧 \(item.metodo)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("🕒 \(DateFormatter.localizedString(from: item.timestamp, dateStyle: .none, timeStyle: .medium))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            botonesAccion(item)
        }
    }
    
    private func botonesAccion(_ item: (id: String, timestamp: Date, metodo: String, resultado: String)) -> some View {
        HStack(spacing: 8) {
            Button(action: { 
                UIPasteboard.general.string = item.resultado
            }) {
                Image(systemName: "doc.on.doc.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Button(action: { 
                resultadosConTimestamp.removeAll { $0.id == item.id }
                if resultadosConTimestamp.isEmpty {
                    mostrarResultado = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
            
            Button(action: { 
                if resultadoExpandido == item.id {
                    resultadoExpandido = nil
                } else {
                    resultadoExpandido = item.id
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: resultadoExpandido == item.id ? "arrow.down.square" : "arrow.up.square")
                        .font(.caption2)
                    Text(resultadoExpandido == item.id ? "Contraer" : "Expandir")
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(4)
            }
        }
    }
    
    private func contenidoItem(_ item: (id: String, timestamp: Date, metodo: String, resultado: String)) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text(item.resultado)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(6)
        }
        .frame(maxHeight: resultadoExpandido == item.id ? 600 : 150)
        .animation(.easeInOut(duration: 0.3), value: resultadoExpandido)
    }
    
    // MARK: - Métodos de Sistema
    
    private func agregarResultado(_ metodo: String, _ resultado: String) {
        let id = UUID().uuidString
        let timestamp = Date()
        resultadosConTimestamp.append((id: id, timestamp: timestamp, metodo: metodo, resultado: resultado))
        mostrarResultado = true
    }
    
    private func inicializarSistema() {
        if epEstablecimientos == nil {
            epEstablecimientos = GV_ep_Establecimientos(modelContext: modelContext)
            print("✅ Sistema inicializado")
        }
    }
    
    private func contarRegistrosEnBD() {
        do {
            let descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>()
            let registros = try modelContext.fetch(descriptor)
            registrosEnBD = registros.count
        } catch {
            registrosEnBD = 0
        }
    }
    
    private func actualizarProgreso(_ valor: Double, _ mensaje: String) async {
        await MainActor.run {
            progreso = valor / 100.0
            mensajeProgreso = mensaje
        }
    }
    
    // MARK: - Métodos API
    
    private func probarAPI_Raw() {
        guard let ep = epEstablecimientos else { return }
        
        estaCargando = true
        let numeroRegistrosInt = Int(numeroRegistros) ?? 50
        
        Task {
            await actualizarProgreso(50, "📡 Conectando API Raw...")
            
            let (resultado, codigo) = ep.Load_API_Stream_EstabalecimeintosV(
                xEndPoint: endpoint,
                xNo: numeroRegistrosInt
            )
            
            await MainActor.run {
                let status = codigo == 0 ? "✅" : "❌"
                let resultadoCompleto = """
                📡 MÉTODO: Load_API_Stream_Estabalecimeintos (RAW)
                ═══════════════════════════════════════════════
                
                📊 Parámetros:
                • Endpoint: \(endpoint)
                • Registros: \(numeroRegistrosInt)
                
                📋 Resultado:
                • Código: \(codigo)
                • Estado: \(status)
                
                📄 JSON Raw:
                \(resultado.prefix(1000))\(resultado.count > 1000 ? "\n... [TRUNCADO]" : "")
                """
                
                agregarResultado("API_Raw", resultadoCompleto)
                estaCargando = false
            }
        }
    }
    
    private func probarAPI_Validated() {
        guard let ep = epEstablecimientos else { return }
        
        estaCargando = true
        let numeroRegistrosInt = Int(numeroRegistros) ?? 50
        
        Task {
            await actualizarProgreso(50, "📡 Conectando API Validated...")
            
            let (resultado, codigo) = ep.Load_API_Stream_EstabalecimeintosV(
                xEndPoint: endpoint,
                xNo: numeroRegistrosInt
            )
            
            await MainActor.run {
                let status = codigo == 0 ? "✅" : "❌"
                let resultadoCompleto = """
                📡 MÉTODO: Load_API_Stream_EstabalecimeintosV (VALIDATED)
                ═══════════════════════════════════════════════════
                
                📊 Parámetros:
                • Endpoint: \(endpoint)
                • Registros: \(numeroRegistrosInt)
                
                📋 Resultado:
                • Código: \(codigo)
                • Estado: \(status)
                
                📄 JSON Validated:
                \(resultado.prefix(1000))\(resultado.count > 1000 ? "\n... [TRUNCADO]" : "")
                """
                
                agregarResultado("API_Validated", resultadoCompleto)
                estaCargando = false
            }
        }
    }
    
    private func mostrarJSONFormateado() {
        guard let ep = epEstablecimientos else { return }
        
        estaCargando = true
        let numeroRegistrosInt = Int(numeroRegistros) ?? 50
        
        Task {
            await actualizarProgreso(50, "📡 Obteniendo JSON formateado...")
            
            let (resultado, codigo) = ep.Load_API_Stream_EstabalecimeintosV(
                xEndPoint: endpoint,
                xNo: numeroRegistrosInt
            )
            
            await MainActor.run {
                let status = codigo == 0 ? "✅" : "❌"
                let resultadoCompleto = """
                📋 MÉTODO: JSON Formateado
                ═══════════════════════════════
                
                📊 Parámetros:
                • Endpoint: \(endpoint)
                • Registros: \(numeroRegistrosInt)
                
                📋 Resultado:
                • Código: \(codigo)
                • Estado: \(status)
                
                📄 JSON Completo:
                \(resultado)
                """
                
                agregarResultado("JSON_Formateado", resultadoCompleto)
                estaCargando = false
            }
        }
    }
    
    // MARK: - Métodos BD
    
    private func probarBD_Full() {
        guard let ep = epEstablecimientos else { return }
        
        estaCargando = true
        let numeroRegistrosInt = Int(numeroRegistros) ?? 50
        
        Task {
            // Obtener JSON primero
            await actualizarProgreso(30, "📡 Obteniendo datos API...")
            let (jsonResultado, codigoAPI) = ep.Load_API_Stream_EstabalecimeintosV(
                xEndPoint: endpoint,
                xNo: numeroRegistrosInt
            )
            
            if codigoAPI != 0 {
                await MainActor.run {
                    agregarResultado("BD_FULL_ERROR", "❌ Error obteniendo datos API: \(codigoAPI)")
                    estaCargando = false
                }
                return
            }
            
            // Cargar a BD
            await actualizarProgreso(70, "💾 Cargando BD (FULL)...")
            let (bdResultado, codigoBD) = ep.Load_Stream_BDL(
                xStream: jsonResultado,
                flagIncremental: .full
            )
            
            await MainActor.run {
                let status = codigoBD == 0 ? "✅" : "❌"
                let resultadoCompleto = """
                💾 MÉTODO: Load_Stream_BDL (FULL)
                ═══════════════════════════════════════
                
                📊 Parámetros:
                • Modo: FULL
                • Registros API: \(numeroRegistrosInt)
                
                📋 Resultado:
                • Código: \(codigoBD)
                • Estado: \(status)
                
                📄 Reporte:
                \(bdResultado)
                """
                
                agregarResultado("BD_FULL", resultadoCompleto)
                estaCargando = false
                contarRegistrosEnBD()
            }
        }
    }
    
    private func probarBD_Add() {
        guard let ep = epEstablecimientos else { return }
        
        estaCargando = true
        let numeroRegistrosInt = Int(numeroRegistros) ?? 50
        
        Task {
            await actualizarProgreso(30, "📡 Obteniendo datos API...")
            let (jsonResultado, codigoAPI) = ep.Load_API_Stream_EstabalecimeintosV(
                xEndPoint: endpoint,
                xNo: numeroRegistrosInt
            )
            
            if codigoAPI != 0 {
                await MainActor.run {
                    agregarResultado("BD_ADD_ERROR", "❌ Error obteniendo datos API: \(codigoAPI)")
                    estaCargando = false
                }
                return
            }
            
            await actualizarProgreso(70, "💾 Cargando BD (ADD)...")
            let (bdResultado, codigoBD) = ep.Load_Stream_BDL(
                xStream: jsonResultado,
                flagIncremental: .add
            )
            
            await MainActor.run {
                let status = codigoBD == 0 ? "✅" : "❌"
                let resultadoCompleto = """
                💾 MÉTODO: Load_Stream_BDL (ADD)
                ═══════════════════════════════════════
                
                📊 Parámetros:
                • Modo: ADD
                • Registros API: \(numeroRegistrosInt)
                
                📋 Resultado:
                • Código: \(codigoBD)
                • Estado: \(status)
                
                📄 Reporte:
                \(bdResultado)
                """
                
                agregarResultado("BD_ADD", resultadoCompleto)
                estaCargando = false
                contarRegistrosEnBD()
            }
        }
    }
    
    private func probarBD_Inc() {
        guard let ep = epEstablecimientos else { return }
        
        estaCargando = true
        let numeroRegistrosInt = Int(numeroRegistros) ?? 50
        
        Task {
            await actualizarProgreso(30, "📡 Obteniendo datos API...")
            let (jsonResultado, codigoAPI) = ep.Load_API_Stream_EstabalecimeintosV(
                xEndPoint: endpoint,
                xNo: numeroRegistrosInt
            )
            
            if codigoAPI != 0 {
                await MainActor.run {
                    agregarResultado("BD_INC_ERROR", "❌ Error obteniendo datos API: \(codigoAPI)")
                    estaCargando = false
                }
                return
            }
            
            await actualizarProgreso(70, "💾 Cargando BD (INCREMENTAL)...")
            let (bdResultado, codigoBD) = ep.Load_Stream_BDL(
                xStream: jsonResultado,
                flagIncremental: .inc
            )
            
            await MainActor.run {
                let status = codigoBD == 0 ? "✅" : "❌"
                let resultadoCompleto = """
                💾 MÉTODO: Load_Stream_BDL (INCREMENTAL)
                ═══════════════════════════════════════
                
                📊 Parámetros:
                • Modo: INCREMENTAL
                • Registros API: \(numeroRegistrosInt)
                
                📋 Resultado:
                • Código: \(codigoBD)
                • Estado: \(status)
                
                📄 Reporte:
                \(bdResultado)
                """
                
                agregarResultado("BD_INC", resultadoCompleto)
                estaCargando = false
                contarRegistrosEnBD()
            }
        }
    }
    
    // MARK: - Métodos Consulta
    
    private func probarConsulta(_ numero: Int, _ orden: String, _ tipo: String) {
        guard let ep = epEstablecimientos else { return }
        
        estaCargando = true
        let metodoKey = "Consulta_\(orden.uppercased())_\(tipo.uppercased())_\(numero)"
        
        Task {
            await actualizarProgreso(50, "🔍 Ejecutando consulta...")
            
            let ordenEnum: GV_ep_Establecimientos.OrdenResultados = orden == "asc" ? .asc : .desc
            let tipoEnum: GV_ep_Establecimientos.TipoRegreso = tipo == "full" ? .full : .id
            
            let (resultado, codigo) = ep.Get_Establecimientos(
                xNo: numero,
                incDec: ordenEnum,
                cRegresa: tipoEnum
            )
            
            await MainActor.run {
                let status = codigo == 0 ? "✅" : "❌"
                let resultadoCompleto = """
                🔍 MÉTODO: Get_Establecimientos
                ═══════════════════════════════
                
                📊 Parámetros:
                • Número: \(numero)
                • Orden: \(orden.uppercased())
                • Tipo: \(tipo.uppercased())
                
                📋 Resultado:
                • Código: \(codigo)
                • Estado: \(status)
                
                📄 Datos:
                \(resultado)
                """
                
                agregarResultado(metodoKey, resultadoCompleto)
                estaCargando = false
            }
        }
    }
    
    // MARK: - Métodos Admin
    
    private func limpiarBD() {
        guard let ep = epEstablecimientos else { return }
        
        estaCargando = true
        
        Task {
            await actualizarProgreso(50, "🗑️ Limpiando base de datos...")
            
            let (resultado, codigo) = ep.Limpiar_BaseDatos()
            
            await MainActor.run {
                let status = codigo == 0 ? "✅" : "❌"
                let resultadoCompleto = """
                🗑️ MÉTODO: Limpiar_BaseDatos
                ═══════════════════════════════
                
                📋 Resultado:
                • Código: \(codigo)
                • Estado: \(status)
                
                📄 Reporte:
                \(resultado)
                """
                
                agregarResultado("Limpiar_BD", resultadoCompleto)
                estaCargando = false
                contarRegistrosEnBD()
            }
        }
    }
    
    private func mostrarEstadisticas() {
        estaCargando = true
        
        Task {
            await actualizarProgreso(50, "📊 Calculando estadísticas...")
            
            let timestamp = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
            
            await MainActor.run {
                let estadisticas = """
                📊 ESTADÍSTICAS DEL SISTEMA
                ═══════════════════════════════
                
                🕒 Timestamp: \(formatter.string(from: timestamp))
                📊 Registros en BD: \(registrosEnBD)
                🔧 Sistema inicializado: \(epEstablecimientos != nil ? "✅" : "❌")
                📡 Endpoint configurado: \(endpoint)
                
                📈 Resultados en memoria: \(resultadosConTimestamp.count)
                🔄 Estado de carga: \(estaCargando ? "⏳ Cargando" : "✅ Listo")
                
                💾 Memoria:
                • Progreso actual: \(String(format: "%.1f", progreso * 100))%
                • Mensaje: \(mensajeProgreso.isEmpty ? "Sin mensaje" : mensajeProgreso)
                
                🎯 Configuración:
                • Número de registros: \(numeroRegistros)
                • Resultado expandido: \(resultadoExpandido?.prefix(8) ?? "Ninguno")
                """
                
                agregarResultado("Estadísticas", estadisticas)
                estaCargando = false
            }
        }
    }
    
    // MARK: - Generar Seed JSON desde BD
    private func generarSeedJSON() {
        guard let ep = epEstablecimientos else { return }
        
        estaCargando = true
        
        // Obtener el límite del cuadro de texto (si está vacío o es 0, trae TODOS)
        let limite = Int(numeroRegistros) ?? 0
        let limiteTexto = (limite > 0) ? "\(limite) registros" : "TODOS los registros"
        
        Task {
            await actualizarProgreso(50, "📄 Generando JSON desde BD (\(limiteTexto))...")
            
            let (jsonString, totalRegistros, registrosConCoordenadas, codigo) = ep.Generar_Seed_JSON(limite: limite)
            
            await MainActor.run {
                let status = codigo == 0 ? "✅" : "❌"
                let porcentajeConCoordenadas = totalRegistros > 0 ? (Double(registrosConCoordenadas) / Double(totalRegistros) * 100) : 0
                
                let resultado = """
                📄 GENERADOR DE SEED JSON
                ═══════════════════════════════════════
                
                📊 Estado: \(status)
                
                📈 Estadísticas:
                • Parámetro: \(limiteTexto)
                • Total de registros: \(totalRegistros)
                • Con coordenadas: \(registrosConCoordenadas)
                • Porcentaje con coords: \(String(format: "%.1f", porcentajeConCoordenadas))%
                • Tamaño JSON: \(jsonString.count) caracteres
                
                📦 JSON COMPLETO (Listo para copiar):
                \(jsonString)
                
                💡 INSTRUCCIONES:
                1. Copiar TODO el JSON de arriba (usa el botón 📋)
                2. Abrir establecimientos_seed.json en Xcode
                3. Pegar y reemplazar todo el contenido
                4. Guardar el archivo
                5. ✅ Listo! El seed estará actualizado
                
                ⚠️ IMPORTANTE:
                El seed tiene \(registrosConCoordenadas) de \(totalRegistros) con coordenadas.
                Si faltan coordenadas, carga datos del API primero.
                
                💡 TIP:
                • Para generar seed COMPLETO: deja el campo vacío o pon 0
                • Para pruebas pequeñas: especifica un número (ej: 10, 50)
                """
                
                // También copiar al portapapeles automáticamente
                UIPasteboard.general.string = jsonString
                
                agregarResultado("📄 Seed JSON", resultado)
                estaCargando = false
            }
        }
    }
}

#Preview {
    GV_VistaSimple_Test()
        .modelContainer(for: GV_modeloCont_Establecimientos.self, inMemory: true)
}
