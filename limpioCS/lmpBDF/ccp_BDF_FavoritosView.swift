//
//  ccp_BDF_FavoritosView.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Descripción:
//  ----------------------------------------------------------------
//  • Lista de establecimientos marcados como favoritos (esFavorito == true).
//  • Reutiliza el componente ccp_UI_EstablecimientoRow para cada fila.
//  • Ordenado por nombre ascendente.
//  • Muestra estado vacío si no hay favoritos.
//  • Migrado al sistema de temas dinámico.
//
//  Fecha: 2025-10-04
//  Migrado: 2025-01-10
//

import SwiftUI
import SwiftData

struct ccp_BDF_FavoritosView: View {
    // Referencias de diseño removidas
    @State private var showThemeSelector = false
    @State private var showAdminDatos = false
    @State private var showAdvancedSearch = false
    @State private var showMySettings = false
    
    // Trae únicamente favoritos
    @Query(
        filter: #Predicate<lmpBDF_EstablecimientoLocal> { $0.esFavorito == true },
        sort: \.nombre,
        order: .forward
    )
    private var favoritos: [lmpBDF_EstablecimientoLocal]

    var body: some View {
        ZStack {
            // Fondo con gradiente sutil usando el tema actual (igual que Participantes)
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
                // Header con la misma altura que Participantes (100px)
                VStack(spacing: 0) {
                    HStack {
                        // Espacio para balance visual (igual que Participantes)
                        Color.clear
                            .frame(width: 30, height: 30)
                        
                        Spacer()
                        
                        // Título "Mis Favoritos" centrado (usando .section como Participantes)
                            Text("Mis Favoritos")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Menú hamburguesa centralizado
                        // Icono de menú (sin funcionalidad por ahora)
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.trailing, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // Línea divisoria
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                }
                .frame(height: 100)  // Misma altura que Participantes
                .background(Color.red)
                
                // Contenido principal
                VStack(spacing: 0) {
                    if favoritos.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "star")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary.opacity(0.3))
                            
                            VStack(spacing: 8) {
                                Text("Aún no tienes favoritos")
                                    .font(.title)
                                    .foregroundStyle(.primary)
                                
                                Text("Marca establecimientos con la estrella para verlos aquí.")
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
                                ForEach(favoritos) { est in
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showThemeSelector) {
            Text("Selector de Temas")
                .padding()
        }
        .sheet(isPresented: $showAdminDatos) {
            ccp_BDF_DBIncrementalTestView()
        }
        .sheet(isPresented: $showAdvancedSearch) {
            // Vista de búsquedas avanzadas - implementar según necesidad
            Text("Búsquedas Avanzadas")
        }
        .sheet(isPresented: $showMySettings) {
            // Vista de configuraciones - implementar según necesidad
            Text("Mis Configuraciones")
        }
    }
}

#Preview {
    NavigationStack {
        ccp_BDF_FavoritosView()
    }
}

