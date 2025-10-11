//
//  GV_TestCategoriasView.swift
//  limpioCS
//
//  Vista de prueba para el sistema de categorías con Plist
//  Creado: 2025-01-11
//

import SwiftUI

struct GV_TestCategoriasView: View {
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    @State private var manager = GV_CategoriaManager.shared
    @State private var taxonomiaManager = GV_TaxonomiaManager.shared
    
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var selectedEvento: Int? = nil
    @State private var selectedTaxonomia: String? = nil
    
    // MARK: - Computed Properties
    
    private var categoriasFiltradas: [GV_Categoria] {
        var resultado = manager.categorias
        
        // Filtrar por evento si está seleccionado
        if let eventoId = selectedEvento {
            resultado = resultado.filter { $0.evento_id == eventoId }
        }
        
        // Filtrar por taxonomía si está seleccionada
        if let taxonomia = selectedTaxonomia {
            resultado = resultado.filter { $0.categoria_taxonomia == taxonomia }
        }
        
        // Filtrar por búsqueda
        if !searchText.isEmpty {
            resultado = resultado.filter { $0.matches(searchTerm: searchText) }
        }
        
        return resultado.sorted { $0.categoria_nombre < $1.categoria_nombre }
    }
    
    private var eventosUnicos: [Int] {
        Array(Set(manager.categorias.map { $0.evento_id })).sorted()
    }
    
    private var taxonomiasUnicas: [String] {
        Array(Set(manager.categorias.map { $0.categoria_taxonomia })).sorted()
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Tab 1: Categorías
                categoriasTabView
                    .tabItem {
                        Label("Categorías", systemImage: "tag.fill")
                    }
                    .tag(0)
                
                // Tab 2: Taxonomías
                taxonomiasTabView
                    .tabItem {
                        Label("Taxonomías", systemImage: "folder.fill")
                    }
                    .tag(1)
            }
            .background(themeManager.background)
            .navigationTitle(selectedTab == 0 ? "🏷️ Categorías" : "📁 Taxonomías")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if selectedTab == 0 {
                            manager.reload()
                        } else {
                            taxonomiaManager.reload()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(themeManager.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Tabs
    
    private var categoriasTabView: some View {
        VStack(spacing: 0) {
            // Header con estadísticas
            headerView
            
            // Filtros
            filtrosView
            
            // Lista de categorías
            if manager.isLoaded {
                if categoriasFiltradas.isEmpty {
                    emptyStateView
                } else {
                    listaCategorias
                }
            } else if let error = manager.loadError {
                errorView(error)
            } else {
                ProgressView("Cargando categorías...")
            }
        }
    }
    
    private var taxonomiasTabView: some View {
        VStack(spacing: 0) {
            // Header con estadísticas de taxonomías
            taxonomiasHeaderView
            
            // Lista de taxonomías
            if taxonomiaManager.isLoaded {
                listaTaxonomias
            } else if let error = taxonomiaManager.loadError {
                errorView(error)
            } else {
                ProgressView("Cargando taxonomías...")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatCard(title: "Total", value: "\(manager.totalCategorias)", icon: "tag.fill", color: themeManager.primary)
                StatCard(title: "Eventos", value: "\(manager.totalEventos)", icon: "calendar", color: themeManager.cardSecondary)
                StatCard(title: "Taxonomías", value: "\(manager.totalTaxonomias)", icon: "folder.fill", color: themeManager.cardSuccess)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Barra de búsqueda
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.textSecondary)
                
                TextField("Buscar categorías...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(themeManager.body)
                    .foregroundColor(themeManager.textPrimary)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.textSecondary)
                    }
                }
            }
            .padding(12)
            .background(themeManager.surface)
            .cornerRadius(themeManager.cornerRadius)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(themeManager.cardBackground)
        .shadow(color: themeManager.shadow, radius: 4, y: 2)
    }
    
    private var filtrosView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Filtro por evento
                Menu {
                    Button("Todos los eventos") {
                        selectedEvento = nil
                    }
                    ForEach(eventosUnicos, id: \.self) { evento in
                        Button("Evento \(evento)") {
                            selectedEvento = evento
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text(selectedEvento != nil ? "Evento \(selectedEvento!)" : "Todos")
                        Image(systemName: "chevron.down")
                    }
                    .font(themeManager.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedEvento != nil ? themeManager.primary.opacity(0.2) : themeManager.surface)
                    .foregroundColor(selectedEvento != nil ? themeManager.primary : themeManager.textPrimary)
                    .cornerRadius(themeManager.cornerRadius)
                }
                
                // Filtro por taxonomía
                Menu {
                    Button("Todas las taxonomías") {
                        selectedTaxonomia = nil
                    }
                    ForEach(taxonomiasUnicas, id: \.self) { taxonomia in
                        Button(taxonomia) {
                            selectedTaxonomia = taxonomia
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text(selectedTaxonomia ?? "Todas")
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                    }
                    .font(themeManager.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedTaxonomia != nil ? themeManager.primary.opacity(0.2) : themeManager.surface)
                    .foregroundColor(selectedTaxonomia != nil ? themeManager.primary : themeManager.textPrimary)
                    .cornerRadius(themeManager.cornerRadius)
                }
                
                // Botón para limpiar filtros
                if selectedEvento != nil || selectedTaxonomia != nil {
                    Button {
                        selectedEvento = nil
                        selectedTaxonomia = nil
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Limpiar")
                        }
                        .font(themeManager.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(themeManager.error.opacity(0.2))
                        .foregroundColor(themeManager.error)
                        .cornerRadius(themeManager.cornerRadius)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(themeManager.background)
    }
    
    private var listaCategorias: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Text("\(categoriasFiltradas.count) categorías")
                    .font(themeManager.caption)
                    .foregroundColor(themeManager.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                ForEach(categoriasFiltradas) { categoria in
                    CategoriaCard(categoria: categoria)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(themeManager.textSecondary.opacity(0.5))
            
            Text("No se encontraron categorías")
                .font(themeManager.headline)
                .foregroundColor(themeManager.textPrimary)
            
            Text("Intenta con otros filtros o búsqueda")
                .font(themeManager.caption)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.error)
            
            Text("Error al cargar")
                .font(themeManager.headline)
                .foregroundColor(themeManager.textPrimary)
            
            Text(error)
                .font(themeManager.caption)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                manager.reload()
            } label: {
                Text("Reintentar")
                    .font(themeManager.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(themeManager.primary)
                    .cornerRadius(themeManager.cornerRadius)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Taxonomías Views
    
    private var taxonomiasHeaderView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatCard(title: "Total", value: "\(taxonomiaManager.totalTaxonomias)", icon: "folder.fill", color: themeManager.primary)
                StatCard(title: "Categorías", value: "\(manager.totalCategorias)", icon: "tag.fill", color: themeManager.cardSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .background(themeManager.cardBackground)
        .shadow(color: themeManager.shadow, radius: 4, y: 2)
    }
    
    private var listaTaxonomias: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Text("\(taxonomiaManager.totalTaxonomias) taxonomías")
                    .font(themeManager.caption)
                    .foregroundColor(themeManager.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                ForEach(taxonomiaManager.todasLasTaxonomias) { taxonomia in
                    TaxonomiaCard(taxonomia: taxonomia)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Subcomponentes

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(themeManager.surface)
        .cornerRadius(themeManager.cornerRadius)
    }
}

struct CategoriaCard: View {
    let categoria: GV_Categoria
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header con icono y nombre
            HStack(spacing: 12) {
                categoria.iconoView(size: 28)
                    .foregroundColor(categoria.color)
                    .frame(width: 40, height: 40)
                    .background(categoria.colorOpaco)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(categoria.categoria_nombre)
                        .font(themeManager.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Text("ID: \(categoria.categoria_id)")
                        .font(themeManager.caption)
                        .foregroundColor(themeManager.textSecondary)
                }
                
                Spacer()
                
                Text("Evento \(categoria.evento_id)")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.primary.opacity(0.1))
                    .foregroundColor(themeManager.primary)
                    .cornerRadius(6)
            }
            
            // Taxonomía con icono
            if let taxonomia = GV_TaxonomiaManager.shared.taxonomia(byNombre: categoria.categoria_taxonomia) {
                Text(categoria.categoria_taxonomia)
                    .taxonomiaTag(taxonomia)
            } else {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondary)
                    
                    Text(categoria.categoria_taxonomia)
                        .font(themeManager.caption)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
            
            // Tags
            if !categoria.tagsArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categoria.tagsArray.prefix(5), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeManager.surface)
                                .foregroundColor(themeManager.textSecondary)
                                .cornerRadius(6)
                        }
                        
                        if categoria.tagsArray.count > 5 {
                            Text("+\(categoria.tagsArray.count - 5)")
                                .font(.caption2)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }
                }
            }
            
            // Color preview
            HStack(spacing: 8) {
                Text("Color:")
                    .font(themeManager.caption)
                    .foregroundColor(themeManager.textSecondary)
                
                Text(categoria.colorHex)
                    .font(.caption2)
                    .monospaced()
                    .foregroundColor(themeManager.textSecondary)
                
                Spacer()
                
                Circle()
                    .fill(categoria.color)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(themeManager.textSecondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .background(themeManager.cardBackground)
        .cornerRadius(themeManager.cornerRadius)
        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, y: 2)
    }
}

// MARK: - Taxonomía Card

struct TaxonomiaCard: View {
    let taxonomia: GV_Taxonomia
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    @State private var manager = GV_CategoriaManager.shared
    
    // Categorías que pertenecen a esta taxonomía
    private var categoriasCount: Int {
        manager.categorias.filter { $0.categoria_taxonomia == taxonomia.nombre }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header con icono y nombre
            HStack(spacing: 12) {
                taxonomia.iconoView(size: 28)
                    .foregroundColor(taxonomia.color)
                    .frame(width: 40, height: 40)
                    .background(taxonomia.colorOpaco)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(taxonomia.nombre)
                        .font(themeManager.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Text("\(categoriasCount) categorías")
                        .font(themeManager.caption)
                        .foregroundColor(themeManager.textSecondary)
                }
                
                Spacer()
            }
            
            // Color preview
            HStack(spacing: 8) {
                Text("Color:")
                    .font(themeManager.caption)
                    .foregroundColor(themeManager.textSecondary)
                
                Text(taxonomia.colorHex)
                    .font(.caption2)
                    .monospaced()
                    .foregroundColor(themeManager.textSecondary)
                
                Spacer()
                
                Circle()
                    .fill(taxonomia.color)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(themeManager.textSecondary.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Icono SF Symbol
            HStack(spacing: 8) {
                Text("Icono:")
                    .font(themeManager.caption)
                    .foregroundColor(themeManager.textSecondary)
                
                Text(taxonomia.icono)
                    .font(.caption2)
                    .monospaced()
                    .foregroundColor(themeManager.textSecondary)
                
                Spacer()
            }
        }
        .padding(16)
        .background(themeManager.cardBackground)
        .cornerRadius(themeManager.cornerRadius)
        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, y: 2)
    }
}

#Preview {
    GV_TestCategoriasView()
}

