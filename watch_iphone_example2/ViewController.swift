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

    private var INITIAL_TIME = 10

    private var timer: Timer?

    let localNotification = LocalNotifications()

    override func viewDidLoad() {
        super.viewDidLoad()
        bindManager()
        setUpUI()
        registerLocalNotification()
        fetchFromCoreData()
    }

    private func registerLocalNotification() {
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

        connectivityManager.$isRunning
            .sink { val in
                if val {
                    self.startTapAction()
                } else {
                    self.timer?.invalidate()
                    self.timer = nil
                    self.connectivityManager.timeRemaining = self.INITIAL_TIME
                }
            }.store(in: &cancellables)

        connectivityManager.$timeRemaining
            .sink { [weak self] t in
                self?.timerLabel.text = String(format:"%d:%02d", 0, t)
                t == self?.INITIAL_TIME ? self?.saveToCoreData(isRunning: false) : self?.saveToCoreData(isRunning: true)
                self?.startButton.isUserInteractionEnabled = t == self?.INITIAL_TIME
                self?.startButton.backgroundColor = t == self?.INITIAL_TIME ? .red.withAlphaComponent(0.7) : .gray.withAlphaComponent(0.7)
            }.store(in: &cancellables)

    }

    @IBAction func startTapped(_ sender: UIButton) {
        startTapAction()
        connectivityManager.send(["start":10])
    }

    private func startTapAction() {
        step()
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        startButton.isUserInteractionEnabled = false
        startButton.backgroundColor = .gray.withAlphaComponent(0.7)
    }

    @IBAction func stopTapped(_ sender: UIButton) {
        timer?.invalidate()
        timer = nil
        connectivityManager.timeRemaining = INITIAL_TIME
        saveToCoreData(isRunning: false)
        timerLabel.text = String(format:"%d:%02d", 0, connectivityManager.timeRemaining)
        startButton.isUserInteractionEnabled = true
        startButton.backgroundColor = .red.withAlphaComponent(0.7)
        connectivityManager.send(["stop":10])
    }

    @objc func step() {
        if connectivityManager.timeRemaining > 0 {
            connectivityManager.timeRemaining -= 1
        } else {
            timer?.invalidate()
            timer = nil
            connectivityManager.timeRemaining = INITIAL_TIME
            Task {
                do {
                    try await localNotification.schedule(after: 1)
                } catch {
                    print("⌚️ local notification: \(error.localizedDescription)")
                }
            }
        }
    }

    func fetchFromCoreData() {
        let fetch = TimerTime.fetchRequest()
        do {
            let managedContext = AppDelegate.sharedAppDelegate.coreDataStack.managedContext
            let results = try managedContext.fetch(fetch)
            connectivityManager.timeRemaining = Int(results.last?.time ?? 10)
            timerLabel.text = String(format:"%d:%02d", 0, connectivityManager.timeRemaining)
            startButton.isUserInteractionEnabled = !(results.last?.isRunning ?? false)
            guard timer == nil else { return }
            if !startButton.isUserInteractionEnabled {
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(step), userInfo: nil, repeats: true)
                startButton.backgroundColor = .gray.withAlphaComponent(0.7)
            }
        } catch let error as NSError {
            print("Fetch error: \(error) description: \(error.userInfo)")
        }
    }

    func saveToCoreData(isRunning: Bool? = false) {
        let managedContext = AppDelegate.sharedAppDelegate.coreDataStack.managedContext
        let coreDataTime = TimerTime(context: managedContext)
        coreDataTime.time = Int16(connectivityManager.timeRemaining)
        coreDataTime.isRunning = isRunning ?? false
        AppDelegate.sharedAppDelegate.coreDataStack.saveContext()
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
