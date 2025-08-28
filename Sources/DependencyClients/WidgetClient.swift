//
//  WidgetClient.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/28.
//

import Dependencies
import DependenciesMacros
import Foundation
import WidgetKit

@DependencyClient
public struct WidgetClient: Sendable {
  /// Reload timelines for a specific widget kind
  public var reloadTimelines: @Sendable (String) -> Void
}

extension WidgetClient: TestDependencyKey {
  public static let testValue = Self()
  public static let previewValue = Self(reloadTimelines: { _ in })
}

extension DependencyValues {
  public var widgetClient: WidgetClient {
    get { self[WidgetClient.self] }
    set { self[WidgetClient.self] = newValue }
  }
}
