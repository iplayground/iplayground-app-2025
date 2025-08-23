import ComposableArchitecture
import CustomDump
import Dependencies
import Foundation
import IdentifiedCollections
import Models
import SessionData
import XCTest

@testable import Features

@MainActor
final class CommunityFeatureTests: XCTestCase {
  func testTapSpeaker() async {
    let speaker = createMockSpeaker()
    let store = TestStore(initialState: CommunityFeature.State()) {
      CommunityFeature()
    }

    await store.send(\.view.tapSpeaker, speaker) {
      $0.path.append(.speaker(SpeakerFeature.State(speaker: speaker)))
    }
  }

  func testPathNavigation() async {
    let speaker = createMockSpeaker()
    var initialState = CommunityFeature.State()
    initialState.path.append(.speaker(SpeakerFeature.State(speaker: speaker)))

    let store = TestStore(initialState: initialState) {
      CommunityFeature()
    }

    // Test path actions are handled without effects
    await store.send(\.path.popFrom, initialState.path.ids.first!) {
      $0.path.removeAll()
    }
  }

  // MARK: - Helper Methods

  private func createMockSpeaker(
    id: Int = 1,
    name: String = "Test Speaker",
    title: String? = "Test Title",
    intro: String = "Test introduction"
  ) -> Speaker {
    return Speaker(
      id: id,
      name: name,
      title: title,
      intro: intro,
      photo: nil,
      url: nil,
      fb: nil,
      github: nil,
      linkedin: nil,
      threads: nil,
      x: nil,
      ig: nil
    )
  }
}
