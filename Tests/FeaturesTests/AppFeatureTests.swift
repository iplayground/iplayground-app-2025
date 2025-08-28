import ComposableArchitecture
import Features
import XCTest

@MainActor
final class AppFeatureTests: XCTestCase {
  func testTask() async throws {
    let store = TestStore(
      initialState: AppFeature.State(),
      reducer: {
        AppFeature()
      }
    ) {
      $0.widgetClient.reloadTimelines = { widgetKind in
        expectNoDifference(widgetKind, "NowWidget")
      }
    }

    await store.send(\.task)
  }
}
