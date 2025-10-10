import SwiftUI
import SwiftData

struct ccp_BDF_EstablecimientosListaView: View {
    @Environment(\.dismiss) private var dismiss
    // Referencias de diseño removidas
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
        ZStack {
            // Fondo con gradiente sutil usando el tema actual
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.1),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header rojo estilo El Buen Fin
                VStack(spacing: 0) {
                    HStack {
                        // Botón regresar al menú principal
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "house.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(.white.opacity(0.2))
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .padding(.leading, 20)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Título "Participantes" centrado
                            Text("Participantes")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        
                        // Menú hamburguesa
                        HStack {
                            Spacer()
                            
                            // Icono de menú (sin funcionalidad por ahora)
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.trailing, 20)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // Línea divisoria
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                }
                .frame(height: 100)
                .background(Color.red)
                
                // Contenido principal
                VStack(spacing: 0) {
                    // Barra de búsqueda y controles
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            // Barra de búsqueda
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                
                                TextField("Buscar por nombre o categoría...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(.primary)
                                
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                            
                            // Toggle de favoritos
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showFavoritesOnly.toggle()
                                }
                            } label: {
                                Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(showFavoritesOnly ? .yellow : .secondary)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                            }
                        }
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .background(Color.white)
                    
                    // Lista de participantes
                    Group {
                        if data.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                
                                Image(systemName: searchText.isEmpty ? 
                                    (showFavoritesOnly ? "star" : "building.2") :
                                    "magnifyingglass")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary.opacity(0.3))
                                
                                VStack(spacing: 8) {
                                    Text(searchText.isEmpty ? 
                                        (showFavoritesOnly ? "Aún no tienes favoritos" : "Sin registros") :
                                        "Sin resultados")
                                        .font(.title)
                                        .foregroundStyle(.primary)
                                    
                                    Text(searchText.isEmpty ? 
                                        (showFavoritesOnly ? "Marca participantes con la estrella para verlos aquí." : "Aún no hay participantes en la base local.") :
                                        "Intenta con otros términos de búsqueda.")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(data) { est in
                                        ccp_UI_EstablecimientoRow(est: est)
                                            .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.vertical, 16)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Componentes de UI

#Preview {
    NavigationStack {
        ccp_BDF_EstablecimientosListaView()
    }
}
