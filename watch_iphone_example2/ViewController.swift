//
//  ViewController.swift
//  watch_iphone_example2
//
//  Created by Jung Hwan Park on 2023/05/04.
//

import UIKit
import WatchConnectivity
import Combine
import UserNotifications

class ViewController: UIViewController {

    private var connectivityManager = WatchConnectivityManager.shared

    private var lapseArray = [String]()

    var cancellables = Set<AnyCancellable>()

    @IBOutlet weak var timerLabel: UILabel!

    @IBOutlet weak var startButton: UIButton!

    @IBOutlet weak var stopButton: UIButton!

    private var timeRemaining: Int = 10

    private var timer: Timer?

    let localNotification = LocalNotifications()

    override func viewDidLoad() {
        super.viewDidLoad()
        bindManager()
        setUpUI()
        Task {
            do {
                try await localNotification.register()
            } catch {
                print("⌚️ local notification: \(error.localizedDescription)")
            }
        }
        UNUserNotificationCenter.current().delegate = self
    }

    private func setUpUI() {
        timerLabel.font = UIFont(descriptor: UIFont.systemFont(ofSize: 60.0, weight: .bold).fontDescriptor.withDesign(.rounded) ?? UIFont.systemFont(ofSize: 60.0, weight: .bold).fontDescriptor, size: 60.0)
        timerLabel.text = "00:10"
        startButton.titleLabel?.font = UIFont(descriptor: UIFont.systemFont(ofSize: 24.0, weight: .bold).fontDescriptor.withDesign(.rounded) ?? UIFont.systemFont(ofSize: 24.0, weight: .bold).fontDescriptor, size: 24.0)
        stopButton.titleLabel?.font = UIFont(descriptor: UIFont.systemFont(ofSize: 24.0, weight: .bold).fontDescriptor.withDesign(.rounded) ?? UIFont.systemFont(ofSize: 24.0, weight: .bold).fontDescriptor, size: 24.0)
        startButton.backgroundColor = .red.withAlphaComponent(0.7)
        stopButton.backgroundColor = .blue.withAlphaComponent(0.7)
        startButton.layer.cornerRadius = 20
        stopButton.layer.cornerRadius = 20
    }

    private func bindManager() {
        connectivityManager.$notificationMessage
            .dropFirst()
            .sink { msg in

            }.store(in: &cancellables)
    }

    @IBAction func startTapped(_ sender: UIButton) {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        Task {
            do {
                try await localNotification.schedule(after: 10)
            } catch {
                print("⌚️ local notification: \(error.localizedDescription)")
            }
        }
    }

    @IBAction func stopTapped(_ sender: UIButton) {
        timer?.invalidate()
        timer = nil
        timeRemaining = 10
        timerLabel.text = String(format:"%d:%02d", 0, timeRemaining)
    }

    @objc func step() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            timer?.invalidate()
            timer = nil
            timeRemaining = 10
        }
        timerLabel.text = String(format:"%d:%02d", 0, timeRemaining)
    }

   
    @IBAction func send(_ sender: UIButton) {
        WatchConnectivityManager.shared.send("화이팅")
    }
}

extension ViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .sound])
    }
}
