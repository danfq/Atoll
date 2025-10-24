import SwiftUI

struct NotchAssistantView: View {
    @EnvironmentObject var vm: DynamicIslandViewModel
    @ObservedObject var tvm = TrayDrop.shared

    var body: some View {
        HStack {
            // Chats List Panel
            ChatMessagesView()

            // Chat Panel
            ChatInputView()
        }
    }
}
