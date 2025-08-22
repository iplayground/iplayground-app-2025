//
//  CommunityFeature.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/21.
//

import ComposableArchitecture
import DependencyClients
import Foundation
import Models

@Reducer
package struct CommunityFeature {
  @ObservableState
  package struct State: Equatable {
    package var path = StackState<Path.State>()

    package var selectedTab: Tab = .sponsor
    package var speakers: IdentifiedArrayOf<Speaker> = []
    package var sponsorData: SponsorsData = SponsorsData(sponsors: [], partner: [])
    package var staffs: [Staff] = []

    package init() {}
  }

  package enum Tab: String, CaseIterable, Hashable, Identifiable {
    case sponsor
    case speaker
    case staff

    package var id: Self { self }
  }

  package enum Action: Equatable, BindableAction, ComposableArchitecture.ViewAction {
    case binding(BindingAction<State>)
    case path(StackAction<Path.State, Path.Action>)
    case view(ViewAction)

    @CasePathable
    package enum ViewAction: Equatable {
      case task
      case tapSpeaker(Speaker)
    }
  }

  package init() {}

  package var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce(core)
      .forEach(\.path, action: \.path)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .binding:
      return .none

    case .path:
      return .none

    case let .view(viewAction):
      switch viewAction {
      case .task:
        return .run { send in
          await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
              @Dependency(\.iPlaygroundDataClient) var iPlaygroundDataClient
              let speakers = try await iPlaygroundDataClient.fetchSpeakers()
              await send(.binding(.set(\.speakers, speakers)))
            }
            group.addTask {
              @Dependency(\.iPlaygroundDataClient) var iPlaygroundDataClient
              let sponsorData = try await iPlaygroundDataClient.fetchSponsors()
              await send(.binding(.set(\.sponsorData, sponsorData)))
            }
            group.addTask {
              @Dependency(\.iPlaygroundDataClient) var iPlaygroundDataClient
              let staffs = try await iPlaygroundDataClient.fetchStaffs()
              await send(.binding(.set(\.staffs, staffs)))
            }
          }
        }

      case .tapSpeaker(let speaker):
        state.path.append(.speaker(.init(speaker: speaker)))
        return .none
      }
    }
  }
}
