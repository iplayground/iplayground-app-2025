//
//  NowView.swift
//  AppPackage
//
//  Created by ethanhuang on 2025/8/17.
//

import Foundation
import SwiftUI

// 我們這邊有幾個可能的 Now 的狀態 一個是在全部的議程之前的一個倒數 其次是議程當中現在的議程是什麼 以及下一個議程是什麼 然後還有一個狀態是說議程都結束 以後的就是說謝謝大家我們整個活動已經結束了 所以這邊的呈現的資訊應該會有 由当下的时间以及议程列表里的资料来决定

// enum NowState {
//   case beforeAllSessions(countdown: Int)
//   case inSession(currentSession: Session, nextSession: Session)
//   case afterAllSessions
// }

struct NowView: View {
  var body: some View {
    Text("Now")
  }
}

#Preview {
  NowView()
}
