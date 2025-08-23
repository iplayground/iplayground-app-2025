import Dependencies
import DependenciesMacros
import Foundation
import IdentifiedCollections
import SessionData

@DependencyClient
public struct IPlaygroundDataClient: Sendable {
  public var fetchSchedules:
    @Sendable (_ day: Int?, _ strategy: FetchStrategy) async throws -> [Session]
  public var fetchSpeakers:
    @Sendable (_ strategy: FetchStrategy) async throws -> IdentifiedArrayOf<Speaker>
  public var fetchSponsors: @Sendable (_ strategy: FetchStrategy) async throws -> SponsorsData
  public var fetchStaffs: @Sendable (_ strategy: FetchStrategy) async throws -> [Staff]
  public var fetchLinks: @Sendable (_ strategy: FetchStrategy) async throws -> [Link]
}

extension IPlaygroundDataClient: TestDependencyKey {
  public static let testValue = Self()
  public static let previewValue: IPlaygroundDataClient = {
    let dataLanguage = DataLanguage(localeIdentifier: Locale.preferredLanguages.first ?? "en")
    let client = SessionDataClient.live
    return IPlaygroundDataClient(
      fetchSchedules: { day, _ in
        try await client.fetchSchedules(day, dataLanguage, .localOnly)
      },
      fetchSpeakers: { _ in
        let speakers = try await client.fetchSpeakers(dataLanguage, .localOnly)
        return IdentifiedArrayOf(uniqueElements: speakers)
      },
      fetchSponsors: { _ in
        try await client.fetchSponsors(.localOnly)
      },
      fetchStaffs: { _ in
        try await client.fetchStaffs(.localOnly)
      },
      fetchLinks: { _ in
        try await client.fetchLinks(.localOnly)
      }
    )
  }()
}

extension DependencyValues {
  public var iPlaygroundDataClient: IPlaygroundDataClient {
    get { self[IPlaygroundDataClient.self] }
    set { self[IPlaygroundDataClient.self] = newValue }
  }
}
