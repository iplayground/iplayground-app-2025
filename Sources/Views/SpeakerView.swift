//
//  SpeakerView.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/21.
//

import ComposableArchitecture
import Features
import SwiftUI

struct SpeakerView: View {
  let store: StoreOf<SpeakerFeature>

  var body: some View {
    VStack {
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
        .padding(.bottom, 8)
      }

      Text(store.speaker.name)
        .font(.title)
        .fontWeight(.bold)
        .padding(.bottom, 2)

      if let title = store.speaker.title, !title.isEmpty {
        Text(title)
          .font(.subheadline)
          .foregroundColor(.secondary)
          .padding(.bottom, 8)
      }

      Text(store.speaker.intro)
        .font(.body)
        .multilineTextAlignment(.center)
        .padding(.bottom, 12)
        .padding(.horizontal)

      HStack(spacing: 16) {
        if let url = store.speaker.url {
          Link(destination: url) {
            Image(systemName: "link")
          }
        }
        if let fb = store.speaker.fb {
          Link(destination: fb) {
            Image(systemName: "f.circle")
          }
        }
        if let github = store.speaker.github {
          Link(destination: github) {
            Image(systemName: "logo.github")
          }
        }
        if let linkedin = store.speaker.linkedin {
          Link(destination: linkedin) {
            Image(systemName: "link.circle")
          }
        }
        if let threads = store.speaker.threads {
          Link(destination: threads) {
            Image(systemName: "number")
          }
        }
        if let x = store.speaker.x {
          Link(destination: x) {
            Image(systemName: "x.circle")
          }
        }
        if let ig = store.speaker.ig {
          Link(destination: ig) {
            Image(systemName: "camera")
          }
        }
      }
      .font(.title2)
      .foregroundColor(.accentColor)
    }
  }
}
