//
//  WatchConnectivityManager.swift
//  watch_iphone_example2
//
//  Created by Jung Hwan Park on 2023/04/26.
//

import Foundation
import WatchConnectivity

struct NotificationMessage: Identifiable {
    let id = UUID()
    let text: String
}

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    @Published var notificationMessage: NotificationMessage? = nil

    @Published var timeRemaining: Int = 10

    @Published var isRunning: Bool = false

    private override init() {
        super.init()

        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    private let kMessageKey = "message"

    private let kStartKey = "start"

    private let kStopKey = "stop"

    func send(_ message: [String: Any]) {
        print(message)
        guard WCSession.default.activationState == .activated else {
            return
        }
        #if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            return
        }
        #else
        guard WCSession.default.isCompanionAppInstalled else {
            return
        }
        #endif
        print("Sending")
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Cannot send message: \(String(describing: error))")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let notificationText = message[kMessageKey] as? String {
            DispatchQueue.main.async { [weak self] in
                self?.notificationMessage = NotificationMessage(text: notificationText)
            }
        }
        if let start = message[kStartKey] as? Int {
            DispatchQueue.main.async { [weak self] in
                self?.timeRemaining = start
                self?.isRunning = true
            }
        }
        if let end = message[kStopKey] as? Int {
            DispatchQueue.main.async { [weak self] in
                self?.timeRemaining = end
                self?.isRunning = false
            }
        }
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("Activation complete")
    }

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        session.activate()
    }
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
}
