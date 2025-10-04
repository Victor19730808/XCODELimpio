import SwiftUI
import SwiftData

public struct ccp_DB_MenuView: View {
    public init() {}
    public var body: some View {
        NavigationStack {
            List {
                Section("Local DB — Pruebas") {
                    NavigationLink("Seed desde API y explorar", destination: ccp_DB_SeedAndBrowseView())
                }
                Section("Notas") {
                    Text("Usa el ModelContainer que viene de la App/ContentView.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("CCP DB Menu")
        }
        // 🔹 Sin .modelContainer aquí (evita contenedor anidado)
    }
}
