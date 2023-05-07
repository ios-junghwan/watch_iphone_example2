//
//  watch_iphone_example2_wApp.swift
//  watch_iphone_example2_w Watch App
//
//  Created by Jung Hwan Park on 2023/05/04.
//

import SwiftUI

@main
struct watch_iphone_example2_w_Watch_AppApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self)
    private var extensionDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        WKNotificationScene(controller: NotificationController.self, category: LocalNotifications.categoryIdentifier)

        WKNotificationScene(controller: RemoteNotificationController.self, category: RemoteNotificationController.categoryIdentifier)
    }
}
