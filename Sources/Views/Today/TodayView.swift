import ComposableArchitecture
import Features
import Models
import SwiftUI

struct TodayView: View {
  @Bindable var store: StoreOf<TodayFeature>

  var body: some View {
    VStack {
      List {
        Section {
          // 情況 1
          Text("iPlayground 倒數中： 1 天")  // Date(8/30 09:00)
          // 情況 2
          Text(
            """
            正在進行中：Let’s Functional Programming in Your Swift Code（剩餘：5 分鐘）
            接下來：10:40 休息
            再接下來：10:55 Swift C++ Interop
            """)  // Date(= 8/30 09:35)
          // 情況 3
          Text("今年的活動已結束，感謝您的參與！")  // Date(> 8/31 18:00)
        }

        Section(
          content: {
            sessionList // TODO: highlight cell contains current time
          },
          header: {
            dayPicker
          }
        )
      }
      .listStyle(.inset)
    }
    .task {
      store.send(.task)
    }
  }

  @ViewBuilder
  private var dayPicker: some View {
    Picker("", selection: $store.selectedDay) {
      ForEach(TodayFeature.State.Day.allCases) { day in
        Text("Day " + day.rawValue.description)
          .tag(day)
      }
    }
    .pickerStyle(.segmented)
  }

  @ViewBuilder
  private var sessionList: some View {
    ForEach(store.currentSessions) { session in
      sessionCell(session)
    }
  }

  @ViewBuilder
  private func sessionCell(_ session: SessionWrapper) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(session.timeRange)
        .font(.footnote)
        .foregroundColor(.secondary)

      Text(session.title)
        .font(.headline)

      Text(session.speaker)
        .font(.subheadline)

      if let tags = session.tags {
        Text(tags)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      if let description = session.description {
        Text(description)
          .font(.body)
          .foregroundColor(.primary)
          .padding(.top, 2)
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  TodayView(
    store: .init(
      initialState: TodayFeature.State(),
      reducer: { TodayFeature() }
    )
  )
}
