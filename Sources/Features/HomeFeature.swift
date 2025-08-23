import ComposableArchitecture
import DependencyClients
import Foundation
import Models

@Reducer
package struct HomeFeature {
  @ObservableState
  package struct State: Equatable {
    @SharedReader(.day1Sessions) package var day1Sessions: [SessionWrapper] = []
    @SharedReader(.day2Sessions) package var day2Sessions: [SessionWrapper] = []
    @Shared(.speakers) package var speakers: IdentifiedArrayOf<Speaker> = []
    @Shared(.sponsorData) package var sponsorData: SponsorsData = SponsorsData(
      sponsors: [], partner: [])
    @Shared(.staffs) package var staffs: [Staff] = []
    @Shared(.links) package var links: [Link] = []

    package var today = TodayFeature.State()

    package init() {}
  }

  package enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case task
  }

  package init() {}

  package var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce(core)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .binding:
      return .none

    case .task:
      return .run { send in
        await withThrowingTaskGroup(of: Void.self) { group in
          group.addTask {
            @Dependency(\.iPlaygroundDataClient) var client
            let speakers = try await client.fetchSpeakers()
            await send(.binding(.set(\.speakers, speakers)))
          }
          group.addTask {
            @Dependency(\.iPlaygroundDataClient) var client
            let sponsorData = try await client.fetchSponsors()
            await send(.binding(.set(\.sponsorData, sponsorData)))
          }
          group.addTask {
            @Dependency(\.iPlaygroundDataClient) var client
            let staffs = try await client.fetchStaffs()
            await send(.binding(.set(\.staffs, staffs)))
          }
          group.addTask {
            @Dependency(\.iPlaygroundDataClient) var client
            let links = try await client.fetchLinks()
            await send(.binding(.set(\.links, links)))
          }
        }
      }
    }
  }
}
