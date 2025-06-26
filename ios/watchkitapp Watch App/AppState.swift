//
//  AppState.swift
//  Runner
//
//  Created by 방경식 on 5/29/25.
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isRecording: Bool = false
    
    private init() { }
}
