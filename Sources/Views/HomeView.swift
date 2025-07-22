import ComposableArchitecture
import Features
import SwiftUI

struct HomeView: View {
  let store: StoreOf<HomeFeature>

  init(store: StoreOf<HomeFeature>) {
    self.store = store
  }

  var body: some View {
    Text("Home")
      .task {
        await store.send(.task).finish()
      }
  }
}

#Preview {
  HomeView(
    store: .init(
      initialState: HomeFeature.State(),
      reducer: { HomeFeature()
      })
  )
}
