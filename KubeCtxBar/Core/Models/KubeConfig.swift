import Foundation

struct KubeConfig: Sendable {
    let contexts: [KubeContext]
    let currentContext: String?
    let sourceFiles: [URL]
    
    init(contexts: [KubeContext] = [], currentContext: String? = nil, sourceFiles: [URL] = []) {
        self.contexts = contexts
        self.currentContext = currentContext
        self.sourceFiles = sourceFiles
    }
    
    static let empty = KubeConfig()
}
