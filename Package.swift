// swift-tools-version: 6.0

import Foundation
import PackageDescription

let appName = "App"

// MARK: - Third party dependencies

let sessionData = SourceControlDependency(
  package: .package(
    url: "https://github.com/iplayground/SessionData",
    exact: "2025.1.2"
  ),
  productName: "SessionData"
)
let tca = SourceControlDependency(
  package: .package(
    url: "https://github.com/pointfreeco/swift-composable-architecture",
    exact: "1.22.0"
  ),
  productName: "ComposableArchitecture"
)
let swiftDependencies = Package.Dependency.package(
  url: "https://github.com/pointfreeco/swift-dependencies",
  from: "1.9.2"
)
let dependencies = SourceControlDependency(
  package: swiftDependencies,
  productName: "Dependencies"
)
let dependenciesMacros = SourceControlDependency(
  package: swiftDependencies,
  productName: "DependenciesMacros"
)
let flitto = SourceControlDependency(
  package: .package(
    url: "https://github.com/flitto/rtt_sdk",
    revision: "f1da670032cb52081285752b7a8c479118038393"
  ),
  productName: "rtt-sdk"
)

// MARK: - Modules. Ordered by dependency hierarchy.

let models = SingleTargetLibrary(
  name: "Models",
  dependencies: [
    sessionData.targetDependency
  ]
)
let dependencyClients = SingleTargetLibrary(
  name: "DependencyClients",
  dependencies: [
    dependencies.targetDependency,
    dependenciesMacros.targetDependency,
    models.targetDependency,
  ]
)
let features = SingleTargetLibrary(
  name: "Features",
  dependencies: [
    tca.targetDependency,
    models.targetDependency,
    dependencyClients.targetDependency,
  ]
)
let views = SingleTargetLibrary(
  name: "Views",
  dependencies: [
    tca.targetDependency,
    models.targetDependency,
    features.targetDependency,
  ]
)
let dependencyClientsLive = SingleTargetLibrary(
  name: "DependencyClientsLive",
  dependencies: [
    dependencies.targetDependency,
    dependenciesMacros.targetDependency,
    dependencyClients.targetDependency,
    flitto.targetDependency,
  ]
)
let publicApp = SingleTargetLibrary(
  name: "PublicApp",
  dependencies: [
    features.targetDependency,
    views.targetDependency,
    dependencyClientsLive.targetDependency,
  ]
)

// MARK: - Package manifest

let package = Package(
  name: appName + "Package",  // To avoid target name collision when importing to Xcode project
  defaultLocalization: "zh-Hant",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    dependencyClients.product,
    dependencyClientsLive.product,
    features.product,
    models.product,
    publicApp.product,
    views.product,
  ],
  dependencies: [
    tca.package,
    swiftDependencies,
    sessionData.package,
    flitto.package,
  ],
  targets: [
    models.target,
    models.testTarget,
    dependencyClients.target,
    dependencyClientsLive.target,
    features.target,
    features.testTarget,
    views.target,
    publicApp.target,
  ]
)

// MARK: - Helpers

/// Third party dependencies.
struct SourceControlDependency {
  var package: Package.Dependency
  var productName: String

  init(package: Package.Dependency, productName: String) {
    self.package = package
    self.productName = productName
  }

  var targetDependency: Target.Dependency {
    var packageName: String

    switch package.kind {
    case let .fileSystem(name: name, path: path):
      guard let name = name ?? URL(string: path)?.lastPathComponent else {
        fatalError("No package name found. Path: \(path)")
      }
      packageName = name
    case let .sourceControl(name: name, location: location, _):
      guard let name = name ?? URL(string: location)?.lastPathComponent else {
        fatalError("No package name found. Location: \(location)")
      }
      packageName = name
    default:
      fatalError("Unsupported dependency kind: \(package.kind)")
    }

    return .product(name: productName, package: packageName, moduleAliases: nil, condition: nil)
  }
}

/// Local modules.
struct SingleTargetLibrary {
  var name: String
  var dependencies: [Target.Dependency] = []

  var product: Product {
    .library(name: name, targets: [name])
  }

  var target: Target {
    .target(name: name, dependencies: dependencies)
  }

  var swift5Target: Target {
    .target(name: name, dependencies: dependencies, swiftSettings: [.swiftLanguageMode(.v5)])
  }

  var targetDependency: Target.Dependency {
    .target(name: name)
  }

  var testTarget: Target {
    .testTarget(name: name + "Tests", dependencies: [targetDependency])
  }
}
