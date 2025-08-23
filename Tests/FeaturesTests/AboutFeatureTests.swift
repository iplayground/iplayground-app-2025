import ComposableArchitecture
import Dependencies
import DependencyClients
import Foundation
import Models
import XCTest

@testable import Features

@MainActor
final class AboutFeatureTests: XCTestCase {

  func testTaskAction() async {
    let store = TestStore(initialState: AboutFeature.State()) {
      AboutFeature()
    } withDependencies: {
      $0.iPlaygroundDataClient.fetchLinks = {
        [
          Link(
            id: "website", title: "官網", url: URL(string: "https://iplayground.io")!, icon: "globe",
            type: .primary),
          Link(
            id: "youtube", title: "YouTube", url: URL(string: "https://youtube.com/@iplayground")!,
            icon: "play.rectangle", type: .primary),
        ]
      }
    }

    await store.send(\.view.task)

    // Let's skip the exact expectation for concurrent actions
    await store.skipReceivedActions()
    XCTAssert(!store.state.links.isEmpty)
    XCTAssert(!store.state.appVersion.isEmpty)
  }

  func testLinksLoaded() async {
    let mockLinks = [
      Link(
        id: "website", title: "官網", url: URL(string: "https://iplayground.io")!, icon: "globe",
        type: .primary),
      Link(
        id: "youtube", title: "YouTube", url: URL(string: "https://youtube.com/@iplayground")!,
        icon: "play.rectangle", type: .primary),
    ]

    let store = TestStore(initialState: AboutFeature.State()) {
      AboutFeature()
    }

    await store.send(.linksLoaded(mockLinks)) {
      $0.links = mockLinks
    }
  }

  func testVersionInfoLoaded() async {
    let store = TestStore(initialState: AboutFeature.State()) {
      AboutFeature()
    }

    await store.send(.versionInfoLoaded(appVersion: "1.2.0", buildNumber: "42")) {
      $0.appVersion = "1.2.0"
      $0.buildNumber = "42"
    }
  }

  func testTapURL() async {
    let testURL = URL(string: "https://iplayground.io")!

    let store = TestStore(initialState: AboutFeature.State()) {
      AboutFeature()
    } withDependencies: {
      $0.openURL = OpenURLEffect { url in
        XCTAssertEqual(url, testURL)
        return true
      }
    }

    await store.send(\.view.tapURL, testURL)
  }

  func testTapCopyURL() async {
    let testURL = URL(string: "https://iplayground.io")!

    let store = TestStore(initialState: AboutFeature.State()) {
      AboutFeature()
    } withDependencies: {
      $0.pasteboardClient.copy = { text in
        XCTAssertEqual(text, testURL.absoluteString)
      }
    }

    await store.send(\.view.tapCopyURL, testURL)
  }

  func testBindingActions() async {
    let store = TestStore(initialState: AboutFeature.State()) {
      AboutFeature()
    }

    let newLinks = [
      Link(id: "test", title: "Test", url: URL(string: "https://example.com")!, type: .primary)
    ]

    await store.send(\.binding.links, newLinks) {
      $0.links = newLinks
    }
  }

  func testLinkTypeEnum() {
    XCTAssertEqual(LinkType.primary.rawValue, "primary")
    XCTAssertEqual(LinkType.social.rawValue, "social")
    XCTAssertEqual(LinkType.appInfo.rawValue, "appInfo")
    XCTAssertEqual(LinkType.allCases.count, 3)
  }
}
