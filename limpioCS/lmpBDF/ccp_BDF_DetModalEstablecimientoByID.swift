//
//  ccp_BDF_DetModalEstablecimientoByID.swift
//  CONSERVI2 · Proyecto: LimpioCS
//
//  Cliente: Concanaco ServyTur
//  Performed by: Grupo VAL Human TECH
//
//  Descripción:
//  ----------------------------------------------------------------
//  • Vista reusable para mostrar detalle simple de un establecimiento.
//  • Wrapper que permite abrir el detalle pasando solo un ID (Int64).
//  • Usa SwiftData (@Query) para resolver el modelo por ID exacto.
//  • Botón “Promociones” que presenta una sheet independiente.
//  • Muestra y permite alternar Favoritos con confirmación.
//  • Embellecida con gradiente, badges y tarjetas.
//  • iOS 17+
//
//  Fecha: 2025-10-04
//

import SwiftUI
import SwiftData
import MapKit

// MARK: - 1) Vista reusable (recibe el modelo completo)

struct EstablecimientoDetalleSheetSimple: View {
    @Environment(\.modelContext) private var modelContext

    // @Bindable para editar propiedades del modelo SwiftData desde aquí
    @Bindable var est: lmpBDF_EstablecimientoLocal

    @State private var showPromos = false
    @State private var showConfirmAddFav = false
    @State private var showConfirmRemoveFav = false

    init(est: lmpBDF_EstablecimientoLocal) {
        self.est = est
    }

    var body: some View {
        VStack(spacing: 0) {
            // Encabezado vistoso con gradiente + título + pill favorito
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color.red.opacity(0.85), Color.red.opacity(0.55)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 140)
                .ignoresSafeArea(edges: .top)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 10) {
                        // Avatar inicial
                        ZStack {
                            Circle().fill(Color.white.opacity(0.18)).frame(width: 48, height: 48)
                            Text(String(est.nombre.prefix(1)).uppercased())
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(est.nombre)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .lineLimit(2)

                            // ID visible y legible
                            HStack(spacing: 6) {
                                Text("ID:")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                Text("\(est.id)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.white.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(.white.opacity(0.15))
                                    )
                            }
                        }

                        Spacer()

                        // Botón estrella en toolbar visual
                        Button {
                            // Mostrar confirmación según estado actual
                            est.esFavorito ? (showConfirmRemoveFav = true) : (showConfirmAddFav = true)
                        } label: {
                            Image(systemName: est.esFavorito ? "star.fill" : "star")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(est.esFavorito ? .yellow : .white)
                                .padding(10)
                                .background(
                                    Circle().fill(Color.white.opacity(0.15))
                                )
                                .accessibilityLabel(est.esFavorito ? "Quitar de favoritos" : "Agregar a favoritos")
                        }
                        .buttonStyle(.plain)
                    }

                    // Badge/pill informativo de favorito
                    HStack(spacing: 8) {
                        if est.esFavorito {
                            Label("Favorito", systemImage: "star.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(Color.yellow.opacity(0.15))
                                )
                        } else {
                            Label("No es favorito", systemImage: "star")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(Color.white.opacity(0.12))
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }

            // Contenido
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    // Tarjeta con datos básicos
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            row(label: "Estado", value: est.estado)
                            row(label: "Municipio", value: est.municipio)
                            row(label: "Categoría", value: est.categoria)
                            if let lat = est.lat, let lon = est.lon {
                                rowMono(label: "Coordenadas", value: String(format: "%.5f, %.5f", lat, lon))
                            }
                        }
                        .padding(.top, 2)
                    } label: {
                        Label("Información", systemImage: "info.circle.fill")
                    }

                    // Acciones
                    GroupBox {
                        HStack(spacing: 12) {
                            Button {
                                showPromos = true
                            } label: {
                                pill(icon: "tag.fill", text: "Promociones", tint: .blue)
                            }
                            .buttonStyle(.plain)

                            // Alternativa de favorito como botón textual adicional
                            Button {
                                est.esFavorito ? (showConfirmRemoveFav = true) : (showConfirmAddFav = true)
                            } label: {
                                pill(icon: est.esFavorito ? "star.slash.fill" : "star.fill",
                                     text: est.esFavorito ? "Quitar de favoritos" : "Agregar a favoritos",
                                     tint: est.esFavorito ? .orange : .yellow)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    } label: {
                        Label("Acciones", systemImage: "wand.and.stars.inverse")
                    }

                    Spacer(minLength: 12)
                }
                .padding(16)
            }
        }
        // Sheet de promociones
        .sheet(isPresented: $showPromos) {
            NavigationStack {
                ccp_BDF_PromocionesView(establecimientoIdInicial: est.id)
            }
            .presentationDetents([.medium, .large])
        }
        // Confirmación para AGREGAR a favoritos
        .alert("Agregar a favoritos", isPresented: $showConfirmAddFav) {
            Button("Cancelar", role: .cancel) { }
            Button("Agregar", role: .none) {
                est.esFavorito = true
                do { try modelContext.save() } catch {
                    print("⚠️ Error al guardar favorito:", error.localizedDescription)
                }
            }
        } message: {
            Text("¿Quieres agregar “\(est.nombre)” a tus favoritos?")
        }
        // Confirmación para QUITAR de favoritos
        .alert("Quitar de favoritos", isPresented: $showConfirmRemoveFav) {
            Button("Cancelar", role: .cancel) { }
            Button("Quitar", role: .destructive) {
                est.esFavorito = false
                do { try modelContext.save() } catch {
                    print("⚠️ Error al quitar favorito:", error.localizedDescription)
                }
            }
        } message: {
            Text("¿Seguro que quieres quitar “\(est.nombre)” de tus favoritos?")
        }
    }

    // MARK: - UI helpers
    private func row(label: String, value: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(label):").font(.subheadline.weight(.semibold))
            Text(value ?? "—").font(.subheadline).foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func rowMono(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(label):").font(.subheadline.weight(.semibold))
            Text(value).font(.caption.monospaced()).foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func pill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text).fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(tint.opacity(0.15)))
        .foregroundStyle(tint)
    }
}

// MARK: - 2) Wrapper que resuelve por ID (SwiftData)

struct ccp_BDF_DetModalEstablecimientoByID: View {
    private let estabId: Int64
    @Query private var encontrados: [lmpBDF_EstablecimientoLocal]

    init(estabId: Int64) {
        self.estabId = estabId

        // Tu modelo usa Int para 'id'; convertimos desde Int64:
        let idInt = Int(exactly: estabId) ?? -1

        _encontrados = Query(
            filter: #Predicate<lmpBDF_EstablecimientoLocal> { $0.id == idInt },
            sort: [SortDescriptor(\.nombre, comparator: .localizedStandard)]
        )
    }

    var body: some View {
        if let est = encontrados.first {
            EstablecimientoDetalleSheetSimple(est: est)
                .presentationDragIndicator(.visible)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No encontrado")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("ID: \(estabId)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
