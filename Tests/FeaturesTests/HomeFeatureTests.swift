import ComposableArchitecture
import DependencyClients
import Features
import Models
import XCTest

@MainActor
final class HomeFeatureTests: XCTestCase {
  func testTask() async throws {
    let mockSpeakers = IdentifiedArrayOf<Speaker>(uniqueElements: [
      createMockSpeaker(id: 1), createMockSpeaker(id: 2),
    ])
    let mockSponsors = SponsorsData(sponsors: [], partner: [])
    let mockStaffs = [createMockStaff()]

    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    } withDependencies: {
      $0.iPlaygroundDataClient.fetchSpeakers = { _ in
        return mockSpeakers
      }
      $0.iPlaygroundDataClient.fetchSponsors = { _ in
        return mockSponsors
      }
      $0.iPlaygroundDataClient.fetchStaffs = { _ in
        return mockStaffs
      }
      $0.iPlaygroundDataClient.fetchLinks = { _ in
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

    store.exhaustivity = .off  // skip changes of binding since the order is not deterministic
    await store.send(\.task)
    await store.receive(\.binding)
    await store.receive(\.binding)
    await store.receive(\.binding)
    await store.receive(\.binding)

    // Verify final state has all the fetched data
    expectNoDifference(store.state.speakers, mockSpeakers)
    expectNoDifference(store.state.sponsorData.sponsors, mockSponsors.sponsors)
    expectNoDifference(store.state.sponsorData.partner, mockSponsors.partner)
    expectNoDifference(store.state.staffs, mockStaffs)
    XCTAssert(!store.state.links.isEmpty)
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
