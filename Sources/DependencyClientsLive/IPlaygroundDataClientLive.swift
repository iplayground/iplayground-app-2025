import Dependencies
import DependenciesMacros
import DependencyClients
import SessionData

extension IPlaygroundDataClient: DependencyKey {
  public static let liveValue = IPlaygroundDataClient(
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
