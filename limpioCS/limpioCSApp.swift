import SwiftUI
import SwiftData

@main
struct limpioCSApp: App {
    // Instancia única para toda la app
    @StateObject private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
           GV_SCR_tp_splash()  // ✨ Empezar con splash migrada
                .environmentObject(locationService)
        }
        // ✅ Registramos el contenedor con el nuevo modelo lmpBDF
        .modelContainer(for: [
            lmpBDF_EstablecimientoLocal.self,
            
        ])
    }
}
