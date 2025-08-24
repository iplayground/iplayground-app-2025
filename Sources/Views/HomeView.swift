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
        store: store.scope(state: \.today, action: \.today)
      )
      .tabItem { Label(String(localized: "議程與活動", bundle: .module), systemImage: "calendar") }

      // Tab 2: Sponsors, Speakers, & Staff
      CommunityView(
        store: store.scope(state: \.community, action: \.community)
      )
      .tabItem { Label(String(localized: "社群", bundle: .module), systemImage: "person.3") }

      // Tab 3: Flitto (Live Translation)
      LiveTranslationView(
        store: store.scope(state: \.liveTranslation, action: \.liveTranslation)
      )
      .tabItem { Label(String(localized: "即時翻譯", bundle: .module), systemImage: "globe") }

      // Tab 4: My
      Text("我的", bundle: .module)
        .tabItem { Label(String(localized: "我的", bundle: .module), systemImage: "bookmark") }

      // Tab 5: About
      AboutView(
        store: store.scope(state: \.about, action: \.about)
      )
      .tabItem { Label(String(localized: "關於", bundle: .module), systemImage: "info.circle") }
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
