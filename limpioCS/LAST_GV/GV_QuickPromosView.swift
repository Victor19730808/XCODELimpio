import SwiftUI

// Vista ligera para mostrar promociones de un establecimiento
struct GV_QuickPromosView: View {
    let establecimientoId: Int
    let establecimientoNombre: String

    @State private var isLoading = true
    @State private var promos: [Promocion] = []
    @State private var errorText: String? = nil

    private let servicios = Servicios()

    @ObservedObject private var themeManager = GV_Temas_Manager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Caption: nombre del establecimiento con color del banner/tema
            Text(establecimientoNombre)
                .font(themeManager.subheadline)
                .fontWeight(.bold)
                .foregroundColor(themeManager.headerBackground)
                .lineLimit(2)

            // Contenedor visual para mejorar legibilidad
            Group {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Cargando promociones…").font(.caption).foregroundColor(.secondary)
                    }
                } else if let err = errorText {
                    Text(err).font(.caption).foregroundColor(.secondary)
                } else if promos.isEmpty {
                    Text("Sin promociones disponibles").font(.caption).foregroundColor(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(promos, id: \.id) { p in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(p.promocion_titulo ?? "Promoción")
                                        .font(.subheadline).bold()
                                    if let desc = p.promocion_descripcion, !desc.isEmpty {
                                        Text(desc)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(3)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 6)
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let res = try await servicios.obtenerPromociones(establecimientoId: establecimientoId)
            await MainActor.run {
                self.promos = res
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorText = "No se pudieron cargar las promociones."
                self.isLoading = false
            }
        }
    }
}


