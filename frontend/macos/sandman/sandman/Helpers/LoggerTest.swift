import Foundation

/// A simple test class to demonstrate the logging functionality
class LoggerTest {
    private let logger = SandmanLogger.shared

    func runTest() {
        logger.info("Starting logger test")
        logger.debug("This is a debug message")
        logger.warning("This is a warning message")
        logger.error("This is an error message")
        logger.info("Logger test completed")

        // Test file logging
        if let logPath = logger.getLogFilePath() {
            logger.info("Log file location: \(logPath)")
        }
    }

    func testConcurrentLogging() {
        logger.info("Testing concurrent logging")

        DispatchQueue.global(qos: .background).async {
            for i in 1...5 {
                self.logger.info("Background log message \(i)")
                Thread.sleep(forTimeInterval: 0.1)
            }
        }

        DispatchQueue.global(qos: .utility).async {
            for i in 1...5 {
                self.logger.warning("Utility log message \(i)")
                Thread.sleep(forTimeInterval: 0.1)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.logger.info("Concurrent logging test completed")
        }
    }
}
