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

  func testInitialState() async {
    let store = TestStore(initialState: CommunityFeature.State()) {
      CommunityFeature()
    }

    store.assert {
      $0.selectedTab = .sponsor
      $0.speakers = []
      $0.sponsorData = SponsorsData(sponsors: [], partner: [])
      $0.staffs = []
      $0.path = StackState<CommunityFeature.Path.State>()
    }
  }

  func testTaskAction() async {
    let mockSpeakers = IdentifiedArrayOf<Speaker>(uniqueElements: [
      createMockSpeaker(id: 1), createMockSpeaker(id: 2),
    ])
    let mockSponsors = SponsorsData(sponsors: [], partner: [])
    let mockStaffs = [createMockStaff()]

    let store = TestStore(initialState: CommunityFeature.State()) {
      CommunityFeature()
    } withDependencies: {
      $0.iPlaygroundDataClient.fetchSpeakers = {
        return mockSpeakers
      }
      $0.iPlaygroundDataClient.fetchSponsors = {
        return mockSponsors
      }
      $0.iPlaygroundDataClient.fetchStaffs = {
        return mockStaffs
      }
    }

    store.exhaustivity = .off

    await store.send(\.view.task)
    await store.receive(\.binding)
    await store.receive(\.binding)
    await store.receive(\.binding)

    // Verify final state has all the fetched data
    expectNoDifference(store.state.speakers, mockSpeakers)
    expectNoDifference(store.state.sponsorData.sponsors, mockSponsors.sponsors)
    expectNoDifference(store.state.sponsorData.partner, mockSponsors.partner)
    expectNoDifference(store.state.staffs, mockStaffs)
  }

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

  private func createMockStaff(
    name: String = "Test Staff",
    title: String? = "Test Title",
    photo: URL? = nil,
    url: URL? = nil
  ) -> Staff {
    return Staff(
      name: name,
      title: title,
      photo: photo,
      url: url
    )
  }
}
