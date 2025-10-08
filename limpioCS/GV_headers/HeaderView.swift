//
//  HeaderView.swift
//  limpioCS
//
//  Created by Victor on 2025-01-10.
//  Componente reutilizable de encabezados con diseño responsive
//

import SwiftUI

/// Componente reutilizable para encabezados
struct HeaderView: View {
    let text: String
    let type: HeaderType
    let textColor: Color
    let backgroundColor: Color
    
    @State private var availableWidth: CGFloat = 0
    private let headerManager = HeaderManager.shared
    
    init(
        text: String,
        type: HeaderType,
        textColor: Color = .white,
        backgroundColor: Color = .clear
    ) {
        self.text = text
        self.type = type
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            let style = headerManager.getStyle(for: type)
            let adaptiveFontSize = headerManager.adaptiveFontSize(
                for: type,
                availableWidth: geometry.size.width,
                text: text
            )
            
            Text(text)
                .font(.system(size: adaptiveFontSize, weight: style.fontWeight, design: .default))
                .foregroundColor(textColor)
                .lineLimit(style.lineLimit)
                .truncationMode(style.truncationMode)
                .minimumScaleFactor(style.minScaleFactor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
        }
        .frame(height: calculateOptimalHeight())
        .onAppear {
            updateAvailableWidth()
        }
    }
    
    /// Calcula la altura óptima basada en el tipo de encabezado
    private func calculateOptimalHeight() -> CGFloat {
        let style = headerManager.getStyle(for: type)
        let baseHeight = style.fontSize * 1.2 // Altura base con padding
        
        switch type {
        case .main:
            return baseHeight * CGFloat(style.maxLines) + 8 // Padding adicional para principales
        case .section:
            return baseHeight + 4 // Padding mínimo para secciones
        }
    }
    
    /// Actualiza el ancho disponible (para futuras optimizaciones)
    private func updateAvailableWidth() {
        // Esta función se puede expandir para cálculos más complejos
    }
}

/// Extensión para crear encabezados con colores del tema
extension HeaderView {
    /// Crea un encabezado con colores del tema actual
    static func themed(
        text: String,
        type: HeaderType,
        themeManager: ThemeManager
    ) -> HeaderView {
        return HeaderView(
            text: text,
            type: type,
            textColor: themeManager.currentTheme.colors.textOnPrimary,
            backgroundColor: .clear
        )
    }
    
    /// Crea un encabezado de sección con colores del tema actual
    static func sectionThemed(
        text: String,
        themeManager: ThemeManager
    ) -> HeaderView {
        return HeaderView(
            text: text,
            type: .section,
            textColor: themeManager.currentTheme.colors.textPrimary,
            backgroundColor: .clear
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        // Encabezado principal
        HeaderView(
            text: "Mapa de Cercanías",
            type: .main,
            textColor: .white,
            backgroundColor: .blue
        )
        .frame(height: 60)
        .background(Color.blue)
        
        // Encabezado de sección
        HeaderView(
            text: "Participantes",
            type: .section,
            textColor: .primary,
            backgroundColor: .clear
        )
        
        // Encabezado principal corto
        HeaderView(
            text: "Hecho en México",
            type: .main,
            textColor: .white,
            backgroundColor: .red
        )
        .frame(height: 40)
        .background(Color.red)
        
        Spacer()
    }
    .padding()
}
