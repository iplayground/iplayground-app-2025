//
//  SpeakerView.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/21.
//

import ComposableArchitecture
import Features
import Models
import SwiftUI

@ViewAction(for: SpeakerFeature.self)
struct SpeakerView: View {
  let store: StoreOf<SpeakerFeature>

  var body: some View {
    List {
      HStack(spacing: 16) {
        profilePhoto
        VStack(alignment: .leading) {
          speakerName
          speakerTitle
        }
        Spacer()
      }

      speakerIntro
      socialLinks
    }
    .contentMargins(.top, .zero)
    .navigationTitle("講者")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: - Child Views

  @ViewBuilder
  private var profilePhoto: some View {
    Group {
      if let photoURL = store.speaker.photo {
        let avatarSize: CGFloat = 80
        // FIXME: Cache image
        AsyncImage(url: photoURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())
        } placeholder: {
          Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: avatarSize, height: avatarSize)
        }
      }
    }
  }

  @ViewBuilder
  private var speakerName: some View {
    Text(store.speaker.name)
      .font(.title)
      .fontWeight(.bold)
  }

  @ViewBuilder
  private var speakerTitle: some View {
    Group {
      if let title = store.speaker.title, !title.isEmpty {
        Text(title)
          .font(.headline)
          .foregroundColor(.secondary)
      }
    }
  }

  @ViewBuilder
  private var speakerIntro: some View {
    Text(store.speaker.intro)
      .font(.body)
      .multilineTextAlignment(.leading)
  }

  @ViewBuilder
  private func urlMenuButton(url: URL, title: String) -> some View {
    Menu(
      content: {
        copyURLButton(url: url)
      },
      label: {
        HStack {
          VStack(alignment: .leading) {
            Text(title)
              .font(.headline)
            Text(url.absoluteString)
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          Spacer()
        }
      },
      primaryAction: {
        send(.tapURL(url))
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
        VStack {
          Label("拷貝", systemImage: "document.on.document")
        }
      }
    )
  }

  @ViewBuilder
  private var socialLinks: some View {
    if let website = store.speaker.url {
      urlMenuButton(url: website, title: String(localized: "網站", bundle: .module))
    }
    if let github = store.speaker.github {
      urlMenuButton(url: github, title: "GitHub")
    }
    if let linkedin = store.speaker.linkedin {
      urlMenuButton(url: linkedin, title: "LinkedIn")
    }
    if let x = store.speaker.x {
      urlMenuButton(url: x, title: "Twitter (X)")
    }
    if let threads = store.speaker.threads {
      urlMenuButton(url: threads, title: "Threads")
    }
    if let instagram = store.speaker.ig {
      urlMenuButton(url: instagram, title: "Instagram")
    }
    if let facebook = store.speaker.fb {
      urlMenuButton(url: facebook, title: "Facebook")
    }
  }
}

#Preview {
  NavigationStack {
    SpeakerView(
      store: .init(
        initialState: .init(
          speaker: .init(
            id: 1,
            name: "John Doe",
            title: "Software Engineer",
            intro:
              "John is a software engineer with a passion for building scalable and efficient systems.",
            photo: URL(
              string:
                "https://raw.githubusercontent.com/iplayground/SessionData/2025/v1/images/speakers/speaker_鄭宇哲.jpg"
            ),
            url: URL(string: "https://www.google.com")!,
            fb: URL(string: "https://www.facebook.com")!,
            github: URL(string: "https://www.github.com")!,
            linkedin: URL(string: "https://www.linkedin.com")!,
            threads: URL(string: "https://www.threads.net")!,
            x: URL(string: "https://www.x.com")!,
            ig: URL(string: "https://www.instagram.com")!
          )
        ),
        reducer: { SpeakerFeature() }
      )
    )
  }
}
