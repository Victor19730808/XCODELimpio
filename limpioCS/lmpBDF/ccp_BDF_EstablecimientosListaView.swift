import SwiftUI
import SwiftData

struct ccp_BDF_EstablecimientosListaView: View {
    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    @Query(sort: \lmpBDF_EstablecimientoLocal.nombre, order: .forward)
    private var all: [lmpBDF_EstablecimientoLocal]
    
    // Computed properties
    private var data: [lmpBDF_EstablecimientoLocal] {
        let baseData = showFavoritesOnly ? all.filter { $0.esFavorito } : all
        
        if searchText.isEmpty {
            return baseData
        } else {
            return baseData.filter { est in
                // Búsqueda principal: nombre O categoría (OR)
                let nombreMatch = est.nombre.localizedCaseInsensitiveContains(searchText)
                let categoriaMatch = est.categoria?.localizedCaseInsensitiveContains(searchText) == true
                
                // Búsqueda secundaria: municipio O estado (opcional)
                let municipioMatch = est.municipio?.localizedCaseInsensitiveContains(searchText) == true
                let estadoMatch = est.estado?.localizedCaseInsensitiveContains(searchText) == true
                
                // Prioridad: nombre O categoría, luego municipio O estado
                return nombreMatch || categoriaMatch || municipioMatch || estadoMatch
            }
        }
    }
    

    var body: some View {
        VStack(spacing: 0) {
            // Encabezado personalizado "Participantes" como DB MORSA ADM
            HStack {
                Text("Participantes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            
            // Header con contador, búsqueda y controles
            VStack(spacing: 12) {
                // Contador de registros
                HStack {
                    Text("\(all.count) registros")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                
                // Barra de búsqueda y controles
                HStack(spacing: 12) {
                    // Barra de búsqueda
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Buscar por nombre o categoría...", text: $searchText)
                            .textFieldStyle(.plain)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // Toggle de favoritos
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showFavoritesOnly.toggle()
                        }
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(showFavoritesOnly ? .yellow : .secondary)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            

            // Lista
            Group {
                if data.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? 
                            (showFavoritesOnly ? "Aún no tienes favoritos" : "Sin registros") :
                            "Sin resultados",
                        systemImage: searchText.isEmpty ? 
                            (showFavoritesOnly ? "star" : "building.2") :
                            "magnifyingglass",
                        description: Text(searchText.isEmpty ? 
                            (showFavoritesOnly ? "Marca participantes con la estrella para verlos aquí." : "Aún no hay participantes en la base local.") :
                            "Intenta con otros términos de búsqueda."
                        )
                    )
                } else {
                    List(data) { est in
                        ccp_UI_EstablecimientoRow(est: est)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .listStyle(.plain)
                    .refreshable {
                        // Función de refresh si es necesaria
                    }
                }
            }
        }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Componentes de UI

#Preview {
    NavigationStack {
        ccp_BDF_EstablecimientosListaView()
    }
}
