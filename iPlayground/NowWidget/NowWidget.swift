//
//  NowWidget.swift
//  iPlayground
//
//  Created by ethanhuang on 2025/8/28.
//

import Dependencies
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
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
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

#Preview("活動中", as: .systemMedium) {
  NowWidget()
} timeline: {
  let eventStartDate = createDate(year: 2025, month: 8, day: 30).addingTimeInterval(8 * 3600)
  let beforeEventDate = Calendar(identifier: .gregorian).date(
    from: DateComponents(year: 2025, month: 8, day: 29, hour: 9, minute: 0))!

  NowEntry(
    date: beforeEventDate,
    phase: .beforeEvent(eventStartDate: eventStartDate)
  )

  let url = Bundle.sessionData.url(
    forResource: "schedule", withExtension: "json")!
  let data = try! Data(contentsOf: url)
  let schedule = try! JSONDecoder().decode(Schedule.self, from: data)
  let day1Date = createDate(year: 2025, month: 8, day: 30)
  let day1Wrappers = Provider.convertSessions(schedule.day1, date: day1Date)
  let day2Date = createDate(year: 2025, month: 8, day: 31)
  let day2Wrappers = Provider.convertSessions(schedule.day2, date: day2Date)
  let allSessions = day1Wrappers + day2Wrappers
  let entries = Provider.convertSessionWrappers(allSessions)
  for entry in entries {
    entry
  }

  let afterEventDate = Calendar(identifier: .gregorian).date(
    from: DateComponents(year: 2025, month: 8, day: 31, hour: 18, minute: 0))!

  NowEntry(
    date: afterEventDate,
    phase: .afterEvent
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
