import SwiftUI
import SwiftData

@main
struct limpioCSApp: App {
    
    init() {
        // Sistema de logging optimizado para producción
        ProductionLogger.log("App iniciando", level: .info)
    }
    // Instancia única para toda la app
    @StateObject private var locationService = LocationService()
    @StateObject private var seedManager = GV_SeedManager.shared
    @State private var showMainApp = false
    @State private var needsSeed = false

    var body: some Scene {
        WindowGroup {
            if needsSeed && !showMainApp {
                // 🌱 Mostrar pantalla de carga si necesita seed
                GV_SeedLoadingView(seedManager: seedManager) {
                    showMainApp = true
                }
            } else {
                // 🚀 Mostrar splash screen normal
                GV_SCR_tp_splash()
                    .environmentObject(locationService)
                    .onAppear {
                        needsSeed = seedManager.checkSeedStatus()
                    }
                
                // 🛠️ VISTA DE ADMINISTRACIÓN (Comentada - solo para desarrollo)
                // GV_VistaSimple_Test()
                //     .environmentObject(locationService)
            }
        }
        // ✅ Registramos el contenedor con el modelo principal (limpio)
               .modelContainer(for: GV_modeloCont_Establecimientos.self)
    }
}
