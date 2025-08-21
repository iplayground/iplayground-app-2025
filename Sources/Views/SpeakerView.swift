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
    ScrollView {
      VStack(spacing: 12) {
        profilePhoto
        speakerName
        speakerTitle
        speakerIntro
        socialLinks
      }
      .padding(.horizontal)
    }
    .scrollBounceBehavior(.basedOnSize)
  }

  // MARK: - Child Views

  @ViewBuilder
  private var profilePhoto: some View {
    Group {
      if let photoURL = store.speaker.photo {
        AsyncImage(url: photoURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 120, height: 120)
            .clipShape(Circle())
        } placeholder: {
          Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 120, height: 120)
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
      .multilineTextAlignment(.center)
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
    VStack(spacing: 8) {
      if let website = store.speaker.url {
        Menu(
          content: {
            copyURLButton(url: website)
          },
          label: {
            Text("網站")
          },
          primaryAction: {
            send(.tapURL(website))
          }
        )
      }
      if let github = store.speaker.github {
        Menu(
          content: {
            copyURLButton(url: github)
          },
          label: {
            Text(verbatim: "GitHub")
          },
          primaryAction: {
            send(.tapURL(github))
          }
        )
      }
      if let linkedin = store.speaker.linkedin {
        Menu(
          content: {
            copyURLButton(url: linkedin)
          },
          label: {
            Text(verbatim: "LinkedIn")
          },
          primaryAction: {
            send(.tapURL(linkedin))
          }
        )
      }
      if let x = store.speaker.x {
        Menu(
          content: {
            copyURLButton(url: x)
          },
          label: {
            Text(verbatim: "X (Twitter)")
          },
          primaryAction: {
            send(.tapURL(x))
          }
        )
      }
      if let threads = store.speaker.threads {
        Menu(
          content: {
            copyURLButton(url: threads)
          },
          label: {
            Text(verbatim: "Threads")
          },
          primaryAction: {
            send(.tapURL(threads))
          }
        )
      }
      if let instagram = store.speaker.ig {
        Menu(
          content: {
            copyURLButton(url: instagram)
          },
          label: {
            Text(verbatim: "Instagram")
          },
          primaryAction: {
            send(.tapURL(instagram))
          }
        )
      }
      if let facebook = store.speaker.fb {
        Menu(
          content: {
            copyURLButton(url: facebook)
          },
          label: {
            Text(verbatim: "Facebook")
          },
          primaryAction: {
            send(.tapURL(facebook))
          }
        )
      }
    }
    .font(.body)
    .foregroundColor(.accentColor)
  }
}

#Preview {
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
