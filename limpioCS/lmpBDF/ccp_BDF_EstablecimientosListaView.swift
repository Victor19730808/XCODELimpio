import SwiftUI
import SwiftData

struct ccp_BDF_EstablecimientosListaView: View {
    enum Filtro: String, CaseIterable, Identifiable {
        case todos = "Todos"
        case favoritos = "Favoritos"
        var id: String { rawValue }
    }

    @State private var filtro: Filtro = .todos

    // Dos consultas separadas (simple y claro)
    @Query(sort: \lmpBDF_EstablecimientoLocal.nombre, order: .forward)
    private var all: [lmpBDF_EstablecimientoLocal]

    @Query(
        filter: #Predicate<lmpBDF_EstablecimientoLocal> { $0.esFavorito == true },
        sort: \.nombre,
        order: .forward
    )
    private var favs: [lmpBDF_EstablecimientoLocal]

    var body: some View {
        VStack {
            Picker("Filtro", selection: $filtro) {
                ForEach(Filtro.allCases) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            let data = (filtro == .todos) ? all : favs

            Group {
                if data.isEmpty {
                    ContentUnavailableView(
                        filtro == .todos ? "Sin registros" : "Aún no tienes favoritos",
                        systemImage: filtro == .todos ? "building.2" : "star",
                        description: Text(filtro == .todos
                                          ? "Aún no hay establecimientos en la base local."
                                          : "Marca establecimientos con la estrella para verlos aquí.")
                    )
                } else {
                    List(data) { est in
                        ccp_UI_EstablecimientoRow(est: est)
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("Establecimientos")
    }
}

#Preview {
    NavigationStack {
        ccp_BDF_EstablecimientosListaView()
    }
}
