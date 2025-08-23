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
      fetchSchedules: { day, strategy in
        try await client.fetchSchedules(day, dataLanguage, strategy)
      },
      fetchSpeakers: { strategy in
        let speakers = try await client.fetchSpeakers(dataLanguage, strategy)
        return IdentifiedArrayOf(uniqueElements: speakers)
      },
      fetchSponsors: { strategy in
        try await client.fetchSponsors(strategy)
      },
      fetchStaffs: { strategy in
        try await client.fetchStaffs(strategy)
      },
      fetchLinks: { strategy in
        try await client.fetchLinks(strategy)
      }
    )
  }()
}
