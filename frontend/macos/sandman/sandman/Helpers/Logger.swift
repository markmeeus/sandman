import Foundation
import Puppy

/// A logging utility using Puppy for console and file logging with rotation
class SandmanLogger {
    static let shared = SandmanLogger()

    private let puppy: Puppy
    private let consoleLogger: ConsoleLogger
    private let fileLogger: Loggerable

    private init() {
        // Create console logger
        self.consoleLogger = ConsoleLogger("be.codestation.sandman.console", logLevel: .info)

        // Configure file rotation
        let rotationConfig = RotationConfig(
            suffixExtension: .numbering,
            maxFileSize: 1 * 1024 * 1024, // 1MB
            maxArchivedFilesCount: 4
        )

        // Get log file path
        let logFileURL = Self.getLogFileURL()

        // Create file rotation logger
        do {
            self.fileLogger = try FileRotationLogger(
                "be.codestation.sandman.file",
                logLevel: .info,
                fileURL: logFileURL,
                rotationConfig: rotationConfig
            )
        } catch {
            print("Failed to create file rotation logger: \(error)")
            print("Falling back to regular file logger")
            // Fallback to regular file logger if rotation fails
            do {
                self.fileLogger = try FileLogger(
                    "be.codestation.sandman.file",
                    logLevel: .info,
                    fileURL: logFileURL
                )
            } catch {
                print("Failed to create file logger: \(error)")
                print("Using console logger only")
                // Last resort: use console logger only
                self.fileLogger = ConsoleLogger("be.codestation.sandman.file.fallback", logLevel: .info)
            }
        }

        // Initialize Puppy with both loggers
        self.puppy = Puppy(loggers: [consoleLogger, fileLogger])

        // Log initialization
        self.info("SandmanLogger initialized with Puppy")
        self.info("Log file location: \(logFileURL.path)")
    }

    deinit {
        _ = puppy.flush()
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

    private func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let formattedMessage = "[\(fileName):\(line)] \(function): \(message)"

        switch level {
        case .verbose:
            puppy.verbose(formattedMessage)
        case .info:
            puppy.info(formattedMessage)
        case .error:
            puppy.error(formattedMessage)
        case .warning:
            puppy.warning(formattedMessage)
        case .debug:
            puppy.debug(formattedMessage)
        case .trace:
            puppy.trace(formattedMessage)
        case .critical:
            puppy.critical(formattedMessage)
        case .notice:
            puppy.notice(formattedMessage)
        }
    }

    private static func getLogFileURL() -> URL {
        // Get the application support directory
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let sandmanURL = appSupportURL.appendingPathComponent("Sandman")

        // Create Sandman directory if it doesn't exist
        try? FileManager.default.createDirectory(at: sandmanURL, withIntermediateDirectories: true)

        return sandmanURL.appendingPathComponent("sandman.log")
    }

    /// Get the path to the current log file
    func getLogFilePath() -> String {
        return Self.getLogFileURL().path
    }

    /// Flush all pending log messages
    func flush() {
        _ = puppy.flush()
    }

    /// Clear the log file (this will clear the current active log file)
    func clearLogFile() {
        let logFileURL = Self.getLogFileURL()
        try? "".write(toFile: logFileURL.path, atomically: true, encoding: .utf8)
        info("Log file cleared")
    }
}
