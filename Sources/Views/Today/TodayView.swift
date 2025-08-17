//
//  TodayView.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/17.
//

import Features
import Foundation
import SwiftUI

struct TodayView: View {
  var body: some View {
    VStack {
      NowView()

      SessionsView(
        store: .init(
          initialState: SessionsFeature.State(),
          reducer: { SessionsFeature() }
        )
      )
    }

  }
}

#Preview {
  TodayView()
}
