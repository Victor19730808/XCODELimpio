import Foundation

extension String {
    /// Normaliza cadenas para búsquedas: sin acentos/diacríticos, minúsculas y trim
    var gvNormalized: String {
        // 1) Pasar a forma canónica descompuesta (NFD)
        let decomposed = self.decomposedStringWithCanonicalMapping.lowercased()
        // 2) Quitar marcas combinantes (acentos/diacríticos), esto cubre casos de encoding raros
        let scalarsNoMarks = decomposed.unicodeScalars.filter { !CharacterSet.nonBaseCharacters.contains($0) }
        let withoutMarks = String(String.UnicodeScalarView(scalarsNoMarks))
        // 3) Ancho insensible y eliminación de símbolos redundantes
        let folded = withoutMarks.folding(options: [.widthInsensitive, .caseInsensitive], locale: .current)
        // 4) Mantener solo alfanuméricos y espacios (eliminar comas, puntos, guiones, etc.)
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        let filteredScalars = folded.unicodeScalars.filter { allowed.contains($0) }
        // 5) Colapsar espacios múltiples
        let cleaned = String(String.UnicodeScalarView(filteredScalars))
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }
    
    /// Contiene insensible a acentos y mayúsculas
    func gvContainsInsensitive(_ needle: String) -> Bool {
        let h = self.gvNormalized
        let n = needle.gvNormalized
        return h.range(of: n, options: []) != nil
    }
}


