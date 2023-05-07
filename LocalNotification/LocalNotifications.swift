import Foundation
import UserNotifications

final class LocalNotifications: NSObject {
    static let categoryIdentifier = "Cashwalk"

    private let actionIdentifier = "viewCatsAction"

    override init() {
        super.init()
        print("Local Notifications")
        Task {
            do {
                try await self.register()
//                try await self.schedule()
            } catch {
                print("⌚️ local notification: \(error.localizedDescription)")
            }
        }
    }

    func register() async throws {
        let current = UNUserNotificationCenter.current()
        try await current.requestAuthorization(options: [.alert, .sound])

        current.removeAllPendingNotificationRequests()

        let action = UNNotificationAction(
            identifier: self.actionIdentifier,
            title: "Cashwalk",
            options: .foreground)

        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [action],
            intentIdentifiers: [])

        current.setNotificationCategories([category])
        current.delegate = self
    }

    func schedule(after: Int) async throws {
        let current = UNUserNotificationCenter.current()
        let settings = await current.notificationSettings()
        guard settings.alertSetting == .enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "애플워치"
        content.subtitle = "정말 신기한데요"
        content.body = "Awesome!"
        content.categoryIdentifier = Self.categoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(after), repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger)

        try await current.add(request)
    }
}

extension LocalNotifications: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.list, .sound]
    }
}
