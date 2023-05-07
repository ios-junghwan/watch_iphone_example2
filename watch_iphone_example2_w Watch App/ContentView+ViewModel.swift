//
//  ContentView+ViewModel.swift
//  watch_iphone_example2_w Watch App
//
//  Created by Jung Hwan Park on 2023/05/06.
//

import Foundation

extension ContentView {

    final class ViewModel: ObservableObject {

        @Published var isActive = false

        @Published var showingAlert = false

        @Published var time: String = "0:10"

        @Published var seconds: Float = 10.0 {
            didSet {
                self.time = "\(Int(seconds)):00"
            }
        }
        private var initialTime = 0
        private var endDate = Date()

        func start(minutes: Float) {
            self.initialTime = Int(seconds)
            self.endDate = Date()
            self.isActive = true
            self.endDate = Calendar.current.date(byAdding: .second, value: Int(minutes), to: endDate)!
        }

        func reset() {
            self.seconds = Float(initialTime)
            self.isActive = false
            self.time = "00:\(Int(seconds))"
        }

        func updateCountdown(){
            guard isActive else { return }

            let now = Date()
            let diff = endDate.timeIntervalSince1970 - now.timeIntervalSince1970

            if diff <= 0 {
                self.isActive = false
                self.time = "0:00"
                self.showingAlert = true
                return
            }

            let date = Date(timeIntervalSince1970: diff)
            let calendar = Calendar.current
            let minutes = calendar.component(.minute, from: date)
            let seconds = calendar.component(.second, from: date)

            self.seconds = Float(seconds)
            self.time = String(format:"%d:%02d", minutes, seconds)
        }
    }
}
