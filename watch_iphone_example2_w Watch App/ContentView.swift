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

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let localNotification = LocalNotifications()

    private var INITIAL_TIME = 10

    var coreDataStack: CoreDataStack = .init(modelName: "TimerModel")

    var body: some View {

        mainView
        .padding()
        .onAppear(perform: {
            fetchFromCoreData()
        })
        .onReceive(timer) { _ in
            if connectivityManager.timeRemaining > 0 && connectivityManager.isRunning {
                connectivityManager.timeRemaining -= 1
                saveToCoreData(isRunning: true)
            } else {
                saveToCoreData(isRunning: false)
                connectivityManager.timeRemaining = INITIAL_TIME
                connectivityManager.isRunning = false
//                connectivityManager.send(["end":10])
            }
        }
    }

    func fetchFromCoreData() {
        let fetch = TimerTime.fetchRequest()
        do {
            let managedContext = coreDataStack.managedContext
            let results = try managedContext.fetch(fetch)
            connectivityManager.timeRemaining = Int(results.last?.time ?? 10)
            connectivityManager.isRunning = results.last?.isRunning ?? false
        } catch let error as NSError {
            print("Fetch error: \(error) description: \(error.userInfo)")
        }
    }

    func saveToCoreData(isRunning: Bool? = false) {
        let managedContext = coreDataStack.managedContext
        let coreDataTime = TimerTime(context: managedContext)
        coreDataTime.time = Int16(connectivityManager.timeRemaining)
        coreDataTime.isRunning = isRunning ?? false
        coreDataStack.saveContext()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension ContentView {
    private var mainView: some View {
        ScrollView {
            Image(systemName: "figure.run")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text(String(format:"%d:%02d", 0, connectivityManager.timeRemaining))
                .backgroundStyle(.purple)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
            Spacer()
            Button("시작") {
                connectivityManager.send(["start":10])
                Task {
                    connectivityManager.isRunning = true
                    do {
                        try await localNotification.schedule(after: 10)
                    } catch {
                        print("⌚️ local notification: \(error.localizedDescription)")
                    }
                }
            }
            .disabled(connectivityManager.isRunning)
            .tint(.red)
            .foregroundColor(.white)
            .fontWeight(.bold)
            .alert(item: $connectivityManager.notificationMessage) { message in
                 Alert(title: Text(message.text),
                       dismissButton: .default(Text("Dismiss")))
            }
            Button("멈추기") {
                saveToCoreData(isRunning: false)
                connectivityManager.timeRemaining = INITIAL_TIME
                connectivityManager.isRunning = false
                connectivityManager.send(["stop":10])
            }
            .tint(.blue)
            .foregroundColor(.white)
            .fontWeight(.bold)
        }
    }
}
