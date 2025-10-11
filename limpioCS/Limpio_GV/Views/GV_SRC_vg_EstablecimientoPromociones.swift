//
//  GV_SRC_vg_EstablecimientoPromociones.swift
//  limpioCS
//
//  Created: 2025-01-10
//  Sistema: GV (Temas + Headers + Menús + ScreenTypes)
//

import SwiftUI

// MARK: - Modelos de Respuesta de la API

struct EstablecimientoPromocionResponse: Codable {
    let ev_id: Int
    let ev_nombre: String
    let establecimiento_id: Int
    let establecimiento_nombre: String
    let establecimiento_descripcion: String?
    let establecimiento_logo: String?
    let establecimiento_web: String?
    let establecimiento_status: String
    let establecimiento_actividad: String
    let establecimiento_regimen: String
    let establecimiento_rfc: String
    let establecimiento_giro: String
    let categoria_id: Int
    let categoria_nombre: String
    let camara_descripcion: String
    let email: String
    let phone_number: String
    let direccion_completa: String
    let direccion_latitud: String
    let direccion_longitud: String
    let promocion_id: Int
    let promocion_para: String
    let promocion_codigo_total: Int
    let promocion_fi: String
    let promocion_ff: String
    let promocion_vigencia: String
    let promocion_titulo: String
    let promocion_descripcion: String?
    let promocion_imagen: String?
    let promocion_tyc: String
    let promocion_estatus: Int
    let promocion_aplicacion_tipo: String
    let promocion_aplicacion_indice: Int
    let promocion_tags: String?
    let promocion_codigo: String?
    let evento_id: Int
}

// MARK: - Modelos de Datos Locales

struct EstablecimientoData: Identifiable {
    let id = UUID()
    let establecimientoId: Int
    let nombre: String
    let logoURL: String?
    let descripcion: String?
    let categoria: String
    let categoriaId: Int
    let taxonomia: String
    let telefono: String?
    let web: String?
    let direccion: String?
    let municipio: String?
    let estado: String?
    
    // Datos de ejemplo para testing
    static let ejemplo = EstablecimientoData(
        establecimientoId: 123,
        nombre: "ARMANDO VIDRIOS Y ALUMINIOS",
        logoURL: nil,
        descripcion: "EMPRESA 100% FAMILIAR CAMPECHANA dedicada a la comercialización de perfiles de aluminio, herrajes, policarbonatos, plásticos y accesorios para la construcción.",
        categoria: "Reparaciones y mantenimiento",
        categoriaId: 4533,
        taxonomia: "Reparación y mantenimiento",
        telefono: "9811037138",
        web: "www.armandoaluminios.com",
        direccion: "Calle Principal 123, Centro",
        municipio: "Campeche",
        estado: "Campeche"
    )
}

struct PromocionData: Identifiable {
    let id = UUID()
    let titulo: String
    let descripcion: String?
    let imagenURL: String?
    let descuento: String
    let fechaInicio: String
    let fechaFin: String
    let terminosCondiciones: String
    let codigoPromocional: String?
    let categoriaPromocion: String
    
    // Datos de ejemplo para testing
    static let ejemplos = [
        PromocionData(
            titulo: "10% EN HERRAJES EN GENERAL DE LA MARCA HERRALUM",
            descripcion: "Descuento especial en toda la línea de herrajes Herralum",
            imagenURL: nil,
            descuento: "10%",
            fechaInicio: "26 Sep 2025",
            fechaFin: "26 Dec 2025",
            terminosCondiciones: "PRECIOS SUJETOS A EXISTENCIAS Y A MÍNIMOS DE COMPRA",
            codigoPromocional: "HERRALUM10",
            categoriaPromocion: "Herrajes"
        ),
        PromocionData(
            titulo: "15% EN VIDRIOS TEMPLADOS",
            descripcion: "Oferta especial en vidrios templados de seguridad",
            imagenURL: nil,
            descuento: "15%",
            fechaInicio: "01 Oct 2025",
            fechaFin: "31 Oct 2025",
            terminosCondiciones: "Válido solo en vidrios templados estándar",
            codigoPromocional: nil,
            categoriaPromocion: "Vidrios"
        )
    ]
}

struct GV_SRC_vg_EstablecimientoPromociones: View {
    // MARK: - Parámetros de entrada
    let establecimientoId: Int
    
    // MARK: - Configuración del Sistema GV
    private let screenType: ScreenType = .general
    private let myHeader: GV_HeaderType = .tipo2
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    // MARK: - Estados
    @Environment(\.dismiss) private var dismiss
    
    // Datos dinámicos
    @State private var establecimiento: EstablecimientoData?
    @State private var promociones: [PromocionData] = []
    @State private var showFavoritoConfirmation = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var datosEstado: String = "Cargando..."
    @ObservedObject private var favoritosManager = GV_FavoritosManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con menú - TODO EN UNA SOLA LÍNEA! 🎯
            myHeader.headerViewWithMenu("Promociones", nil, .principal)
            
            // Contenido principal con tema aplicado
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Cargando promociones...")
                        .font(themeManager.body)
                        .foregroundColor(themeManager.textSecondary)
                        .padding(.top, 16)
                    Spacer()
                }
            } else if let errorMessage = errorMessage {
                VStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.error)
                    Text("Error")
                        .font(themeManager.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textPrimary)
                    Text(errorMessage)
                        .font(themeManager.body)
                        .foregroundColor(themeManager.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
            } else if let establecimiento = establecimiento {
                ScrollView {
                    VStack(spacing: themeManager.spacing * 2) {
                    // Header del establecimiento
                    EstablecimientoHeaderCard(establecimiento: establecimiento, showFavoritoConfirmation: $showFavoritoConfirmation)
                        .padding(.horizontal, themeManager.paddingMedium)
                    
                    // Leyenda de estado de los datos (solo cuando NO son datos reales)
                    if !datosEstado.contains("REALES") {
                        HStack {
                            Image(systemName: datosEstado.contains("REAL") ? "checkmark.circle.fill" : 
                                  datosEstado.contains("PRUEBA") ? "exclamationmark.triangle.fill" : "questionmark.circle.fill")
                                .foregroundColor(datosEstado.contains("REAL") ? .green : 
                                               datosEstado.contains("PRUEBA") ? .orange : .blue)
                            
                            Text(datosEstado)
                                .font(.caption)
                                .foregroundColor(datosEstado.contains("REAL") ? .green : 
                                               datosEstado.contains("PRUEBA") ? .orange : .blue)
                            
                            Spacer()
                        }
                        .padding(.horizontal, themeManager.paddingMedium)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(datosEstado.contains("REAL") ? Color.green.opacity(0.1) : 
                                     datosEstado.contains("PRUEBA") ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                        )
                        .padding(.horizontal, themeManager.paddingMedium)
                    }
                        
                        // Sección de promociones
                        VStack(alignment: .leading, spacing: themeManager.spacing) {
                        // Header de promociones (subheader translúcido)
                        HStack {
                            Text("Promociones")
                                .font(themeManager.headline)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.subheaderText)
                            
                            Spacer()
                            
                            Text("\(promociones.count) disponibles")
                                .font(themeManager.caption)
                                .foregroundColor(themeManager.subheaderText.opacity(0.8))
                        }
                        .padding(.horizontal, themeManager.paddingMedium)
                        .padding(.vertical, 12)
                        .background(themeManager.subheaderBackground)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: themeManager.cornerRadius,
                                topTrailingRadius: themeManager.cornerRadius
                            )
                        )
                        
                        // Lista de promociones
                        VStack(spacing: themeManager.spacing) {
                            ForEach(promociones) { promocion in
                                PromocionCardView(promocion: promocion)
                            }
                        }
                        .padding(themeManager.paddingMedium)
                        .background(themeManager.cardBackground)
                        .clipShape(
                            UnevenRoundedRectangle(
                                bottomLeadingRadius: themeManager.cornerRadius,
                                bottomTrailingRadius: themeManager.cornerRadius
                            )
                        )
                        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 4)
                        }
                        .padding(.horizontal, themeManager.paddingMedium)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
        }
        .background(themeManager.background)
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
        .navigationBarHidden(true)
        .onAppear {
            datosEstado = "🔄 Cargando datos para establecimiento ID: \(establecimientoId)..."
            loadPromociones()
        }
        .alert("Favoritos", isPresented: $showFavoritoConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button(favoritosManager.isFavorite(establecimientoId: establecimiento?.establecimientoId ?? 0) ? "Quitar" : "Agregar") {
                toggleFavorito()
            }
        } message: {
            Text(favoritosManager.isFavorite(establecimientoId: establecimiento?.establecimientoId ?? 0) ? 
                "¿Quieres quitar \"\(establecimiento?.nombre ?? "")\" de tus favoritos?" :
                "¿Quieres agregar \"\(establecimiento?.nombre ?? "")\" a tus favoritos?")
        }
    }
    
    // MARK: - Funciones
    
    private func loadPromociones() {
        guard let url = URL(string: "https://canacocard-ms-backend.azurewebsites.net/api/evento/1/promociones/establecimiento/\(establecimientoId)") else {
            errorMessage = "URL inválida"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                // Debug: Verificar respuesta HTTP
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 Status HTTP: \(httpResponse.statusCode)")
                    print("📊 Headers: \(httpResponse.allHeaderFields)")
                }
                
                if let error = error {
                    print("❌ Error de red: \(error.localizedDescription)")
                    errorMessage = "Error de conexión: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No se recibieron datos"
                    return
                }
                
                // Debug: Imprimir respuesta de la API
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📡 Respuesta de la API para establecimiento \(establecimientoId):")
                    print("📏 Longitud de respuesta: \(jsonString.count) caracteres")
                    print("📄 Contenido:")
                    print(jsonString)
                    print("📄 Fin de respuesta")
                    print(String(repeating: "=", count: 50))
                }
                
                // Primero intentar parsear como JSON genérico para ver la estructura
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("🔍 Estructura JSON detectada:")
                        print("   - Tipo: Dictionary")
                        print("   - Claves: \(jsonObject.keys.sorted())")
                        
                        // Si tiene una clave que parece promociones
                        if let promocionesKey = jsonObject.keys.first(where: { $0.lowercased().contains("promocion") || $0.lowercased().contains("promotion") }) {
                            print("   - Clave de promociones encontrada: '\(promocionesKey)'")
                            if let promocionesArray = jsonObject[promocionesKey] as? [Any] {
                                print("   - Cantidad de promociones: \(promocionesArray.count)")
                                if let primeraPromocion = promocionesArray.first as? [String: Any] {
                                    print("   - Claves de la primera promoción: \(primeraPromocion.keys.sorted())")
                                }
                            }
                        }
                    } else if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                        print("🔍 Estructura JSON detectada:")
                        print("   - Tipo: Array")
                        print("   - Cantidad de elementos: \(jsonArray.count)")
                        if let primerElemento = jsonArray.first as? [String: Any] {
                            print("   - Claves del primer elemento: \(primerElemento.keys.sorted())")
                        }
                    }
                } catch {
                    print("⚠️ No se pudo parsear como JSON genérico: \(error)")
                }
                
                do {
                    // Ahora intentar parsear con nuestro modelo
                    let responses = try JSONDecoder().decode([EstablecimientoPromocionResponse].self, from: data)
                    print("✅ API devolvió \(responses.count) registros")
                    
                    if !responses.isEmpty {
                        if let primerRegistro = responses.first {
                            // Debug: Mostrar datos del establecimiento
                            print("🏢 Establecimiento: \(primerRegistro.establecimiento_nombre)")
                            print("🖼️ Logo URL: \(primerRegistro.establecimiento_logo ?? "nil")")
                            print("📞 Teléfono: \(primerRegistro.phone_number)")
                            print("🌐 Web: \(primerRegistro.establecimiento_web ?? "nil")")
                            print("📍 Dirección: \(primerRegistro.direccion_completa)")
                            print("🎯 Promoción: \(primerRegistro.promocion_titulo)")
                            print("🖼️ Imagen promoción: \(primerRegistro.promocion_imagen ?? "nil")")
                            
                            // Crear datos del establecimiento desde el primer registro
                            establecimiento = EstablecimientoData(
                                establecimientoId: primerRegistro.establecimiento_id,
                                nombre: primerRegistro.establecimiento_nombre,
                                logoURL: primerRegistro.establecimiento_logo,
                                descripcion: primerRegistro.establecimiento_descripcion,
                                categoria: primerRegistro.categoria_nombre,
                                categoriaId: primerRegistro.categoria_id,
                                taxonomia: primerRegistro.promocion_tags ?? "Sin taxonomía",
                                telefono: primerRegistro.phone_number,
                                web: primerRegistro.establecimiento_web,
                                direccion: primerRegistro.direccion_completa,
                                municipio: "Campeche", // Extraer de direccion_completa si es necesario
                                estado: "Campeche"   // Extraer de direccion_completa si es necesario
                            )
                            
                            // Marcar como datos reales de la API
                            datosEstado = "✅ DATOS REALES de la API (\(responses.count) registros)"
                            
                            // Convertir registros de la API a promociones
                            promociones = responses.map { response in
                                PromocionData(
                                    titulo: response.promocion_titulo,
                                    descripcion: response.promocion_descripcion,
                                    imagenURL: response.promocion_imagen,
                                    descuento: response.promocion_titulo, // Usar el título como badge principal
                                    fechaInicio: formatDate(response.promocion_fi),
                                    fechaFin: formatDate(response.promocion_ff),
                                    terminosCondiciones: response.promocion_tyc,
                                    codigoPromocional: response.promocion_codigo,
                                    categoriaPromocion: response.promocion_tags ?? response.categoria_nombre
                                )
                            }
                        }
                    } else {
                        // Si no hay promociones pero la API respondió, crear establecimiento con ID
                        print("⚠️ API respondió pero sin promociones para establecimiento ID: \(establecimientoId)")
                        
                        // Crear datos de establecimiento básico con el ID real
                        establecimiento = EstablecimientoData(
                            establecimientoId: establecimientoId,
                            nombre: "Establecimiento #\(establecimientoId)",
                            logoURL: nil, // Sin logo hasta que tengamos datos reales
                            descripcion: "Establecimiento participante en el evento Buen Fin",
                            categoria: "General",
                            categoriaId: 0,
                            taxonomia: "Comercio",
                            telefono: nil,
                            web: nil,
                            direccion: nil,
                            municipio: nil,
                            estado: nil
                        )
                        
                        promociones = [] // Sin promociones
                        datosEstado = "⚠️ API respondió pero SIN promociones para ID \(establecimientoId)"
                    }
                } catch {
                    // En caso de error de parsing, usar datos de ejemplo para desarrollo
                    print("⚠️ Error al parsear API: \(error.localizedDescription), usando datos de ejemplo")
                    
                    establecimiento = EstablecimientoData(
                        establecimientoId: establecimientoId,
                        nombre: "ARMANDO VIDRIOS Y ALUMINIOS",
                        logoURL: "https://via.placeholder.com/100x100/FF0000/FFFFFF?text=AV", // Logo de ejemplo
                        descripcion: "EMPRESA 100% FAMILIAR CAMPECHANA dedicada a la comercialización de perfiles de aluminio, herrajes, policarbonatos, plásticos y accesorios para la construcción.",
                        categoria: "Reparaciones y mantenimiento",
                        categoriaId: 4533,
                        taxonomia: "Reparación y mantenimiento",
                        telefono: "9811037138",
                        web: "www.armandoaluminios.com",
                        direccion: "Calle Principal 123, Centro",
                        municipio: "Campeche",
                        estado: "Campeche"
                    )
                    
                    promociones = PromocionData.ejemplos
                    datosEstado = "🧪 DATOS DE PRUEBA (Error de API: \(error.localizedDescription))"
                }
            }
        }.resume()
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd MMM yyyy"
            displayFormatter.locale = Locale(identifier: "es_MX")
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func toggleFavorito() {
        guard let currentEstablecimiento = establecimiento else { return }
        
        // Usar el manager de favoritos
        favoritosManager.toggleFavorite(establecimientoId: currentEstablecimiento.establecimientoId)
        let nuevoEstadoFavorito = favoritosManager.isFavorite(establecimientoId: currentEstablecimiento.establecimientoId)
        
        // No necesitamos actualizar el establecimiento porque el favoritosManager
        // ya maneja el estado y SwiftUI se actualizará automáticamente
        
        print("🔄 Favorito toggled para: \(currentEstablecimiento.nombre) - Es favorito: \(nuevoEstadoFavorito)")
        
        print("⭐ Favorito \(favoritosManager.isFavorite(establecimientoId: establecimiento?.establecimientoId ?? 0) ? "agregado" : "quitado"): \(establecimiento?.nombre ?? "")")
    }
    
    private func openInMaps(address: String) {
        print("🗺️ Abriendo mapa para dirección: \(address)")
        
        // Crear URL para Maps de Apple
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mapsURL = "http://maps.apple.com/?q=\(encodedAddress)"
        
        if let url = URL(string: mapsURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        print("✅ Mapa abierto exitosamente")
                    } else {
                        print("❌ Error al abrir el mapa")
                    }
                }
            } else {
                print("❌ No se puede abrir Maps")
            }
        } else {
            print("❌ URL inválida para Maps")
        }
    }
}

// MARK: - Componentes de UI

struct EstablecimientoHeaderCard: View {
    let establecimiento: EstablecimientoData
    @Binding var showFavoritoConfirmation: Bool
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    @ObservedObject private var favoritosManager = GV_FavoritosManager.shared
    
    private func openInMaps(address: String) {
        print("🗺️ Abriendo mapa para dirección: \(address)")
        
        // Crear URL para Maps de Apple
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mapsURL = "http://maps.apple.com/?q=\(encodedAddress)"
        
        if let url = URL(string: mapsURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        print("✅ Mapa abierto exitosamente")
                    } else {
                        print("❌ Error al abrir el mapa")
                    }
                }
            } else {
                print("❌ No se puede abrir Maps")
            }
        } else {
            print("❌ URL inválida para Maps")
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header con logo y nombre (logo más protagonista)
            HStack(spacing: 20) {
                // Logo del establecimiento (más grande y prominente)
                AsyncImage(url: URL(string: establecimiento.logoURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    // Placeholder con iniciales
                    let iniciales = String(establecimiento.nombre.prefix(2)).uppercased()
                    Text(iniciales)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            Circle()
                                .fill(themeManager.primary)
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: themeManager.shadow, radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 10) {
                    // Nombre del establecimiento (tamaño ajustado)
                    Text(establecimiento.nombre)
                        .font(themeManager.headline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // ID del establecimiento (temporal para debug)
                    Text("ID: \(establecimiento.establecimientoId)")
                        .font(.caption2)
                        .foregroundColor(themeManager.textSecondary.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeManager.surface.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    // Solo categoría con icono y caption
                    HStack(spacing: 8) {
                        // Icono de la categoría (buscar por nombre para que coincida el color)
                        if let categoria = GV_CategoriaManager.shared.categoria(byNombre: establecimiento.categoria) {
                            categoria.iconoView(size: 16)
                                .foregroundColor(categoria.color)
                            
                            // Nombre de la categoría con el mismo color
                            Text(establecimiento.categoria)
                                .font(themeManager.caption)
                                .foregroundColor(categoria.color)
                        } else {
                            Image(systemName: "tag.fill")
                                .font(.caption)
                                .foregroundColor(themeManager.textSecondary)
                            
                            // Nombre de la categoría (fallback)
                            Text(establecimiento.categoria)
                                .font(themeManager.caption)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Botón de favorito (ajustado para el nuevo layout)
                Button {
                    showFavoritoConfirmation = true
                } label: {
                    let esFavorito = favoritosManager.isFavorite(establecimientoId: establecimiento.establecimientoId)
                    Image(systemName: esFavorito ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(esFavorito ? .red : themeManager.textSecondary)
                }
            }
            
            // Descripción del establecimiento
            if let descripcion = establecimiento.descripcion, !descripcion.isEmpty {
                Text(descripcion)
                    .font(themeManager.body)
                    .foregroundColor(themeManager.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            
            // Información de contacto y ubicación
            VStack(alignment: .leading, spacing: 8) {
                       // Dirección (clickeable para mapa)
                       if let direccion = establecimiento.direccion, !direccion.isEmpty {
                           Button {
                               openInMaps(address: direccion)
                           } label: {
                               HStack(spacing: 6) {
                                   Image(systemName: "location.fill")
                                       .font(themeManager.caption)
                                       .foregroundColor(themeManager.primary)
                                   Text(direccion)
                                       .font(themeManager.caption)
                                       .foregroundColor(themeManager.textSecondary)
                                       .multilineTextAlignment(.leading)
                                   Spacer()
                               }
                           }
                           .buttonStyle(.plain)
                       }
                
                // Municipio y estado
                if let municipio = establecimiento.municipio, let estado = establecimiento.estado {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(themeManager.caption)
                            .foregroundColor(themeManager.primary)
                        Text("\(municipio), \(estado)")
                            .font(themeManager.caption)
                            .foregroundColor(themeManager.textSecondary)
                        Spacer()
                    }
                }
                
                // Información de contacto
                HStack(spacing: 16) {
                    if let telefono = establecimiento.telefono, !telefono.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                                .font(themeManager.caption)
                                .foregroundColor(themeManager.primary)
                            Text(telefono)
                                .font(themeManager.caption)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }
                    
                    if let web = establecimiento.web, !web.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(themeManager.caption)
                                .foregroundColor(themeManager.primary)
                            Text("Sitio web")
                                .font(themeManager.caption)
                                .foregroundColor(themeManager.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(themeManager.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadius))
        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 4)
    }
}

struct PromocionCardView: View {
    let promocion: PromocionData
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Imagen y Título (Sin color)
            HStack(alignment: .top, spacing: 12) {
                // Imagen de la promoción
                AsyncImage(url: URL(string: promocion.imagenURL ?? themeManager.imagenPromocionDefault)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.surface.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(themeManager.textSecondary.opacity(0.5))
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onAppear {
                    let imagenURL = promocion.imagenURL ?? themeManager.imagenPromocionDefault
                    print("🖼️ Cargando imagen de promoción: \(imagenURL)")
                }
                
                // Título de la promoción
                Text(promocion.titulo)
                    .font(themeManager.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Categoría con su logo y color
            HStack(spacing: 8) {
                // Buscar el icono de la categoría por nombre
                if let categoria = GV_CategoriaManager.shared.categoria(byNombre: promocion.categoriaPromocion) {
                    categoria.iconoView(size: 16)
                        .foregroundColor(categoria.color)
                    
                    Text(promocion.categoriaPromocion)
                        .font(themeManager.caption)
                        .foregroundColor(categoria.color)
                } else {
                    Image(systemName: "tag.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondary)
                    
                    Text(promocion.categoriaPromocion)
                        .font(themeManager.caption)
                        .foregroundColor(themeManager.textSecondary)
                }
            }
            
            // Descripción
            if let descripcion = promocion.descripcion, !descripcion.isEmpty {
                Text(descripcion)
                    .font(themeManager.body)
                    .foregroundColor(themeManager.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
            }
            
            // Vigencia
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(themeManager.caption)
                    .foregroundColor(themeManager.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vigencia")
                        .font(themeManager.caption)
                        .foregroundColor(themeManager.textSecondary)
                    
                    Text("\(promocion.fechaInicio) - \(promocion.fechaFin)")
                        .font(themeManager.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textPrimary)
                }
                
                Spacer()
            }
            
            // Condiciones (Términos y condiciones)
            Text(promocion.terminosCondiciones)
                .font(.caption2)
                .foregroundColor(themeManager.textSecondary.opacity(0.8))
                .multilineTextAlignment(.leading)
                .italic()
                .lineLimit(3)
        }
        .padding(20)
        .background(themeManager.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: themeManager.cornerRadius))
        .shadow(color: themeManager.shadow, radius: themeManager.shadowRadius, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        GV_SRC_vg_EstablecimientoPromociones(establecimientoId: 123)
    }
}
