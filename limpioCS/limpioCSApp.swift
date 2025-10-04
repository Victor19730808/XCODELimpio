import SwiftUI
import SwiftData

@main
struct limpioCSApp: App {
    // Instancia única para toda la app
    @StateObject private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            // Si ya usas NavigationStack en ContentView, puedes dejarlo como está.
            ContentView()
                .environmentObject(locationService)
        }
        // ✅ Registramos el contenedor con el nuevo modelo lmpBDF
        .modelContainer(for: [
            lmpBDF_EstablecimientoLocal.self,
            
        ])
    }
}
