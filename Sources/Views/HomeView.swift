import ComposableArchitecture
import Features
import SwiftUI

struct HomeView: View {
  let store: StoreOf<HomeFeature>

  init(store: StoreOf<HomeFeature>) {
    self.store = store
  }

  var body: some View {
    TabView {
      // Tab 1: Today
      TodayView(
        store: .init(
          initialState: TodayFeature.State(),
          reducer: { TodayFeature() }
        )
      )
      .tabItem { Label("Today", systemImage: "calendar") }

      // Tab 2: Sponsors, Speakers, & Staff
      Text("Sponsors")
        .tabItem { Label("Community", systemImage: "person.3") }

      // Tab 3: Flitto (Live Translation)
      Text("Flitto")
        .tabItem { Label("Flitto", systemImage: "globe") }

      // Tab 4: My
      Text("My")
        .tabItem { Label("My", systemImage: "bookmark") }

      // Tab 5: About
      Text("About")
        .tabItem { Label("About", systemImage: "info.circle") }
    }
    .task {
      await store.send(.task).finish()
    }
  }
}

#Preview("活動前") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2025, month: 8, day: 29, hour: 9, minute: 0))!
      return date
    }()
  }
  HomeView(
    store: .init(
      initialState: HomeFeature.State(),
      reducer: { HomeFeature() }
    )
  )
}

#Preview("活動中 - Day 1") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2025, month: 8, day: 30, hour: 9, minute: 35))!
      return date
    }()
  }
  HomeView(
    store: .init(
      initialState: HomeFeature.State(),
      reducer: { HomeFeature() }
    )
  )
}

#Preview("活動中 - Day 2") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2025, month: 8, day: 31, hour: 17, minute: 10))!
      return date
    }()
  }
  HomeView(
    store: .init(
      initialState: HomeFeature.State(),
      reducer: { HomeFeature() }
    )
  )
}

#Preview("活動結束後") {
  let _ = prepareDependencies {
    $0.date.now = {
      let date = Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2025, month: 8, day: 31, hour: 18, minute: 0))!
      return date
    }()
  }
  HomeView(
    store: .init(
      initialState: HomeFeature.State(),
      reducer: { HomeFeature() }
    )
  )
}
