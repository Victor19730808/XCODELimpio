//
//  ccp_BDF_PromocionesView.swift
//  LimpioCS
//
//  Archivo: ccp_BDF_PromocionesView.swift
//  Hora: 2025-10-07 11:05
//  Estado: Limpio para pruebas
//  Migrado: 2025-01-10
//

import SwiftUI

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
    // Referencias de diseño removidas
    @State private var promociones: [PromocionResponse] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Fondo usando el tema actual
            Color.white
                .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Cargando promociones...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Error al cargar")
                        .font(.title)
                        .foregroundColor(.primary)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if promociones.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tag")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.3))
                    
                    Text("Sin promociones")
                        .font(.title)
                        .foregroundColor(.primary)
                    
                    Text("Este establecimiento no tiene promociones disponibles")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Cabecera del establecimiento
                        if let primeraPromocion = promociones.first {
                            EstablecimientoHeaderView(establecimiento: primeraPromocion)
                        }
                        
                        // Separador minimalista para promociones
                        VStack(spacing: 16) {
                            HStack {
                                Spacer()
                                
                                // Título de promociones
                                Text("Promociones")
                                    .font(.title)
                                    .foregroundColor(.primary)
                                
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
}

// MARK: - Cabecera del Establecimiento

struct EstablecimientoHeaderView: View {
    let establecimiento: PromocionResponse
    @Environment(\.dismiss) private var dismiss
    // Referencias de diseño removidas
    
    var body: some View {
        VStack(spacing: 16) {
            // Header minimalista con solo botón cerrar
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    
                    // Botón cerrar
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.red)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 24)
            .padding(.bottom, 8)
            
            // Contenido del establecimiento
            VStack(spacing: 16) {
                // Logo y nombre
                HStack(spacing: 16) {
                    if let logoURL = establecimiento.establecimiento_logo, !logoURL.isEmpty {
                        AsyncImage(url: URL(string: logoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    Image(systemName: "building.2")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                Image(systemName: "building.2")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                            )
                            .frame(width: 80, height: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(establecimiento.establecimiento_nombre ?? "Sin nombre")
                            .font(.title)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(establecimiento.categoria_nombre ?? "Sin categoría")
                            .font(.body)
                            .foregroundColor(Color.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        
                        Text(establecimiento.establecimiento_actividad ?? "Sin actividad")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Descripción
                if let descripcion = establecimiento.establecimiento_descripcion, !descripcion.isEmpty {
                    Text(descripcion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                }
                
                // Información de contacto
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contacto")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text(establecimiento.display_name ?? "Sin contacto")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Teléfono")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text(establecimiento.phone_number ?? "Sin teléfono")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Tarjeta de Promoción

struct PromocionCardView: View {
    let promocion: PromocionResponse
    // Referencias de diseño removidas
    
    var body: some View {
        VStack(spacing: 16) {
            // Imagen de la promoción (solo si existe)
            if let imagenURL = promocion.promocion_imagen, !imagenURL.isEmpty {
                AsyncImage(url: URL(string: imagenURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Contenido de la promoción
            VStack(alignment: .leading, spacing: 12) {
                // Título
                Text(promocion.promocion_titulo ?? "Sin título")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Descripción
                Text(promocion.promocion_descripcion ?? "Sin descripción")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                // Fechas
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Inicio")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(promocion.promocion_fi ?? ""))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fin")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(promocion.promocion_ff ?? ""))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                
                // Términos y condiciones
                if let tyc = promocion.promocion_tyc, !tyc.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Términos y Condiciones")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text(tyc)
                            .font(.caption)
                            .foregroundColor(Color.red)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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









