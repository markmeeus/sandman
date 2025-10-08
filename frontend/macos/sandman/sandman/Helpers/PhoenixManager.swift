import Foundation
import Network
import os
class PhoenixManager: ObservableObject {
    @Published var isRunning = false
    @Published var port: UInt16 = 7000
    private var process: Process?
    private let logger = SandmanLogger.shared

    init() {
        logger.info("PhoenixManager: init() called")
        startPhoenixAppIfRequested()
    }

    deinit {
        stopPhoenixApp()
    }

    func findAvailablePort() -> UInt16? {
        guard let listener = try? NWListener(using: .tcp, on: .any) else {
            print("Failed to create listener")
            return nil
        }

        let semaphore = DispatchSemaphore(value: 0)
        var port: UInt16?

        listener.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                if let p = listener.port?.rawValue {
                    port = UInt16(p)
                }
                semaphore.signal()
            case .failed(let err):
                print("Listener failed: \(err)")
                semaphore.signal()
            default:
                break
            }
        }

        listener.newConnectionHandler = { _ in } // required on some macOS versions
        listener.start(queue: DispatchQueue.global())

        // Wait up to 2 seconds for listener to become ready
        _ = semaphore.wait(timeout: .now() + 2)

        // Only cancel AFTER we've gotten the port
        listener.cancel()

        return port
    }

    func startPhoenixAppIfRequested() {
        #if START_PHOENIX
        logger.info("Starting Phoenix app...")
        startPhoenixApp()
        #else
        logger.info("START_PHOENIX not configured - Phoenix startup disabled")
        self.isRunning = true
        return
        #endif
    }

    func startPhoenixApp() {
        logger.info("startPhoenixApp")
        if let availablePort = findAvailablePort() {
            logger.warning("Using Port \(availablePort)")
            self.port = availablePort
        } else {
            logger.warning("Could not find open port")
        }
        guard !isRunning else {
            logger.warning("Already running, skipping")
            return
        }
        logger.info("startPhoenixApp not running")



        // Get the path to the Phoenix release within the app bundle
        /*guard let bundlePath = Bundle.main.resourcePath else {
            logger.error("Could not get bundle resource path")
            return
        }*/
        guard let phoenixReleasePath = Bundle.main.path(forResource: "phoenix_release", ofType: nil) else {
            logger.error("Could not find embedded Elixir release")
            return
        }

        let sandmanBinaryPath = "\(phoenixReleasePath)/bin/sandman"

        logger.info("Bundle path: \(sandmanBinaryPath)")
        logger.info("Phoenix release path: \(phoenixReleasePath)")
        logger.info("Sandman binary path: \(sandmanBinaryPath)")

        // Check if the Phoenix release exists
        guard FileManager.default.fileExists(atPath: sandmanBinaryPath) else {
            logger.error("Phoenix release not found at \(sandmanBinaryPath)")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: sandmanBinaryPath) {
                logger.error("Directory contents: \(contents)")
            }
            return
        }

        // Create and configure the process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sandmanBinaryPath)
        process.arguments = ["start"]

        // Set environment variables
        var environment = ProcessInfo.processInfo.environment
        environment["PORT"] = "\(self.port)"
        process.environment = environment

        logger.info("Environment PORT set to: \(self.port)")
        logger.info("Working directory: \(phoenixReleasePath)")

        // Set working directory to the Phoenix release directory
        process.currentDirectoryURL = URL(fileURLWithPath: phoenixReleasePath)

        // Set up output handling
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // Set up output reading
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                if let output = String(data: data, encoding: .utf8) {
                    let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
                    DispatchQueue.main.async {
                        self?.logger.info("Phoenix stdout: \(trimmedOutput)")
                    }
                }
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                if let output = String(data: data, encoding: .utf8) {
                    let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
                    DispatchQueue.main.async {
                        self?.logger.error("Phoenix stderr: \(trimmedOutput)")
                    }
                }
            }
        }

        // Handle process termination
        process.terminationHandler = { [weak self] process in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.logger.info("Phoenix app terminated with code \(process.terminationStatus)")
            }
        }

        do {
            try process.run()
            self.process = process
            self.isRunning = true
            logger.info("Phoenix app started successfully on port \(self.port)")
        } catch {
            logger.error("Failed to start Phoenix app: \(error.localizedDescription)")
        }
    }

    func stopPhoenixApp() {
        #if RELEASE
        guard let process = process, isRunning else { return }

        logger.info("Stopping Phoenix app...")
        process.terminate()

        // Wait a bit for graceful shutdown
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            if process.isRunning {
                process.terminate()
            }
        }
        #endif
    }

    func restartPhoenixApp() {
        logger.info("Restarting Phoenix app...")
        stopPhoenixApp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startPhoenixApp()
        }
    }
}
