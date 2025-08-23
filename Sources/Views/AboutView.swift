import ComposableArchitecture
import Features
import Models
import SwiftUI

@ViewAction(for: AboutFeature.self)
package struct AboutView: View {
  @Bindable package var store: StoreOf<AboutFeature>

  package init(store: StoreOf<AboutFeature>) {
    self.store = store
  }

  package var body: some View {
    List {
      importantLinksSection
      socialMediaSection
      appInfoSection
    }
    .navigationTitle("關於")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      send(.task)
    }
  }

  @ViewBuilder
  private var importantLinksSection: some View {
    Section("重要連結") {
      ForEach(importantLinks) { link in
        urlMenuButton(link: link)
      }
    }
  }

  @ViewBuilder
  private var socialMediaSection: some View {
    if !socialMediaLinks.isEmpty {
      Section("社群媒體") {
        ForEach(socialMediaLinks) { link in
          urlMenuButton(link: link)
        }
      }
    }
  }

  @ViewBuilder
  private var appInfoSection: some View {
    Section("App 資訊") {
      ForEach(appInfoLinks) { link in
        urlMenuButton(link: link)
      }

      if !store.appVersion.isEmpty {
        HStack {
          Label("版本資訊", systemImage: "info.circle")
          Spacer()
          Text("\(store.appVersion) (\(store.buildNumber))")
            .foregroundColor(.secondary)
        }
      }
    }
  }

  @ViewBuilder
  private func urlMenuButton(link: Models.Link) -> some View {
    Menu(
      content: {
        copyURLButton(url: link.url)
      },
      label: {
        HStack {
          if let iconName = link.icon {
            Label(link.title, systemImage: iconName)
          } else {
            Text(link.title)
          }
          Spacer()
          Image(systemName: "chevron.right")
            .foregroundColor(.secondary)
            .font(.caption)
        }
      },
      primaryAction: {
        send(.tapURL(link.url))
      }
    )
  }

  @ViewBuilder
  private func copyURLButton(url: URL) -> some View {
    Button(
      action: {
        send(.tapCopyURL(url))
      },
      label: {
        Label("拷貝", systemImage: "document.on.document")
      }
    )
  }

  private var importantLinks: [Models.Link] {
    store.links.filter { link in
      link.type == .primary
    }
  }

  private var socialMediaLinks: [Models.Link] {
    store.links.filter { link in
      link.type == .social
    }
  }

  private var appInfoLinks: [Models.Link] {
    store.links.filter { link in
      link.type == .appInfo
    }
  }
}

#Preview {
  NavigationStack {
    AboutView(
      store: .init(
        initialState: .init(),
        reducer: { AboutFeature() }
      )
    )
  }
}
