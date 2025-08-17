import Dependencies
import DependenciesMacros
import SessionData

@DependencyClient
public struct IPlaygroundDataClient: Sendable {
  public var fetchSchedules: @Sendable (_ day: Int?) async throws -> [Session]
  public var fetchSpeakers: @Sendable () async throws -> [Speaker]
  public var fetchSponsors: @Sendable () async throws -> SponsorsData
  public var fetchStaffs: @Sendable () async throws -> [Staff]
}

extension IPlaygroundDataClient: TestDependencyKey {
  public static let testValue = Self()
  public static let previewValue = IPlaygroundDataClient(
    fetchSchedules: { day in
      let client = SessionDataClient.live
      return try await client.fetchSchedules(day)
    },
    fetchSpeakers: {
      let client = SessionDataClient.live
      return try await client.fetchSpeakers()
    },
    fetchSponsors: {
      let client = SessionDataClient.live
      return try await client.fetchSponsors()
    },
    fetchStaffs: {
      let client = SessionDataClient.live
      return try await client.fetchStaffs()
    }
  )
}

extension DependencyValues {
  public var iPlaygroundDataClient: IPlaygroundDataClient {
    get { self[IPlaygroundDataClient.self] }
    set { self[IPlaygroundDataClient.self] = newValue }
  }
}
