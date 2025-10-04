import SwiftUI

struct ccp_WebServicesView: View {
    var body: some View {
        List {
            Section("Pruebas rápidas") {
                NavigationLink("Establecimientos (con filtros)") {
                    ccp_WS_EstablecimientosView()
                }
                NavigationLink("Promociones por establecimiento") {
                    ccp_WS_PromocionesView()
                }
            }

            Section("Notas") {
                Text("Estas vistas usan la fachada Servicios y los modelos tolerantes a lat/lon (String o Double).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .navigationTitle("ccp_WebServices")
    }
}

#Preview {
    NavigationStack { ccp_WebServicesView() }
}
