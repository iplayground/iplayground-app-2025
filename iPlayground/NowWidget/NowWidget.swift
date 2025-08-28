//
//  NowWidget.swift
//  iPlayground
//
//  Created by ethanhuang on 2025/8/28.
//

import Models
import SwiftUI
import WidgetKit

struct NowWidget: Widget {
  let kind: String = "NowWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      NowWidgetEntryView(entry: entry)
        .containerBackground(Color(.widgetBackground), for: .widget)
    }
    .configurationDisplayName("iPlayground")
    .description(String(localized: "議程與活動"))
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview("活動前", as: .systemSmall) {
  NowWidget()
} timeline: {
  let eventStartDate = createDate(year: 2025, month: 8, day: 30).addingTimeInterval(9 * 3600)
  let beforeEventDate = Calendar(identifier: .gregorian).date(
    from: DateComponents(year: 2025, month: 8, day: 29, hour: 9, minute: 0))!

  NowEntry(
    date: beforeEventDate,
    phase: .beforeEvent(eventStartDate: eventStartDate)
  )
}

#Preview("活動中", as: .systemSmall) {
  NowWidget()
} timeline: {
  let duringEventDate = Calendar(identifier: .gregorian).date(
    from: DateComponents(year: 2025, month: 8, day: 30, hour: 9, minute: 35))!

  // Create sample sessions
  let currentSession = SessionWrapper(
    timeRange: "09:30 - 10:20",
    title: "SwiftUI 與 Combine 實作",
    speaker: "王小明",
    speakerID: 1,
    tags: "iOS · SwiftUI",
    description: "介紹如何使用 SwiftUI 和 Combine 建構現代 iOS 應用程式",
    hackMDURL: nil
  )

  let nextSession = SessionWrapper(
    timeRange: "10:30 - 11:20",
    title: "Metal 效能優化技巧",
    speaker: "李小華",
    speakerID: 2,
    tags: "iOS · Metal",
    description: "深入探討 Metal 框架的效能優化策略",
    hackMDURL: nil
  )

  NowEntry(
    date: duringEventDate,
    phase: .duringEvent(
      currentSession: currentSession,
      nextSession: nextSession,
      nextNextSession: nil
    )
  )
}

#Preview("活動結束後", as: .systemSmall) {
  NowWidget()
} timeline: {
  let afterEventDate = Calendar(identifier: .gregorian).date(
    from: DateComponents(year: 2025, month: 8, day: 31, hour: 18, minute: 0))!

  NowEntry(
    date: afterEventDate,
    phase: .afterEvent
  )
}
