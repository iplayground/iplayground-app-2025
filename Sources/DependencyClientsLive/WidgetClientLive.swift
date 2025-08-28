//
//  WidgetClientLive.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/28.
//

import Dependencies
import DependencyClients
import WidgetKit

extension WidgetClient: DependencyKey {
  public static let liveValue = Self(
    reloadTimelines: { kind in
      WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
  )
}
