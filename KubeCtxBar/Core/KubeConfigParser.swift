import Foundation
import OSLog
import Yams

// MARK: - Errors

enum KubeConfigError: LocalizedError {
    case fileNotFound(URL)
    case readFailure(URL, Error)
    case parseFailure(URL, String)
    case noContextsDefined
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "Kubeconfig not found: \(url.path)"
        case .readFailure(let url, let error):
            return "Cannot read \(url.path): \(error.localizedDescription)"
        case .parseFailure(let url, let message):
            return "Parse error in \(url.path): \(message)"
        case .noContextsDefined:
            return "No contexts found in kubeconfig"
        }
    }
}

// MARK: - Parser

final class KubeConfigParser: Sendable {
    
    private static let logger = Logger(subsystem: "com.kubectxbar.app", category: "Parser")
    
    // MARK: - Public API
    
    func parse() throws -> KubeConfig {
        let paths = resolveKubeconfigPaths()
        
        if paths.isEmpty {
            Self.logger.warning("No kubeconfig files found")
            return .empty
        }
        
        var allContexts: [KubeContext] = []
        var seenNames: Set<String> = []
        var currentContext: String?
        var sourceFiles: [URL] = []
        
        for path in paths {
            Self.logger.debug("Parsing kubeconfig: \(path.path)")
            
            do {
                let (contexts, current) = try parseFile(at: path)
                
                for context in contexts {
                    if !seenNames.contains(context.name) {
                        allContexts.append(context)
                        seenNames.insert(context.name)
                    }
                }
                
                if currentContext == nil, let current {
                    currentContext = current
                }
                
                sourceFiles.append(path)
                
            } catch {
                Self.logger.error("Failed to parse \(path.path): \(error.localizedDescription)")
            }
        }
        
        return KubeConfig(
            contexts: allContexts,
            currentContext: currentContext,
            sourceFiles: sourceFiles
        )
    }
    
    // MARK: - Path Resolution
    
    func resolveKubeconfigPaths() -> [URL] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let defaultPath = homeDir.appendingPathComponent(".kube/config")
        
        if let kubeconfigEnv = ProcessInfo.processInfo.environment["KUBECONFIG"], !kubeconfigEnv.isEmpty {
            Self.logger.debug("KUBECONFIG env var: \(kubeconfigEnv)")
            
            let paths = kubeconfigEnv
                .split(separator: ":")
                .map { String($0) }
                .map { expandPath($0, homeDir: homeDir) }
                .filter { FileManager.default.fileExists(atPath: $0.path) }
            
            if !paths.isEmpty {
                return paths
            }
        }
        
        if FileManager.default.fileExists(atPath: defaultPath.path) {
            return [defaultPath]
        }
        
        return []
    }
    
    // MARK: - File Parsing
    
    private func parseFile(at url: URL) throws -> ([KubeContext], String?) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw KubeConfigError.fileNotFound(url)
        }
        
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw KubeConfigError.readFailure(url, error)
        }
        
        return try parseContent(content, sourceFile: url)
    }
    
    func parseContent(_ content: String, sourceFile: URL) throws -> ([KubeContext], String?) {
        guard let yaml = try? Yams.load(yaml: content) as? [String: Any] else {
            throw KubeConfigError.parseFailure(sourceFile, "Invalid YAML structure")
        }
        
        let currentContext = yaml["current-context"] as? String
        
        guard let contextsArray = yaml["contexts"] as? [[String: Any]] else {
            return ([], currentContext)
        }
        
        var contexts: [KubeContext] = []
        
        for contextDict in contextsArray {
            guard let name = contextDict["name"] as? String,
                  let contextData = contextDict["context"] as? [String: Any] else {
                continue
            }
            
            let clusterName = contextData["cluster"] as? String ?? ""
            let userName = contextData["user"] as? String ?? ""
            let namespace = contextData["namespace"] as? String
            
            let context = KubeContext(
                name: name,
                clusterName: clusterName,
                userName: userName,
                namespace: namespace,
                sourceFile: sourceFile
            )
            
            contexts.append(context)
        }
        
        return (contexts, currentContext)
    }
    
    // MARK: - Helpers
    
    private func expandPath(_ path: String, homeDir: URL) -> URL {
        if path.hasPrefix("~") {
            let relativePath = String(path.dropFirst(1))
            if relativePath.hasPrefix("/") {
                return homeDir.appendingPathComponent(String(relativePath.dropFirst(1)))
            } else {
                return homeDir.appendingPathComponent(relativePath)
            }
        }
        return URL(fileURLWithPath: path)
    }
}
