import ComposableArchitecture
import Features
import MapKit
import Models
import SwiftUI

// Coordinate and address are hard-coded for 2025 event

let coordinate = CLLocationCoordinate2D(
  latitude: 25.030146,
  longitude: 121.527629
)

@MainActor
let initialMapPosition: MapCameraPosition = .region(
  .init(
    center: coordinate,
    latitudinalMeters: 200,
    longitudinalMeters: 200
  )
)

@ViewAction(for: AboutFeature.self)
package struct AboutView: View {
  @Bindable package var store: StoreOf<AboutFeature>
  @State private var lookAroundScene: MKLookAroundScene?

  package init(store: StoreOf<AboutFeature>) {
    self.store = store
  }

  package var body: some View {
    NavigationStack {
      List {
        mapSection
        importantLinksSection
        socialMediaSection
        appInfoSection
      }
      .navigationTitle(String(localized: "關於", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .task {
        send(.task)
      }
      .task {
        await requestLookAround()
      }
    }
  }

  private let appleMapsLink = SwiftUI.Link(
    destination: URL(
      string:
        "https://maps.apple.com/place?coordinate=25.030146,121.527629&place-id=IC4414FF248A5DFE5"
    )!,
    label: {
      Label(String(localized: "打開 Apple 地圖", bundle: .module), systemImage: "map")
    }
  )

  private let googleMapsLink = SwiftUI.Link(
    destination: URL(string: "https://maps.app.goo.gl/un36yK3ptkxnUiTE6")!,
    label: {
      Label(String(localized: "打開 Google 地圖", bundle: .module), systemImage: "map")
    }
  )

  @ViewBuilder
  private var mapSection: some View {
    Section(String(localized: "場地", bundle: .module)) {
      HStack {
        Menu(
          content: {
            appleMapsLink
            googleMapsLink
          },
          label: {
            Map(initialPosition: initialMapPosition) {
              Annotation(String(localized: "政大公企中心", bundle: .module), coordinate: coordinate) {
                Image(systemName: "mappin.and.ellipse")
              }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 8))
          }
        )

        LookAroundPreview(
          scene: $lookAroundScene,
          allowsNavigation: true,
          showsRoadLabels: true
        )
        .aspectRatio(1, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 8))
      }

      Menu(
        content: {
          appleMapsLink
          googleMapsLink
        },
        label: {
          VStack {
            Label(
              title: {
                Text("政大公企中心", bundle: .module)
                  .multilineTextAlignment(.leading)
                Text("台北市大安區金華街 187 號", bundle: .module)
                  .multilineTextAlignment(.leading)
              },
              icon: {
                Image(systemName: "mappin.and.ellipse")
              }
            )
          }
          .contentShape(Rectangle())
        }
      )
    }
  }

  private func requestLookAround() async {
    Task.detached {
      let request = MKLookAroundSceneRequest(coordinate: coordinate)
      guard let scene = try? await request.scene else {
        return
      }
      Task { @MainActor in
        self.lookAroundScene = scene
      }
    }
  }

  @ViewBuilder
  private var importantLinksSection: some View {
    Section(String(localized: "重要連結", bundle: .module)) {
      ForEach(importantLinks) { link in
        urlMenuButton(link: link)
      }
    }
  }

  @ViewBuilder
  private var socialMediaSection: some View {
    if !socialMediaLinks.isEmpty {
      Section(String(localized: "社群媒體", bundle: .module)) {
        ForEach(socialMediaLinks) { link in
          urlMenuButton(link: link)
        }
      }
    }
  }

  @ViewBuilder
  private var appInfoSection: some View {
    Section(String(localized: "App 資訊", bundle: .module)) {
      ForEach(appInfoLinks) { link in
        urlMenuButton(link: link)
      }

      // Link to Settings
      if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
        let settingsLink = Models.Link(
          id: "licensePlist",
          title: "Acknowledgements",
          url: settingsURL,
          icon: "list.dash",
          type: .appInfo
        )
        urlMenuButton(link: settingsLink)
      }

      if !store.appVersion.isEmpty {
        HStack {
          Label(String(localized: "版本資訊", bundle: .module), systemImage: "info.circle")
          Spacer()
          Text(verbatim: "\(store.appVersion) (\(store.buildNumber))")
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
          Image(systemName: "arrow.up.right.square")
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
        Label(String(localized: "拷貝", bundle: .module), systemImage: "document.on.document")
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
