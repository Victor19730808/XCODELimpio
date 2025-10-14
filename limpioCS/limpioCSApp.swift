import SwiftUI
import SwiftData

@main
struct limpioCSApp: App {
    
    init() {
        // Configurar sistema de logs
        #if DEBUG
        // Configuración SÚPER mínima - solo errores críticos
        LogConfig.enabledLevels = [.error]
        LogConfig.enabledCategories = [.system]
        LogConfig.showFileInfo = false
        LogConfig.showTimestamp = false
        LogConfig.maxMessageLength = 50
        #else
        LogConfig.configureForProduction()
        #endif
        
        infoLog("🚀 App iniciando", category: .system)
    }
    // Instancia única para toda la app
    @StateObject private var locationService = LocationService()
    @StateObject private var seedManager = GV_SeedManager.shared
    @State private var showMainApp = false

    var body: some Scene {
        WindowGroup {
            if seedManager.checkSeedStatus() && !showMainApp {
                // 🌱 Mostrar pantalla de carga si necesita seed
                GV_SeedLoadingView(seedManager: seedManager) {
                    showMainApp = true
                }
            } else {
                // 🚀 Mostrar splash screen normal
                GV_SCR_tp_splash()
                    .environmentObject(locationService)
                
                // 🛠️ VISTA DE ADMINISTRACIÓN (Comentada - solo para desarrollo)
                // GV_VistaSimple_Test()
                //     .environmentObject(locationService)
            }
        }
        // ✅ Registramos el contenedor con ambos modelos
               .modelContainer(for: [
                   GV_modeloCont_Establecimientos.self,  // Modelo nuevo (principal)
                   lmpBDF_EstablecimientoLocal.self      // Modelo anterior (compatibilidad)
               ])
    }
}
