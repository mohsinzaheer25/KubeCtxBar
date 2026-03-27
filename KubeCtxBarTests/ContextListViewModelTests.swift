import XCTest
@testable import KubeCtxBar

@MainActor
final class ContextListViewModelTests: XCTestCase {
    
    // MARK: - Menu Bar Title Tests
    
    func testMenuBarTitleWithNoCurrentContext() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.currentContext = nil
        
        XCTAssertEqual(viewModel.menuBarTitle, "⎈")
    }
    
    func testMenuBarTitleWithShortContextName() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.currentContext = "minikube"
        
        XCTAssertEqual(viewModel.menuBarTitle, "minikube")
    }
    
    func testMenuBarTitleTruncatesLongContextName() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.currentContext = "arn:aws:eks:us-west-2:123456789:cluster/production-cluster"
        
        XCTAssertEqual(viewModel.menuBarTitle.count, 20)
        XCTAssertTrue(viewModel.menuBarTitle.hasSuffix("…"))
    }
    
    func testMenuBarTitleExactly20Characters() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.currentContext = "exactly-20-char-name"
        
        XCTAssertEqual(viewModel.menuBarTitle, "exactly-20-char-name")
        XCTAssertEqual(viewModel.menuBarTitle.count, 20)
    }
    
    // MARK: - Filtered Contexts Tests
    
    func testFilteredContextsEmptySearchReturnsAll() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.contexts = [
            mockContext(name: "production"),
            mockContext(name: "staging"),
            mockContext(name: "development")
        ]
        viewModel.searchText = ""
        
        XCTAssertEqual(viewModel.filteredContexts.count, 3)
    }
    
    func testFilteredContextsMatchesByName() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.contexts = [
            mockContext(name: "production"),
            mockContext(name: "staging"),
            mockContext(name: "development")
        ]
        viewModel.searchText = "prod"
        
        XCTAssertEqual(viewModel.filteredContexts.count, 1)
        XCTAssertEqual(viewModel.filteredContexts.first?.name, "production")
    }
    
    func testFilteredContextsMatchesByClusterName() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.contexts = [
            mockContext(name: "ctx1", clusterName: "prod-cluster"),
            mockContext(name: "ctx2", clusterName: "staging-cluster"),
            mockContext(name: "ctx3", clusterName: "dev-cluster")
        ]
        viewModel.searchText = "staging"
        
        XCTAssertEqual(viewModel.filteredContexts.count, 1)
        XCTAssertEqual(viewModel.filteredContexts.first?.name, "ctx2")
    }
    
    func testFilteredContextsIsCaseInsensitive() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.contexts = [
            mockContext(name: "Production"),
            mockContext(name: "STAGING"),
            mockContext(name: "development")
        ]
        viewModel.searchText = "PRODUCTION"
        
        XCTAssertEqual(viewModel.filteredContexts.count, 1)
        XCTAssertEqual(viewModel.filteredContexts.first?.name, "Production")
    }
    
    func testFilteredContextsNoMatchReturnsEmpty() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.contexts = [
            mockContext(name: "production"),
            mockContext(name: "staging")
        ]
        viewModel.searchText = "nonexistent"
        
        XCTAssertTrue(viewModel.filteredContexts.isEmpty)
    }
    
    // MARK: - Sorting Tests
    
    func testFilteredContextsSortsActiveFirst() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.contexts = [
            mockContext(name: "alpha"),
            mockContext(name: "beta"),
            mockContext(name: "gamma")
        ]
        viewModel.currentContext = "gamma"
        
        let sorted = viewModel.filteredContexts
        XCTAssertEqual(sorted.first?.name, "gamma")
    }
    
    func testFilteredContextsSortsAlphabeticallyAfterActive() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.contexts = [
            mockContext(name: "zebra"),
            mockContext(name: "alpha"),
            mockContext(name: "mango"),
            mockContext(name: "beta")
        ]
        viewModel.currentContext = "mango"
        
        let sorted = viewModel.filteredContexts
        XCTAssertEqual(sorted.map(\.name), ["mango", "alpha", "beta", "zebra"])
    }
    
    // MARK: - Has Contexts Tests
    
    func testHasContextsReturnsFalseWhenEmpty() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.contexts = []
        
        XCTAssertFalse(viewModel.hasContexts)
    }
    
    func testHasContextsReturnsTrueWhenNotEmpty() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.contexts = [mockContext(name: "test")]
        
        XCTAssertTrue(viewModel.hasContexts)
    }
    
    // MARK: - Error Handling Tests
    
    func testDismissErrorClearsErrorMessage() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        viewModel.errorMessage = "Test error"
        
        XCTAssertNotNil(viewModel.errorMessage)
        
        viewModel.dismissError()
        
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Initial State Tests
    
    func testInitialStateIsEmpty() {
        let viewModel = ContextListViewModel(parser: KubeConfigParser(), switcher: ContextSwitcher())
        
        XCTAssertTrue(viewModel.contexts.isEmpty)
        XCTAssertNil(viewModel.currentContext)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isSwitching)
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showSettings)
        XCTAssertNil(viewModel.recentlySwitchedContext)
    }
    
    // MARK: - Helpers
    
    private func mockContext(
        name: String,
        clusterName: String = "cluster",
        userName: String = "user",
        namespace: String? = nil
    ) -> KubeContext {
        KubeContext(
            name: name,
            clusterName: clusterName,
            userName: userName,
            namespace: namespace,
            sourceFile: URL(fileURLWithPath: "/tmp/config")
        )
    }
}
