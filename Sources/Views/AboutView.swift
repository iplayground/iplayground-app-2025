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
      .navigationTitle("關於")
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
      Label("打開 Apple 地圖", systemImage: "map")
    }
  )

  private let googleMapsLink = SwiftUI.Link(
    destination: URL(string: "https://maps.app.goo.gl/un36yK3ptkxnUiTE6")!,
    label: {
      Label("打開 Google 地圖", systemImage: "map")
    }
  )

  @ViewBuilder
  private var mapSection: some View {
    Section("地點") {
      HStack {
        Menu(
          content: {
            appleMapsLink
            googleMapsLink
          },
          label: {
            Map(initialPosition: initialMapPosition) {
              Annotation("政大公企中心", coordinate: coordinate) {
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
                Text("政大公企中心")
                Text("台北市大安區金華街 187 號")
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
