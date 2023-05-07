//
//  NotificationView.swift
//  watch_iphone_example2_notification
//
//  Created by Jung Hwan Park on 2023/05/04.
//
import SwiftUI

struct NotificationView: View {
  // 1
  let message: String
  let image: Image

  // 2
  var body: some View {
    ScrollView {
      Text(message)
        .font(.headline)

      image
        .resizable()
        .scaledToFit()
    }
  }
}


struct NotificationView_Previews: PreviewProvider {
  static var previews: some View {
    NotificationView(message: "Hello world", image: Image(systemName: "checkmark"))
  }
}
