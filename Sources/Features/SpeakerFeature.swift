//
//  SpeakerFeature.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/21.
//

import ComposableArchitecture
import Foundation
import Models

@Reducer
package struct SpeakerFeature {
  @ObservableState
  package struct State: Equatable {
    package var speaker: Speaker

    package init(speaker: Speaker) {
      self.speaker = speaker
    }
  }

  @CasePathable
  package enum Action: Equatable, BindableAction, ComposableArchitecture.ViewAction {
    case view(ViewAction)
    case binding(BindingAction<State>)

    @CasePathable
    package enum ViewAction: Equatable {
      case task
      case tapURL(URL)
      case tapCopyURL(URL)
    }
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

    case let .view(viewAction):
      switch viewAction {
      case .task:
        return .none
      case let .tapURL(url):
        return .run { _ in
          @Dependency(\.openURL) var openURL
          await openURL(url)
        }
      case let .tapCopyURL(url):
        return .run { _ in
          @Dependency(\.pasteboardClient) var pasteboardClient
          pasteboardClient.copy(url.absoluteString)
        }
      }
    }
  }
}
