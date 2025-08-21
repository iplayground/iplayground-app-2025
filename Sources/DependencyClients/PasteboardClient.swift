import Dependencies
import DependenciesMacros

@DependencyClient
public struct PasteboardClient: Sendable {
  public var copy: @Sendable (_ string: String) -> Void
}

extension PasteboardClient: TestDependencyKey {
  public static let testValue = Self()
  public static let previewValue = Self()
}

extension DependencyValues {
  public var pasteboardClient: PasteboardClient {
    get { self[PasteboardClient.self] }
    set { self[PasteboardClient.self] = newValue }
  }
}
