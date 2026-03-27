import Foundation

struct KubeContext: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let clusterName: String
    let userName: String
    let namespace: String?
    let sourceFile: URL
    
    init(name: String, clusterName: String, userName: String, namespace: String?, sourceFile: URL) {
        self.id = name
        self.name = name
        self.clusterName = clusterName
        self.userName = userName
        self.namespace = namespace
        self.sourceFile = sourceFile
    }
    
    // MARK: - Cloud Provider Detection
    
    var cloudProvider: CloudProvider {
        // AWS EKS: arn:aws:eks:region:account:cluster/name
        if name.hasPrefix("arn:aws:eks:") {
            return .eks
        }
        // Google GKE: gke_project_region_cluster
        if name.hasPrefix("gke_") {
            return .gke
        }
        // DigitalOcean: do-region-cluster
        if name.hasPrefix("do-") && name.split(separator: "-").count >= 3 {
            return .digitalocean
        }
        // Minikube
        if name == "minikube" || name.hasPrefix("minikube-") {
            return .minikube
        }
        // Kind: kind-cluster
        if name.hasPrefix("kind-") {
            return .kind
        }
        // k3d: k3d-cluster
        if name.hasPrefix("k3d-") {
            return .k3d
        }
        // Rancher Desktop
        if name == "rancher-desktop" {
            return .rancher
        }
        // Docker Desktop
        if name == "docker-desktop" || name == "docker-for-desktop" {
            return .docker
        }
        // Default/other (including AKS which uses plain names)
        return .other
    }
    
    /// Returns a user-friendly display name extracted from the full context name.
    var displayName: String {
        switch cloudProvider {
        case .eks:
            // arn:aws:eks:us-east-1:123456:cluster/my-cluster → my-cluster
            if let clusterPart = name.split(separator: "/").last {
                return String(clusterPart)
            }
        case .gke:
            // gke_project_region_cluster → cluster
            let parts = name.split(separator: "_")
            if parts.count >= 4 {
                return parts.dropFirst(3).joined(separator: "_")
            }
        case .digitalocean:
            // do-nyc1-my-cluster → my-cluster
            let parts = name.split(separator: "-")
            if parts.count >= 3 {
                return parts.dropFirst(2).joined(separator: "-")
            }
        case .kind:
            // kind-my-cluster → my-cluster
            return String(name.dropFirst(5))
        case .k3d:
            // k3d-my-cluster → my-cluster
            return String(name.dropFirst(4))
        case .minikube, .rancher, .docker, .other:
            break
        }
        return name
    }
    
    /// Returns a shorter display name for the cluster field.
    var displayClusterName: String {
        switch cloudProvider {
        case .eks:
            // Extract from ARN if present
            if clusterName.hasPrefix("arn:aws:eks:") {
                if let clusterPart = clusterName.split(separator: "/").last {
                    return String(clusterPart)
                }
            }
        case .gke:
            // Extract from gke_project_region_cluster format
            if clusterName.hasPrefix("gke_") {
                let parts = clusterName.split(separator: "_")
                if parts.count >= 4 {
                    return parts.dropFirst(3).joined(separator: "_")
                }
            }
        default:
            break
        }
        return clusterName
    }
    
    /// Returns a badge/label for the cloud provider
    var providerBadge: String? {
        switch cloudProvider {
        case .eks: return "EKS"
        case .gke: return "GKE"
        case .digitalocean: return "DO"
        case .minikube: return "Local"
        case .kind: return "Kind"
        case .k3d: return "k3d"
        case .rancher: return "Rancher"
        case .docker: return "Docker"
        case .other: return nil
        }
    }
}

// MARK: - Cloud Provider

enum CloudProvider: String, Sendable {
    case eks           // AWS EKS
    case gke           // Google GKE
    case digitalocean  // DigitalOcean Kubernetes
    case minikube      // Minikube
    case kind          // Kind (Kubernetes in Docker)
    case k3d           // k3d
    case rancher       // Rancher Desktop
    case docker        // Docker Desktop
    case other         // Unknown/Other (including AKS)
}
