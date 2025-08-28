//
//  NowEntry.swift
//  iPlayground
//
//  Created by ethanhuang on 2025/8/28.
//

import Models
import WidgetKit

struct NowEntry: TimelineEntry, Hashable {
  let date: Date
  let phase: Phase

  enum Phase: Equatable, Hashable {
    case beforeEvent(eventStartDate: Date)
    case duringEvent(
      currentSession: SessionWrapper?,
      nextSession: SessionWrapper?,
      nextNextSession: SessionWrapper?
    )
    case afterEvent
  }
}
