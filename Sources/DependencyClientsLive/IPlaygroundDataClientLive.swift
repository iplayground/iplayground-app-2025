import Dependencies
import DependenciesMacros
import DependencyClients
import Foundation
import IdentifiedCollections
import SessionData

extension IPlaygroundDataClient: DependencyKey {
  public static let liveValue: IPlaygroundDataClient = {
    let dataLanguage = DataLanguage(localeIdentifier: Locale.preferredLanguages.first ?? "en")
    let client = SessionDataClient.live
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
