//
//  NowWidgetEntryView.swift
//  iPlayground
//
//  Created by ethanhuang on 2025/8/28.
//

import Models
import SwiftUI
import WidgetKit

struct NowWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      switch entry.phase {
      case let .beforeEvent(eventStartDate):
        beforeEventView(eventStartDate: eventStartDate)
      case let .duringEvent(currentSession, nextSession, nextNextSession):
        duringEventView(
          currentSession: currentSession,
          nextSession: nextSession,
          nextNextSession: nextNextSession
        )
      case .afterEvent:
        afterEventView
      }
    }
    .padding()
  }

  @ViewBuilder
  private func beforeEventView(eventStartDate: Date) -> some View {
    let duration = Duration.seconds(eventStartDate.timeIntervalSince(entry.date))

    Text(
      "iPlayground 倒數中：\(Text(duration.formatted(.units(allowed: [.days, .hours, .minutes], width: .narrow))))"
    )
  }

  @ViewBuilder
  private func duringEventView(
    currentSession: SessionWrapper?,
    nextSession: SessionWrapper?,
    nextNextSession: SessionWrapper?
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      if let currentSession = currentSession {
        let duration = Duration.seconds(
          currentSession.dateInterval?.end.timeIntervalSince(entry.date) ?? 0
        )
        Text(
          """
          進行中：\(currentSession.title)\(currentSession.speaker.isEmpty ? "" : " - \(currentSession.speaker)")（剩餘：\(Text(duration.formatted(.units(allowed: [.hours, .minutes], width: .narrow))))）
          """
        )
        .foregroundStyle(Color(.iPlaygroundYellow))
      }

      if let nextSession = nextSession {
        Text(
          "接下來：\(Text(nextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextSession.title)\(nextSession.speaker.isEmpty ? "" : " - \(nextSession.speaker)")"
        )
        .foregroundStyle(Color(.iPlaygroundPink))
      }

      if let nextNextSession = nextNextSession {
        Text(
          "再接下來：\(Text(nextNextSession.dateInterval?.start.formatted(date: .omitted, time: .shortened) ?? "")) \(nextNextSession.title)\(nextNextSession.speaker.isEmpty ? "" : " - \(nextNextSession.speaker)")"
        )
        .foregroundStyle(Color(.iPlaygroundBlue))
      }
    }
  }

  @ViewBuilder
  private var afterEventView: some View {
    Text("今年的活動已結束，感謝您的參與！")
  }
}
