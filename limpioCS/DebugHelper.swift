//
//  DebugHelper.swift
//  limpioCS
//
//  Created by Victor on 2025-01-14.
//  Sistema inteligente de logging con niveles y control granular
//

import Foundation

// MARK: - Niveles de Log
enum LogLevel: String, CaseIterable {
    case error = "❌ ERROR"
    case warning = "⚠️ WARNING"
    case info = "ℹ️ INFO"
    case debug = "🔍 DEBUG"
    case verbose = "📝 VERBOSE"
}

// MARK: - Categorías de Log
enum LogCategory: String, CaseIterable {
    case location = "📍 LOCATION"
    case network = "🌐 NETWORK"
    case database = "💾 DATABASE"
    case ui = "🎨 UI"
    case business = "💼 BUSINESS"
    case system = "⚙️ SYSTEM"
    case banner = "🖼️ BANNER"
    case favorites = "❤️ FAVORITES"
    case themes = "🎨 THEMES"
    case seed = "🌱 SEED"
    case menu = "📋 MENU"
}

// MARK: - Configuración Global de Logs
struct LogConfig {
    static var enabledLevels: Set<LogLevel> = [.error, .warning, .info]
    static var enabledCategories: Set<LogCategory> = Set(LogCategory.allCases)
    static var showFileInfo: Bool = false
    static var showTimestamp: Bool = true
    static var maxMessageLength: Int = 200
}

// MARK: - Funciones de Log Inteligentes
func log(_ message: String, level: LogLevel = .info, category: LogCategory = .system, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    // Verificar si el nivel y categoría están habilitados
    guard LogConfig.enabledLevels.contains(level) && LogConfig.enabledCategories.contains(category) else { return }
    
    // Truncar mensaje si es muy largo
    let truncatedMessage = message.count > LogConfig.maxMessageLength ? 
        String(message.prefix(LogConfig.maxMessageLength)) + "..." : message
    
    // Construir el mensaje
    var logMessage = "\(level.rawValue) \(category.rawValue): \(truncatedMessage)"
    
    if LogConfig.showTimestamp {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        logMessage = "[\(formatter.string(from: Date()))] \(logMessage)"
    }
    
    if LogConfig.showFileInfo {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logMessage += " [\(fileName):\(line)]"
    }
    
    print(logMessage)
    #endif
}

// MARK: - Funciones de Conveniencia
func errorLog(_ message: String, category: LogCategory = .system, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, level: .error, category: category, file: file, function: function, line: line)
}

func warningLog(_ message: String, category: LogCategory = .system, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, level: .warning, category: category, file: file, function: function, line: line)
}

func infoLog(_ message: String, category: LogCategory = .system, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, level: .info, category: category, file: file, function: function, line: line)
}

func debugLog(_ message: String, category: LogCategory = .system, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, level: .debug, category: category, file: file, function: function, line: line)
}

func verboseLog(_ message: String, category: LogCategory = .system, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, level: .verbose, category: category, file: file, function: function, line: line)
}

// MARK: - Funciones Específicas por Categoría
func locationLog(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, level: level, category: .location, file: file, function: function, line: line)
}

func networkLog(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, level: level, category: .network, file: file, function: function, line: line)
}

func databaseLog(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, level: level, category: .database, file: file, function: function, line: line)
}

func bannerLog(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, level: level, category: .banner, file: file, function: function, line: line)
}

func favoritesLog(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, level: level, category: .favorites, file: file, function: function, line: line)
}

// MARK: - Configuración de Logs para Producción
extension LogConfig {
    static func configureForProduction() {
        enabledLevels = [.error, .warning]
        enabledCategories = [.system, .network, .database]
        showFileInfo = false
        showTimestamp = true
        maxMessageLength = 100
    }
    
    static func configureForDevelopment() {
        enabledLevels = Set(LogLevel.allCases)
        enabledCategories = Set(LogCategory.allCases)
        showFileInfo = true
        showTimestamp = true
        maxMessageLength = 500
    }
    
    static func configureMinimal() {
        enabledLevels = [.error]
        enabledCategories = [.system]
        showFileInfo = false
        showTimestamp = false
        maxMessageLength = 50
    }
}
