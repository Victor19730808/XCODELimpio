//
//  ccp_BDF_PromocionesView.swift
//  LimpioCS
//
//  Archivo: ccp_BDF_PromocionesView.swift
//  Hora: 2025-10-07 11:05
//  Estado: Refinado con sistema de temas GV y funcionalidad de favoritos
//  Migrado: 2025-01-10
//  Refinado: 2025-01-10
//

import SwiftUI
import SwiftData

struct ccp_BDF_PromocionesView: View {
    let establecimientoIdInicial: Int
    
    init(establecimientoIdInicial: Int = 41178) {
        self.establecimientoIdInicial = establecimientoIdInicial
    }
    
    var body: some View {
        PromocionesMainView(establecimientoId: establecimientoIdInicial)
    }
}

// MARK: - Modelos de Datos

struct ErrorResponse: Codable {
    let message: String
}

struct PromocionResponse: Codable {
    let ev_id: Int?
    let ev_nombre: String?
    let establecimiento_id: Int // Único campo obligatorio
    let establecimiento_date: String?
    let establecimiento_via: String?
    let establecimiento_nombre: String?
    let establecimiento_razon_social: String?
    let establecimiento_status: String?
    let establecimiento_regimen: String?
    let establecimiento_actividad: String?
    let establecimiento_descripcion: String?
    let establecimiento_web: String?
    let establecimiento_logo: String?
    let establecimiento_rfc: String?
    let establecimiento_giro: String?
    let establecimiento_concaclick: String?
    let establecimiento_concaclick_perfil: String?
    let establecimiento_denue: String?
    let establecimiento_comunidades: String?
    let organizacion_id: Int?
    let establecimiento_rfc_validado: String?
    let establecimiento_rnt: String?
    let rs_facebook: String?
    let rs_instagram: String?
    let rs_x: String?
    let camara_id: Int?
    let usuario_id: Int?
    let categoria_id: Int?
    let categoria_nombre: String?
    let camara_descripcion: String?
    let email: String?
    let password_hash: String?
    let display_name: String?
    let creation_date: String?
    let last_login: String?
    let role: String?
    let terminos_condiciones: String?
    let phone_number: String?
    let phone_fecha_verificacion: String?
    let phone_codigo_verificacion: Int?
    let phone_verificacion_estatus: String?
    let email_fecha_verificacion: String?
    let email_codigo_verificacion: String?
    let email_verificacion_estatus: String?
    let promocion_id: Int?
    let promocion_para: String?
    let promocion_codigo_total: Int?
    let promocion_fi: String?
    let promocion_ff: String?
    let promocion_vigencia: String?
    let promocion_titulo: String?
    let promocion_descripcion: String?
    let promocion_imagen: String?
    let promocion_tyc: String?
    let promocion_estatus: Int?
    let promocion_aplicacion_tipo: String?
    let promocion_aplicacion_indice: Int?
    let promocion_tags: String?
    let promocion_codigo: String?
    let direccion_completa: String?
    let direccion_latitud: String?
    let direccion_longitud: String?
}

// MARK: - Vista Principal de Promociones

struct PromocionesMainView: View {
    let establecimientoId: Int
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    @State private var promociones: [PromocionResponse] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var establecimientoLocal: lmpBDF_EstablecimientoLocal?
    @State private var showFavoritoConfirmation = false
    
    var body: some View {
        ZStack {
            // Fondo usando el tema actual
            themeManager.background
                .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(themeManager.primary)
                    Text("Cargando promociones...")
                        .font(themeManager.body)
                        .foregroundColor(themeManager.textSecondary)
                }
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.error)
                    
                    Text("Error al cargar")
                        .font(themeManager.title)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Text(error)
                        .font(themeManager.body)
                        .foregroundColor(themeManager.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if promociones.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tag")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.textSecondary.opacity(0.3))
                    
                    Text("Sin promociones")
                        .font(themeManager.title)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Text("Este establecimiento no tiene promociones disponibles")
                        .font(themeManager.body)
                        .foregroundColor(themeManager.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Cabecera del establecimiento
                        if let primeraPromocion = promociones.first {
                            EstablecimientoHeaderView(
                                establecimiento: primeraPromocion,
                                establecimientoLocal: $establecimientoLocal,
                                showFavoritoConfirmation: $showFavoritoConfirmation
                            )
                        }
                        
                        // Separador minimalista para promociones
                        VStack(spacing: 16) {
                            HStack {
                                Spacer()
                                
                                // Título de promociones
                                Text("Promociones")
                                    .font(themeManager.title)
                                    .foregroundColor(themeManager.textPrimary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                        
                        // Lista de promociones
                        LazyVStack(spacing: 16) {
                            ForEach(promociones, id: \.promocion_id) { promocion in
                                PromocionCardView(promocion: promocion)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle("Promociones")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPromociones()
            loadEstablecimientoLocal()
        }
        .alert("Favoritos", isPresented: $showFavoritoConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button(establecimientoLocal?.esFavorito == true ? "Quitar" : "Agregar") {
                toggleFavorito()
            }
        } message: {
            Text(establecimientoLocal?.esFavorito == true ? 
                "¿Quieres quitar \"\(establecimientoLocal?.nombre ?? "este establecimiento")\" de tus favoritos?" :
                "¿Quieres agregar \"\(establecimientoLocal?.nombre ?? "este establecimiento")\" a tus favoritos?")
        }
    }
    
    private func loadPromociones() {
        guard let url = URL(string: "https://canacocard-ms-backend.azurewebsites.net/api/evento/1/promociones/establecimiento/\(establecimientoId)") else {
            errorMessage = "URL inválida"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error de red: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No se recibieron datos"
                    return
                }
                
                // Debug: Imprimir la respuesta JSON
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔍 Respuesta JSON recibida:")
                    print(jsonString.prefix(500)) // Primeros 500 caracteres
                }
                
                do {
                    // Intentar decodificar como array de promociones
                    let promocionesData = try JSONDecoder().decode([PromocionResponse].self, from: data)
                    self.promociones = promocionesData
                    print("✅ Se decodificaron \(promocionesData.count) promociones")
                } catch {
                    // Si falla, intentar decodificar como mensaje de error
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        print("⚠️ Respuesta de error: \(errorResponse.message)")
                        self.promociones = [] // Lista vacía, no es un error
                    } catch {
                        print("❌ Error de decodificación: \(error)")
                        errorMessage = "Error al decodificar datos: \(error.localizedDescription)"
                    }
                }
            }
        }.resume()
    }
    
    private func loadEstablecimientoLocal() {
        // Buscar el establecimiento en la base de datos local
        let descriptor = FetchDescriptor<lmpBDF_EstablecimientoLocal>(
            predicate: #Predicate { $0.id == establecimientoId }
        )
        
        do {
            let establecimientos = try modelContext.fetch(descriptor)
            establecimientoLocal = establecimientos.first
        } catch {
            print("⚠️ Error al cargar establecimiento local:", error.localizedDescription)
        }
    }
    
    private func toggleFavorito() {
        guard let establecimiento = establecimientoLocal else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            establecimiento.esFavorito.toggle()
        }
        
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Error al guardar favorito:", error.localizedDescription)
        }
    }
}

// MARK: - Cabecera del Establecimiento

struct EstablecimientoHeaderView: View {
    let establecimiento: PromocionResponse
    @Binding var establecimientoLocal: lmpBDF_EstablecimientoLocal?
    @Binding var showFavoritoConfirmation: Bool
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header rojo como en la imagen
            HStack {
                Spacer()
                
                Text("Participantes")
                    .font(themeManager.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Botón cerrar
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(themeManager.primary)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: themeManager.cornerRadius,
                    topTrailingRadius: themeManager.cornerRadius
                )
            )
            
            // Contenido del establecimiento
            VStack(spacing: 16) {
                // Logo y nombre
                HStack(spacing: 16) {
                    // Logo del establecimiento
                    if let logoURL = establecimiento.establecimiento_logo, !logoURL.isEmpty {
                        AsyncImage(url: URL(string: logoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themeManager.surface)
                                .overlay(
                                    Image(systemName: "building.2")
                                        .font(.title)
                                        .foregroundColor(themeManager.textSecondary)
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Logo placeholder con letra estilizada
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.primary)
                            .overlay(
                                Text(String(establecimiento.establecimiento_nombre?.prefix(2) ?? "A").uppercased())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                            .frame(width: 80, height: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Nombre del establecimiento
                        Text(establecimiento.establecimiento_nombre ?? "Sin nombre")
                            .font(themeManager.title)
                            .foregroundColor(themeManager.textPrimary)
                            .lineLimit(2)
                        
                        // Categoría con estilo como en la imagen
                        if let categoria = establecimiento.categoria_nombre {
                            Text(categoria)
                                .font(themeManager.callout)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.pink)
                                )
                        }
                        
                        // Tipo de comercio
                        Text("Comercio")
                            .font(themeManager.caption)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Descripción
                if let descripcion = establecimiento.establecimiento_descripcion, !descripcion.isEmpty {
                    Text(descripcion)
                        .font(themeManager.body)
                        .foregroundColor(themeManager.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                }
                
                // Información de contacto
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contacto")
                            .font(themeManager.footnote)
                            .foregroundColor(themeManager.textSecondary)
                        
                        Text(establecimiento.display_name ?? "Sin contacto")
                            .font(themeManager.caption)
                            .foregroundColor(themeManager.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Teléfono")
                            .font(themeManager.footnote)
                            .foregroundColor(themeManager.textSecondary)
                        
                        Text(establecimiento.phone_number ?? "Sin teléfono")
                            .font(themeManager.caption)
                            .foregroundColor(themeManager.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Botón de favoritos
                    Button {
                        showFavoritoConfirmation = true
                    } label: {
                        Image(systemName: establecimientoLocal?.esFavorito == true ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(establecimientoLocal?.esFavorito == true ? themeManager.warning : themeManager.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(themeManager.cardBackground)
            .clipShape(
                UnevenRoundedRectangle(
                    bottomLeadingRadius: themeManager.cornerRadius,
                    bottomTrailingRadius: themeManager.cornerRadius
                )
            )
            .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadius))
        .padding(.horizontal, 20)
    }
}

// MARK: - Tarjeta de Promoción

struct PromocionCardView: View {
    let promocion: PromocionResponse
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Imagen de la promoción (solo si existe)
            if let imagenURL = promocion.promocion_imagen, !imagenURL.isEmpty {
                AsyncImage(url: URL(string: imagenURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius)
                        .fill(themeManager.surface)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(themeManager.primary)
                        )
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadius))
            }
            
            // Contenido de la promoción
            VStack(alignment: .leading, spacing: 12) {
                // Título
                Text(promocion.promocion_titulo ?? "Sin título")
                    .font(themeManager.headline)
                    .foregroundColor(themeManager.textPrimary)
                    .lineLimit(2)
                
                // Descripción
                Text(promocion.promocion_descripcion ?? "Sin descripción")
                    .font(themeManager.body)
                    .foregroundColor(themeManager.textSecondary)
                    .lineLimit(3)
                
                // Fechas
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Inicio")
                            .font(themeManager.footnote)
                            .foregroundColor(themeManager.textSecondary)
                        
                        Text(formatDate(promocion.promocion_fi ?? ""))
                            .font(themeManager.caption)
                            .foregroundColor(themeManager.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fin")
                            .font(themeManager.footnote)
                            .foregroundColor(themeManager.textSecondary)
                        
                        Text(formatDate(promocion.promocion_ff ?? ""))
                            .font(themeManager.caption)
                            .foregroundColor(themeManager.textPrimary)
                    }
                    
                    Spacer()
                }
                
                // Términos y condiciones
                if let tyc = promocion.promocion_tyc, !tyc.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Términos y Condiciones")
                            .font(themeManager.footnote)
                            .foregroundColor(themeManager.textSecondary)
                        
                        Text(tyc)
                            .font(themeManager.caption)
                            .foregroundColor(themeManager.error)
                    }
                }
            }
            .padding(16)
        }
        .background(themeManager.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadius))
        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "dd MMM yyyy"
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

#Preview {
    NavigationStack {
        ccp_BDF_PromocionesView()
    }
}









