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
    VStack(spacing: .zero) {
      tabs
        .background {
          store.selectedTab.backgroundColor
        }

      switch store.selectedTab {
      case .sponsor:
        sponsorsView
      case .speaker:
        speakersView
      case .staff:
        staffsView
      }
    }
    .navigationTitle(String(localized: "社群", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(store.selectedTab.backgroundColor, for: .navigationBar)
    .task {
      send(.task)
    }
  }

  @ViewBuilder
  private var tabs: some View {
    Picker("", selection: $store.selectedTab) {
      ForEach(CommunityFeature.Tab.allCases) { tab in
        Text(tab.localizedStringKey, bundle: .module)
          .tag(tab)
      }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
    .padding(.vertical, 8)
  }

  @ViewBuilder
  private var sponsorsView: some View {
    List {
      Section(String(localized: "鑽石級贊助商", bundle: .module)) {
        ForEach(
          store.sponsorData.sponsors.first(where: { $0.title == "鑽石級" })?.items ?? [], id: \.name
        ) { sponsor in
          sponsorCell(name: sponsor.name, logoURL: sponsor.picture, url: sponsor.link)
        }
      }

      Section(String(localized: "白銀級贊助商", bundle: .module)) {
        ForEach(
          store.sponsorData.sponsors.first(where: { $0.title == "白銀級" })?.items ?? [], id: \.name
        ) { sponsor in
          sponsorCell(name: sponsor.name, logoURL: sponsor.picture, url: sponsor.link)
        }
      }

      Section(String(localized: "青銅級贊助商", bundle: .module)) {
        ForEach(
          store.sponsorData.sponsors.first(where: { $0.title == "青銅級" })?.items ?? [], id: \.name
        ) { sponsor in
          sponsorCell(name: sponsor.name, logoURL: sponsor.picture, url: sponsor.link)
        }
      }

      Section(String(localized: "特別贊助", bundle: .module)) {
        ForEach(
          store.sponsorData.sponsors.first(where: { $0.title == "特別贊助" })?.items ?? [], id: \.name
        ) { sponsor in
          sponsorCell(name: sponsor.name, logoURL: sponsor.picture, url: sponsor.link)
        }
      }

      Section(String(localized: "個人贊助", bundle: .module)) {
        ForEach(store.sponsorData.personal, id: \.name) { sponsor in
          personCell(
            name: sponsor.name,
            title: nil,
            photoURL: sponsor.icon,
            navigationIndicator: sponsor.link.map { .link($0) } ?? .empty
          )
        }
      }

      Section(String(localized: "合作夥伴", bundle: .module)) {
        ForEach(store.sponsorData.partner, id: \.name) { partner in
          sponsorCell(name: partner.name, logoURL: partner.icon, url: partner.link)
        }
      }
    }
    .contentMargins(.bottom, -4, for: .scrollIndicators)
  }

  enum NavigationIndicator {
    case link(URL)
    case chevron
    case empty
  }

  @ViewBuilder
  private func sponsorCell(
    name: String,
    logoURL: URL?,
    url: URL?
  ) -> some View {
    HStack {
      let logoSize: CGFloat = 80
      if let logoURL = logoURL {
        CachedAsyncImage(url: logoURL) { phase in
          switch phase {
          case let .success(image):
            image
              .resizable()
              .scaledToFit()
              .frame(width: logoSize, height: logoSize)
          case .failure, .empty:
            Image(systemName: "building.2")
              .frame(width: logoSize, height: logoSize)
          @unknown default:
            Image(systemName: "building.2")
              .frame(width: logoSize, height: logoSize)
          }
        }
      } else {
        Image(systemName: "building.2")
          .frame(width: logoSize, height: logoSize)
      }

      Text(name)
        .font(.headline)

      Spacer()

      if let url = url {
        Link(destination: url, label: { Image(systemName: "arrow.up.right.square") })
      }
    }
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
        CachedAsyncImage(url: photoURL) { phase in
          switch phase {
          case let .success(image):
            image
              .resizable()
              .scaledToFill()
              .frame(width: avatarSize, height: avatarSize)
              .clipShape(Circle())
          case .failure, .empty:
            Image(systemName: "person.fill")
              .frame(width: avatarSize, height: avatarSize)
          @unknown default:
            Image(systemName: "person.fill")
              .frame(width: avatarSize, height: avatarSize)
          }
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
        Link(
          destination: url,
          label: {
            Image(systemName: "arrow.up.right.square")
              .foregroundStyle(Color(.accent))
          }
        )
      case .chevron:
        Image(systemName: "chevron.right")
          .foregroundStyle(Color(.accent))
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
    .contentMargins(.bottom, -4, for: .scrollIndicators)
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
    .contentMargins(.bottom, -4, for: .scrollIndicators)
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

  var backgroundColor: Color {
    switch self {
    case .speaker:
      return Color(.iPlaygroundBlueBackground)
    case .sponsor:
      return Color(.iPlaygroundYellowBackground)
    case .staff:
      return Color(.iPlaygroundPinkBackground)
    }
  }
}

#Preview {
  CommunityView(store: .init(initialState: .init(), reducer: { CommunityFeature() }))
}
