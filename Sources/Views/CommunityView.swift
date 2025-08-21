//
//  CommunityView.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/21.
//

import ComposableArchitecture
import Features
import SwiftUI

@ViewAction(for: CommunityFeature.self)
struct CommunityView: View {
  @Bindable var store: StoreOf<CommunityFeature>

  var body: some View {
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path),
      root: { rootView },
      destination: { store in
        switch store.case {
        case let .speaker(store):
          SpeakerView(store: store)
        }
      }
    )
  }

  @ViewBuilder
  private var rootView: some View {
    VStack {
      tabs

      switch store.selectedTab {
      case .sponsor:
        sponsorsView
      case .speaker:
        speakersView
      case .staff:
        staffsView
      }
    }
    .navigationTitle("社群")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      send(.task)
    }
  }

  @ViewBuilder
  private var tabs: some View {
    Picker("", selection: $store.selectedTab) {
      ForEach(CommunityFeature.Tab.allCases) { tab in
        Text(tab.localizedStringKey)
          .tag(tab)
      }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
    .padding(.bottom, 8)
  }

  @ViewBuilder
  private var sponsorsView: some View {
    Color.clear.overlay {
      Text("Sponsors")
    }
  }

  enum NavigationIndicator {
    case link(URL)
    case chevron
    case empty
  }

  @ViewBuilder
  private func personCell(
    name: String,
    title: String?,
    photoURL: URL?,
    navigationIndicator: NavigationIndicator
  ) -> some View {
    HStack {
      let avatarSize: CGFloat = 40
      if let photoURL = photoURL {
        // FIXME: Cache image
        AsyncImage(url: photoURL) { image in
          image
            .resizable()
            .scaledToFill()
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())
        } placeholder: {
          Image(systemName: "person.fill")
            .frame(width: avatarSize, height: avatarSize)
        }
      } else {
        Image(systemName: "person.fill")
          .frame(width: avatarSize, height: avatarSize)
      }

      VStack(alignment: .leading) {
        Text(name)
          .font(.headline)
        if let title = title, title.isEmpty == false {
          Text(title)
            .font(.subheadline)
        }
      }
      Spacer()
      switch navigationIndicator {
      case let .link(url):
        Link(destination: url, label: { Image(systemName: "arrow.up.right.square") })
      case .chevron:
        Image(systemName: "chevron.right")
      case .empty:
        EmptyView()
      }
    }
  }

  @ViewBuilder
  private var speakersView: some View {
    List {
      ForEach(store.state.speakers) { speaker in
        Button {
          send(.tapSpeaker(speaker))
        } label: {
          personCell(
            name: speaker.name,
            title: speaker.title,
            photoURL: speaker.photo,
            navigationIndicator: .chevron
          )
        }
      }
    }
    .listStyle(.plain)
    .contentMargins(.vertical, -4, for: .scrollIndicators)
  }

  @ViewBuilder
  private var staffsView: some View {
    List {
      ForEach(store.state.staffs, id: \.name) { staff in
        personCell(
          name: staff.name,
          title: staff.title,
          photoURL: staff.photo,
          navigationIndicator: staff.url.map { .link($0) } ?? .empty
        )
      }
    }
    .listStyle(.plain)
    .contentMargins(.vertical, -4, for: .scrollIndicators)
  }
}

extension CommunityFeature.Tab {
  var localizedStringKey: LocalizedStringKey {
    switch self {
    case .speaker:
      return "講者"
    case .sponsor:
      return "贊助商"
    case .staff:
      return "工作人員"
    }
  }
}

#Preview {
  CommunityView(store: .init(initialState: .init(), reducer: { CommunityFeature() }))
}
