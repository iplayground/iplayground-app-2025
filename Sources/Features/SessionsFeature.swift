import ComposableArchitecture

package struct SessionsFeature: Reducer {
  package struct State: Equatable {
    package init() {}
  }

  package enum Action: Equatable {}

  package init() {}

  package var body: some Reducer<State, Action> {
    Reduce(core)
  }

  package func core(state: inout State, action: Action) -> Effect<Action> {

  }
}
