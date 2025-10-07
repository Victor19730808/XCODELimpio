import SwiftUI
import SwiftData

struct ccp_BDF_EstablecimientosListaView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    @Query(sort: \lmpBDF_EstablecimientoLocal.nombre, order: .forward)
    private var all: [lmpBDF_EstablecimientoLocal]
    
    // Colores inspirados en El Buen Fin
    private let buenFinRed = Color(red: 0.89, green: 0.12, blue: 0.14) // #E31E24
    private let buenFinWhite = Color.white
    private let buenFinGray = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    
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
            // Fondo con gradiente sutil
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.05),
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
                                    .foregroundColor(buenFinWhite)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .padding(.leading, 20)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Título "Participantes" centrado
                        Text("Participantes")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(buenFinWhite)
                        
                        // Menú hamburguesa
                        HStack {
                            Spacer()
                            
                            Menu {
                                Button {
                                    // Mis configuraciones
                                } label: {
                                    Label("Mis Configuraciones", systemImage: "gear")
                                }
                                
                                Button {
                                    // Búsquedas Avanzadas
                                } label: {
                                    Label("Búsquedas Avanzadas", systemImage: "magnifyingglass.circle")
                                }
                                
                                Button {
                                    // Admin Datos
                                } label: {
                                    Label("Admin Datos", systemImage: "wrench.and.screwdriver")
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal")
                                    .font(.title2)
                                    .foregroundColor(buenFinWhite)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .padding(.trailing, 20)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // Línea divisoria
                    Rectangle()
                        .fill(buenFinWhite.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                }
                .frame(height: 100)
                .background(buenFinRed)
                
                // Contenido principal
                VStack(spacing: 0) {
                    // Barra de búsqueda y controles
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            // Barra de búsqueda
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(buenFinGray.opacity(0.6))
                                
                                TextField("Buscar por nombre o categoría...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(buenFinGray)
                                
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(buenFinGray.opacity(0.6))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(buenFinWhite)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            
                            // Toggle de favoritos
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showFavoritesOnly.toggle()
                                }
                            } label: {
                                Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(showFavoritesOnly ? .yellow : buenFinGray.opacity(0.6))
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(buenFinWhite)
                                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    )
                            }
                        }
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .background(buenFinWhite)
                    
                    // Lista de participantes
                    Group {
                        if data.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                
                                Image(systemName: searchText.isEmpty ? 
                                    (showFavoritesOnly ? "star" : "building.2") :
                                    "magnifyingglass")
                                    .font(.system(size: 60))
                                    .foregroundStyle(buenFinGray.opacity(0.3))
                                
                                VStack(spacing: 8) {
                                    Text(searchText.isEmpty ? 
                                        (showFavoritesOnly ? "Aún no tienes favoritos" : "Sin registros") :
                                        "Sin resultados")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundStyle(buenFinGray)
                                    
                                    Text(searchText.isEmpty ? 
                                        (showFavoritesOnly ? "Marca participantes con la estrella para verlos aquí." : "Aún no hay participantes en la base local.") :
                                        "Intenta con otros términos de búsqueda.")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(buenFinGray.opacity(0.6))
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
