import Dependencies
import DependenciesMacros
import Foundation
import IdentifiedCollections
import SessionData

@DependencyClient
public struct IPlaygroundDataClient: Sendable {
  public var fetchSchedules: @Sendable (_ day: Int?) async throws -> [Session]
  public var fetchSpeakers: @Sendable () async throws -> IdentifiedArrayOf<Speaker>
  public var fetchSponsors: @Sendable () async throws -> SponsorsData
  public var fetchStaffs: @Sendable () async throws -> [Staff]
  public var fetchLinks: @Sendable () async throws -> [Link]
}

extension IPlaygroundDataClient: TestDependencyKey {
  public static let testValue = Self()
  public static let previewValue: IPlaygroundDataClient = {
    let dataLanguage = DataLanguage(localeIdentifier: Locale.preferredLanguages.first ?? "en")
    let client = SessionDataClient.local
    return IPlaygroundDataClient(
      fetchSchedules: { day in
        try await client.fetchSchedules(day, dataLanguage)
      },
      fetchSpeakers: {
        let speakers = try await client.fetchSpeakers(dataLanguage)
        return IdentifiedArrayOf(uniqueElements: speakers)
      },
      fetchSponsors: {
        try await client.fetchSponsors()
      },
      fetchStaffs: {
        try await client.fetchStaffs()
      },
      fetchLinks: {
        try await client.fetchLinks()
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
