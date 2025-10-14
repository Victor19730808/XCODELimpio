import Foundation
import SwiftData
import SwiftUI
import Combine

// MARK: - 🌱 SEED MANAGER - Sistema de Carga Inicial de Datos

/// Gestiona la carga inicial de datos desde un archivo JSON precargado en el bundle
// TEMPORALMENTE DESHABILITADO PARA DEBUGGING
// final class GV_SeedManager: ObservableObject {
final class GV_SeedManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = GV_SeedManager()
    
    // MARK: - Published Properties (REACTIVADAS CON PROTECCIÓN)
    @Published var isLoading: Bool = false
    @Published var progress: Double = 0.0
    @Published var progressMessage: String = ""
    @Published var seedStatus: SeedStatus = .notChecked
    
    // MARK: - Protección contra llamadas infinitas
    private var isCurrentlyLoading: Bool = false
    private var hasCheckedStatus: Bool = false
    
    // MARK: - Enums
    enum SeedStatus {
        case notChecked
        case needsSeed
        case seeded
        case seedFailed
        case updating
    }
    
    // MARK: - Constants
    private let seedVersionKey = "GV_Seed_Version_Establecimientos"
    private let seedLoadedKey = "GV_Seed_Loaded_Establecimientos"
    private let currentSeedVersion = "1.0.0"
    private let seedFileName = "establecimientos_seed"
    
    // MARK: - Private Init
    private init() {}
    
    // MARK: - Public Methods
    
    /// Verifica si es necesario cargar el seed (CON PROTECCIÓN)
    func checkSeedStatus() -> Bool {
        // 🔒 PROTECCIÓN: Evitar llamadas múltiples
        if hasCheckedStatus {
            return seedStatus == .needsSeed
        }
        
        hasCheckedStatus = true
        let isLoaded = UserDefaults.standard.bool(forKey: seedLoadedKey)
        let version = UserDefaults.standard.string(forKey: seedVersionKey)
        
        if !isLoaded || version != currentSeedVersion {
            seedStatus = .needsSeed
            return true
        }
        
        seedStatus = .seeded
        return false
    }
    
    /// Carga el seed desde el bundle si es necesario (CON PROTECCIÓN)
    @MainActor
    func loadSeedIfNeeded(modelContext: ModelContext) async -> (success: Bool, message: String) {
        
        // 🔒 PROTECCIÓN: Evitar múltiples cargas simultáneas
        if isCurrentlyLoading {
            return (false, "⚠️ Carga ya en progreso...")
        }
        
        // Verificar si ya está cargado
        if !checkSeedStatus() {
            return (true, "✅ Datos ya cargados (v\(currentSeedVersion))")
        }
        
        isCurrentlyLoading = true
        print("🌱 SEED: Iniciando carga de datos precargados...")
        
        isLoading = true
        progress = 0.0
        progressMessage = "Preparando datos..."
        seedStatus = .updating
        
        // Paso 1: Verificar que existe el archivo seed
        await updateProgress(10, "Verificando archivo seed...")
        
        guard let seedURL = Bundle.main.url(forResource: seedFileName, withExtension: "json") else {
            let error = "❌ Archivo seed no encontrado: \(seedFileName).json"
            print(error)
            await finalizarConError(error)
            return (false, error)
        }
        
        // Paso 2: Leer el archivo JSON
        await updateProgress(20, "Leyendo archivo JSON...")
        
        guard let jsonData = try? Data(contentsOf: seedURL),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            let error = "❌ Error al leer archivo seed"
            print(error)
            await finalizarConError(error)
            return (false, error)
        }
        
        print("📦 SEED: Archivo leído - \(jsonData.count) bytes")
        
        // Paso 3: Inicializar el objeto de sincronización
        await updateProgress(30, "Inicializando sistema...")
        
        let ep = GV_ep_Establecimientos(modelContext: modelContext)
        
        // Paso 4: Cargar a la base de datos
        await updateProgress(40, "Cargando a base de datos...")
        
        let (resultado, codigo) = ep.Load_Stream_BDL(
            xStream: jsonString,
            flagIncremental: .full
        )
        
        print("💾 SEED: Resultado de carga:")
        print("   Código: \(codigo)")
        print("   Resultado: \(resultado)")
        
        // Paso 5: Verificar resultado
        await updateProgress(80, "Verificando datos...")
        
        if codigo == 0 || codigo == -2 { // Éxito o error parcial
            // Marcar como cargado
            UserDefaults.standard.set(true, forKey: seedLoadedKey)
            UserDefaults.standard.set(currentSeedVersion, forKey: seedVersionKey)
            
            await updateProgress(100, "¡Datos cargados exitosamente!")
            
            // Esperar un momento para que se vea el 100%
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
            
            await finalizarExitoso()
            
            let mensaje = "✅ Seed cargado exitosamente (v\(currentSeedVersion))"
            print(mensaje)
            return (true, mensaje)
            
        } else {
            let error = "❌ Error al cargar seed: \(resultado)"
            print(error)
            await finalizarConError(error)
            return (false, error)
        }
    }
    
    /// Exporta los datos actuales de la BD a JSON para crear un nuevo seed
    func exportarSeedDesdeDB(modelContext: ModelContext) -> (success: Bool, json: String, message: String) {
        print("📤 SEED: Exportando datos actuales a JSON...")
        
        do {
            let descriptor = FetchDescriptor<GV_modeloCont_Establecimientos>(
                sortBy: [SortDescriptor(\GV_modeloCont_Establecimientos.establecimiento_id, order: .forward)]
            )
            let establecimientos = try modelContext.fetch(descriptor)
            
            print("📊 SEED: \(establecimientos.count) registros encontrados")
            
            // Convertir a array de diccionarios
            var jsonArray: [[String: Any]] = []
            
            for est in establecimientos {
                var dict: [String: Any] = [
                    "establecimiento_id": est.establecimiento_id,
                    "establecimiento_nombre": est.establecimiento_nombre
                ]
                
                // Agregar campos opcionales solo si tienen valor
                if let user_id = est.user_id { dict["user_id"] = user_id }
                if let usuario_id = est.usuario_id { dict["usuario_id"] = usuario_id }
                if let indice_id = est.indice_id { dict["indice_id"] = indice_id }
                if let registro_evento_id = est.registro_evento_id { dict["registro_evento_id"] = registro_evento_id }
                if let logo = est.establecimiento_logo { dict["establecimiento_logo"] = logo }
                if let url = est.establecimiento_url { dict["establecimiento_url"] = url }
                if let phone = est.usuario_phone_number { dict["usuario_phone_number"] = phone }
                if let email = est.usuario_email { dict["usuario_email"] = email }
                if let direccion = est.direccion_completa { dict["direccion_completa"] = direccion }
                if let municipio = est.direccion_municipio { dict["direccion_municipio"] = municipio }
                if let estado = est.direccion_estado { dict["direccion_estado"] = estado }
                if let lat = est.direccion_latitud { dict["direccion_latitud"] = lat }
                if let lon = est.direccion_longitud { dict["direccion_longitud"] = lon }
                if let cat_id = est.categoria_id { dict["categoria_id"] = cat_id }
                if let cat_nombre = est.categoria_nombre { dict["categoria_nombre"] = cat_nombre }
                
                jsonArray.append(dict)
            }
            
            // Convertir a JSON
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                return (false, "", "❌ Error al convertir JSON a String")
            }
            
            let mensaje = """
            ✅ EXPORTACIÓN EXITOSA
            ═══════════════════════
            Registros exportados: \(establecimientos.count)
            Tamaño JSON: \(jsonData.count) bytes (\(Double(jsonData.count) / 1024.0) KB)
            Versión: \(currentSeedVersion)
            
            📝 Siguiente paso:
            1. Guardar el JSON como: \(seedFileName).json
            2. Agregarlo al bundle de la app
            3. Verificar que esté en "Copy Bundle Resources"
            """
            
            print(mensaje)
            
            return (true, jsonString, mensaje)
            
        } catch {
            let mensaje = "❌ Error al exportar: \(error.localizedDescription)"
            print(mensaje)
            return (false, "", mensaje)
        }
    }
    
    /// Fuerza la recarga del seed (útil para testing o actualizaciones)
    func resetSeed() {
        UserDefaults.standard.removeObject(forKey: seedLoadedKey)
        UserDefaults.standard.removeObject(forKey: seedVersionKey)
        seedStatus = .notChecked
        print("🔄 SEED: Estado reseteado - se cargará en el próximo inicio")
    }
    
    /// Obtiene información del seed actual
    func getSeedInfo() -> String {
        let isLoaded = UserDefaults.standard.bool(forKey: seedLoadedKey)
        let version = UserDefaults.standard.string(forKey: seedVersionKey) ?? "N/A"
        
        return """
        📦 INFORMACIÓN DEL SEED
        ═══════════════════════
        Estado: \(isLoaded ? "✅ Cargado" : "❌ No cargado")
        Versión actual: \(version)
        Versión esperada: \(currentSeedVersion)
        Archivo: \(seedFileName).json
        Necesita actualización: \(version != currentSeedVersion ? "Sí" : "No")
        """
    }
    
    // MARK: - Private Methods
    
    private func updateProgress(_ value: Double, _ message: String) async {
        await MainActor.run {
            self.progress = value
            self.progressMessage = message
        }
    }
    
    private func finalizarExitoso() async {
        await MainActor.run {
            self.isLoading = false
            self.seedStatus = .seeded
            self.progress = 100
            self.isCurrentlyLoading = false  // 🔓 LIBERAR PROTECCIÓN
        }
    }
    
    private func finalizarConError(_ mensaje: String) async {
        await MainActor.run {
            self.isLoading = false
            self.seedStatus = .seedFailed
            self.progressMessage = mensaje
            self.isCurrentlyLoading = false  // 🔓 LIBERAR PROTECCIÓN
        }
    }
}

// MARK: - 🎨 VISTA DE CARGA SEED

/// Vista que muestra el progreso de carga del seed
struct GV_SeedLoadingView: View {
    @ObservedObject var seedManager: GV_SeedManager
    @Environment(\.modelContext) private var modelContext
    @State private var loadCompleted = false
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Fondo con gradiente
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo o icono
                Image(systemName: "cylinder.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                
                Text("Cargando Datos")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Barra de progreso
                VStack(spacing: 10) {
                    ProgressView(value: seedManager.progress, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(width: 250)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    Text("\(Int(seedManager.progress))%")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(seedManager.progressMessage)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .frame(width: 280)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                
                Spacer()
                
                // Footer
                Text("Primera carga • Esto solo ocurre una vez")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
        .onAppear {
            Task {
                let (success, message) = await seedManager.loadSeedIfNeeded(modelContext: modelContext)
                print("🌱 Seed cargado: \(success) - \(message)")
                
                // Esperar un momento antes de continuar
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
                
                await MainActor.run {
                    loadCompleted = true
                    onComplete()
                }
            }
        }
    }
}

// MARK: - 🧪 VISTA DE ADMINISTRACIÓN DE SEED

/// Vista para gestionar el seed (exportar, resetear, info)
struct GV_SeedAdminView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var seedManager = GV_SeedManager.shared
    
    @State private var showExportResult = false
    @State private var exportedJSON = ""
    @State private var exportMessage = ""
    @State private var showInfo = false
    @State private var seedInfo = ""
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    
    var body: some View {
        NavigationStack {
            List {
                // Sección: Estado
                Section("📊 ESTADO DEL SEED") {
                    HStack {
                        Text("Estado:")
                        Spacer()
                        statusBadge
                    }
                    
                    Button(action: { 
                        showInfo = true
                        seedInfo = seedManager.getSeedInfo()
                    }) {
                        Label("Ver Información Completa", systemImage: "info.circle")
                    }
                }
                
                // Sección: Exportar
                Section("📤 EXPORTAR SEED") {
                    if isExporting {
                        VStack(spacing: 12) {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Exportando datos...")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            ProgressView(value: exportProgress, total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            
                            Text("\(Int(exportProgress))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(exportMessage)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 8)
                    } else {
                        Button(action: exportarSeed) {
                            Label("Exportar BD Actual a JSON", systemImage: "square.and.arrow.up")
                        }
                        .disabled(isExporting)
                    }
                    
                    Text("Genera un archivo JSON con todos los registros actuales de la base de datos.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Sección: Resetear
                Section("🔄 RESETEAR SEED") {
                    Button(role: .destructive, action: resetearSeed) {
                        Label("Forzar Recarga en Próximo Inicio", systemImage: "arrow.clockwise")
                    }
                    
                    Text("Marca el seed como no cargado. La app volverá a cargar los datos en el próximo inicio.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("🌱 Administrador Seed")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showExportResult) {
                exportResultView
            }
            .alert("ℹ️ Información del Seed", isPresented: $showInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(seedInfo)
            }
        }
    }
    
    private var statusBadge: some View {
        Group {
            switch seedManager.seedStatus {
            case .notChecked:
                Text("No verificado")
                    .foregroundColor(.gray)
            case .needsSeed:
                Text("Necesita carga")
                    .foregroundColor(.orange)
            case .seeded:
                Text("✅ Cargado")
                    .foregroundColor(.green)
            case .seedFailed:
                Text("❌ Error")
                    .foregroundColor(.red)
            case .updating:
                Text("Actualizando...")
                    .foregroundColor(.blue)
            }
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var exportResultView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(exportMessage)
                        .font(.body)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    
                    if !exportedJSON.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("JSON Generado:")
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    UIPasteboard.general.string = exportedJSON
                                }) {
                                    Label("Copiar", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: true) {
                                Text(exportedJSON)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            .frame(maxHeight: 300)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Resultado de Exportación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        showExportResult = false
                    }
                }
            }
        }
    }
    
    private func exportarSeed() {
        isExporting = true
        exportProgress = 0.0
        exportMessage = "Iniciando exportación..."
        
        Task {
            // Simular progreso mientras se exporta
            await updateExportProgress(10, "Conectando a base de datos...")
            
            await updateExportProgress(30, "Leyendo registros...")
            
            let (success, json, message) = seedManager.exportarSeedDesdeDB(modelContext: modelContext)
            
            await updateExportProgress(80, "Procesando JSON...")
            
            await MainActor.run {
                exportedJSON = json
                exportMessage = message
                showExportResult = success
                isExporting = false
                exportProgress = 100.0
                
                if success {
                    print("✅ JSON exportado exitosamente")
                }
            }
        }
    }
    
    private func updateExportProgress(_ progress: Double, _ message: String) async {
        await MainActor.run {
            self.exportProgress = progress
            self.exportMessage = message
        }
        
        // Pequeña pausa para que se vea el progreso
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 segundos
    }
    
    private func resetearSeed() {
        seedManager.resetSeed()
        seedInfo = seedManager.getSeedInfo()
    }
}

#Preview {
    GV_SeedAdminView()
        .modelContainer(for: [GV_modeloCont_Establecimientos.self])
}

