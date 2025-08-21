//
//  TodayFeature+Path.swift
//  Features
//
//  Created by ethanhuang on 2025/8/21.
//
import ComposableArchitecture

extension TodayFeature {
  @Reducer(state: .equatable, action: .equatable)
  package enum Path {
    case speaker(SpeakerFeature)
  }
}
