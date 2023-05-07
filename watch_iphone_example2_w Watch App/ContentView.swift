//
//  ContentView.swift
//  watch_app_jhp Watch App
//
//  Created by Jung Hwan Park on 2023/04/26.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared

    @State var startDate = Date.now

    @State var timeElapsed: Int = 0

    @StateObject private var vm = ViewModel()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let localNotification = LocalNotifications()

    var body: some View {
        ScrollView {
            Image(systemName: "figure.run")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("\(vm.time)")
                .backgroundStyle(.purple)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
            Spacer()
            Button("시작") {
                Task {
                    do {
                        try await localNotification.schedule(after: 10)
                    } catch {
                        print("⌚️ local notification: \(error.localizedDescription)")
                    }
                }
                vm.start(minutes: vm.seconds)
                WatchConnectivityManager.shared.send("\(vm.seconds) \n\(Date())")
            }
            .disabled(vm.isActive)
            .tint(.red)
            .foregroundColor(.white)
            .fontWeight(.bold)
            .alert(item: $connectivityManager.notificationMessage) { message in
                 Alert(title: Text(message.text),
                       dismissButton: .default(Text("Dismiss")))
            }
            Button("멈추기") {
                vm.reset()
                WatchConnectivityManager.shared.send("리셋")
            }
            .tint(.blue)
            .foregroundColor(.white)
            .fontWeight(.bold)
        }
        .padding()
        .onReceive(timer) { _ in
            vm.updateCountdown()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
