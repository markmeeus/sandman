import Foundation
import os

/// A comprehensive logging utility that supports console output, OS logging, and file logging
class SandmanLogger {
    static let shared = SandmanLogger()

    private let osLogger: Logger
    private let fileManager = FileManager.default
    private let logQueue = DispatchQueue(label: "com.sandman.logger", qos: .utility)
    private var logFileHandle: FileHandle?

    // Configuration
    private let subsystem = "be.codestation.sandman"
    private let category = "client"
    private let logFileName = "sandman.log"

    private init() {
        self.osLogger = Logger(subsystem: subsystem, category: category)
        setupLogFile()
    }

    deinit {
        closeLogFile()
    }

    // MARK: - Public Logging Methods

    /// Log an info message
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }

    /// Log an error message
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }

    /// Log a warning message
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }

    /// Log a debug message
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }

    // MARK: - Private Methods

    private enum LogLevel: String, CaseIterable {
        case info = "INFO"
        case error = "ERROR"
        case warning = "WARNING"
        case debug = "DEBUG"

        var emoji: String {
            switch self {
            case .info: return "ℹ️"
            case .error: return "❌"
            case .warning: return "⚠️"
            case .debug: return "🔍"
            }
        }
    }

    private func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        let logMessage = "[\(timestamp)] \(level.emoji) [\(level.rawValue)] [\(fileName):\(line)] \(function): \(message)"

        logQueue.async { [weak self] in
            self?.writeToConsole(logMessage)
            self?.writeToOSLog(level: level, message: message, fileName: fileName, function: function, line: line)
            self?.writeToFile(logMessage)
        }
    }

    private func writeToConsole(_ message: String) {
        print(message)
    }

    private func writeToOSLog(level: LogLevel, message: String, fileName: String, function: String, line: Int) {
        let osMessage = "[\(fileName):\(line)] \(function): \(message)"

        switch level {
        case .info:
            osLogger.info("\(osMessage, privacy: .public)")
        case .error:
            osLogger.error("\(osMessage, privacy: .public)")
        case .warning:
            osLogger.warning("\(osMessage, privacy: .public)")
        case .debug:
            osLogger.debug("\(osMessage, privacy: .public)")
        }
    }

    private func writeToFile(_ message: String) {
        guard let fileHandle = logFileHandle else { return }

        let data = (message + "\n").data(using: .utf8)
        fileHandle.write(data ?? Data())
    }

    // MARK: - File Management

    private func setupLogFile() {
        logQueue.async { [weak self] in
            guard let self = self else { return }

            // Get the application support directory
            let appSupportURL = self.fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            let sandmanURL = appSupportURL?.appendingPathComponent("Sandman")

            // Create Sandman directory if it doesn't exist
            if let sandmanURL = sandmanURL {
                try? self.fileManager.createDirectory(at: sandmanURL, withIntermediateDirectories: true)

                let logFileURL = sandmanURL.appendingPathComponent(self.logFileName)

                // Create log file if it doesn't exist
                if !self.fileManager.fileExists(atPath: logFileURL.path) {
                    self.fileManager.createFile(atPath: logFileURL.path, contents: nil)
                }

                // Open file handle for writing
                do {
                    self.logFileHandle = try FileHandle(forWritingTo: logFileURL)
                    self.logFileHandle?.seekToEndOfFile()

                    // Log the file location
                    let fileMessage = "Log file created at: \(logFileURL.path)"
                    DispatchQueue.main.async {
                        print("📝 SandmanLogger: \(fileMessage)")
                    }
                } catch {
                    print("❌ SandmanLogger: Failed to open log file: \(error)")
                }
            }
        }
    }

    private func closeLogFile() {
        logFileHandle?.closeFile()
        logFileHandle = nil
    }

    /// Get the path to the current log file
    func getLogFilePath() -> String? {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let sandmanURL = appSupportURL?.appendingPathComponent("Sandman")
        let logFileURL = sandmanURL?.appendingPathComponent(logFileName)
        return logFileURL?.path
    }

    /// Clear the log file
    func clearLogFile() {
        logQueue.async { [weak self] in
            guard let self = self else { return }

            self.closeLogFile()

            if let logFilePath = self.getLogFilePath() {
                try? "".write(toFile: logFilePath, atomically: true, encoding: .utf8)
                self.setupLogFile()
            }
        }
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
