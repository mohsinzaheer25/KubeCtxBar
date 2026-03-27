import XCTest
@testable import KubeCtxBar

final class KubeConfigParserTests: XCTestCase {
    
    private var parser: KubeConfigParser!
    
    override func setUp() {
        super.setUp()
        parser = KubeConfigParser()
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    // MARK: - Valid Config Tests
    
    func testParseValidConfigWithSingleContext() throws {
        let yaml = """
        apiVersion: v1
        kind: Config
        current-context: minikube
        contexts:
        - name: minikube
          context:
            cluster: minikube
            user: minikube
        """
        
        let tempURL = URL(fileURLWithPath: "/tmp/test-kubeconfig")
        let (contexts, currentContext) = try parser.parseContent(yaml, sourceFile: tempURL)
        
        XCTAssertEqual(contexts.count, 1)
        XCTAssertEqual(contexts.first?.name, "minikube")
        XCTAssertEqual(contexts.first?.clusterName, "minikube")
        XCTAssertEqual(contexts.first?.userName, "minikube")
        XCTAssertNil(contexts.first?.namespace)
        XCTAssertEqual(currentContext, "minikube")
    }
    
    func testParseValidConfigWithMultipleContexts() throws {
        let yaml = """
        apiVersion: v1
        kind: Config
        current-context: production
        contexts:
        - name: development
          context:
            cluster: dev-cluster
            user: dev-user
            namespace: dev-ns
        - name: staging
          context:
            cluster: staging-cluster
            user: staging-user
        - name: production
          context:
            cluster: prod-cluster
            user: prod-user
            namespace: production
        """
        
        let tempURL = URL(fileURLWithPath: "/tmp/test-kubeconfig")
        let (contexts, currentContext) = try parser.parseContent(yaml, sourceFile: tempURL)
        
        XCTAssertEqual(contexts.count, 3)
        XCTAssertEqual(currentContext, "production")
        
        let devContext = contexts.first { $0.name == "development" }
        XCTAssertNotNil(devContext)
        XCTAssertEqual(devContext?.namespace, "dev-ns")
        
        let stagingContext = contexts.first { $0.name == "staging" }
        XCTAssertNotNil(stagingContext)
        XCTAssertNil(stagingContext?.namespace)
        
        let prodContext = contexts.first { $0.name == "production" }
        XCTAssertNotNil(prodContext)
        XCTAssertEqual(prodContext?.namespace, "production")
    }
    
    func testParseConfigWithNoCurrentContext() throws {
        let yaml = """
        apiVersion: v1
        kind: Config
        contexts:
        - name: test-context
          context:
            cluster: test-cluster
            user: test-user
        """
        
        let tempURL = URL(fileURLWithPath: "/tmp/test-kubeconfig")
        let (contexts, currentContext) = try parser.parseContent(yaml, sourceFile: tempURL)
        
        XCTAssertEqual(contexts.count, 1)
        XCTAssertNil(currentContext)
    }
    
    func testParseConfigWithEmptyNamespace() throws {
        let yaml = """
        apiVersion: v1
        kind: Config
        current-context: test
        contexts:
        - name: test
          context:
            cluster: test-cluster
            user: test-user
            namespace: ""
        """
        
        let tempURL = URL(fileURLWithPath: "/tmp/test-kubeconfig")
        let (contexts, _) = try parser.parseContent(yaml, sourceFile: tempURL)
        
        XCTAssertEqual(contexts.count, 1)
        XCTAssertEqual(contexts.first?.namespace, "")
    }
    
    // MARK: - Edge Cases
    
    func testParseConfigWithNoContexts() throws {
        let yaml = """
        apiVersion: v1
        kind: Config
        current-context: none
        """
        
        let tempURL = URL(fileURLWithPath: "/tmp/test-kubeconfig")
        let (contexts, currentContext) = try parser.parseContent(yaml, sourceFile: tempURL)
        
        XCTAssertTrue(contexts.isEmpty)
        XCTAssertEqual(currentContext, "none")
    }
    
    func testParseConfigWithEmptyContextsArray() throws {
        let yaml = """
        apiVersion: v1
        kind: Config
        contexts: []
        """
        
        let tempURL = URL(fileURLWithPath: "/tmp/test-kubeconfig")
        let (contexts, currentContext) = try parser.parseContent(yaml, sourceFile: tempURL)
        
        XCTAssertTrue(contexts.isEmpty)
        XCTAssertNil(currentContext)
    }
    
    func testParseConfigSkipsInvalidContextEntries() throws {
        let yaml = """
        apiVersion: v1
        kind: Config
        current-context: valid
        contexts:
        - name: valid
          context:
            cluster: valid-cluster
            user: valid-user
        - invalid: entry
        - name: also-valid
          context:
            cluster: cluster
            user: user
        """
        
        let tempURL = URL(fileURLWithPath: "/tmp/test-kubeconfig")
        let (contexts, _) = try parser.parseContent(yaml, sourceFile: tempURL)
        
        XCTAssertEqual(contexts.count, 2)
        XCTAssertTrue(contexts.contains { $0.name == "valid" })
        XCTAssertTrue(contexts.contains { $0.name == "also-valid" })
    }
    
    // MARK: - Error Cases
    
    func testParseInvalidYAML() {
        let yaml = """
        this is not: valid: yaml:
        - missing proper structure
        """
        
        let tempURL = URL(fileURLWithPath: "/tmp/test-kubeconfig")
        
        XCTAssertThrowsError(try parser.parseContent(yaml, sourceFile: tempURL)) { error in
            XCTAssertTrue(error is KubeConfigError)
        }
    }
    
    func testParseEmptyContent() {
        let yaml = ""
        let tempURL = URL(fileURLWithPath: "/tmp/test-kubeconfig")
        
        XCTAssertThrowsError(try parser.parseContent(yaml, sourceFile: tempURL))
    }
    
    // MARK: - Context Model Tests
    
    func testContextIdentifiableById() {
        let context1 = KubeContext(
            name: "test",
            clusterName: "cluster",
            userName: "user",
            namespace: nil,
            sourceFile: URL(fileURLWithPath: "/tmp/config")
        )
        
        let context2 = KubeContext(
            name: "test",
            clusterName: "different-cluster",
            userName: "different-user",
            namespace: nil,
            sourceFile: URL(fileURLWithPath: "/tmp/other-config")
        )
        
        XCTAssertEqual(context1.id, context2.id)
        XCTAssertEqual(context1.id, "test")
    }
    
    func testContextHashable() {
        let context1 = KubeContext(
            name: "test",
            clusterName: "cluster",
            userName: "user",
            namespace: nil,
            sourceFile: URL(fileURLWithPath: "/tmp/config")
        )
        
        let context2 = KubeContext(
            name: "test",
            clusterName: "cluster",
            userName: "user",
            namespace: nil,
            sourceFile: URL(fileURLWithPath: "/tmp/config")
        )
        
        XCTAssertEqual(context1, context2)
        XCTAssertEqual(context1.hashValue, context2.hashValue)
    }
    
    // MARK: - Real World Config Examples
    
    func testParseEKSStyleContext() throws {
        let yaml = """
        apiVersion: v1
        kind: Config
        current-context: arn:aws:eks:us-west-2:123456789:cluster/my-cluster
        contexts:
        - name: arn:aws:eks:us-west-2:123456789:cluster/my-cluster
          context:
            cluster: arn:aws:eks:us-west-2:123456789:cluster/my-cluster
            user: arn:aws:eks:us-west-2:123456789:cluster/my-cluster
            namespace: kube-system
        """
        
        let tempURL = URL(fileURLWithPath: "/tmp/test-kubeconfig")
        let (contexts, currentContext) = try parser.parseContent(yaml, sourceFile: tempURL)
        
        XCTAssertEqual(contexts.count, 1)
        XCTAssertEqual(currentContext, "arn:aws:eks:us-west-2:123456789:cluster/my-cluster")
        XCTAssertEqual(contexts.first?.namespace, "kube-system")
    }
    
    func testParseGKEStyleContext() throws {
        let yaml = """
        apiVersion: v1
        kind: Config
        current-context: gke_my-project_us-central1_my-cluster
        contexts:
        - name: gke_my-project_us-central1_my-cluster
          context:
            cluster: gke_my-project_us-central1_my-cluster
            user: gke_my-project_us-central1_my-cluster
        """
        
        let tempURL = URL(fileURLWithPath: "/tmp/test-kubeconfig")
        let (contexts, currentContext) = try parser.parseContent(yaml, sourceFile: tempURL)
        
        XCTAssertEqual(contexts.count, 1)
        XCTAssertEqual(currentContext, "gke_my-project_us-central1_my-cluster")
    }
}
