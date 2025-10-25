//
//  ChatPanels.swift
//  DynamicIsland
//
//  Created by DanFQ

import AppKit
import SwiftUI
import Defaults

// MARK: - Chat Messages View (Redesigned for standalone panel)
struct ChatMessagesView: View {
    @ObservedObject var screenAssistantManager = ScreenAssistantManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Text("AI Assistant")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    screenAssistantManager.closePanels()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close assistant")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))

            Divider()

            // Chat content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if screenAssistantManager.chatMessages.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue.opacity(0.6))

                                VStack(spacing: 8) {
                                    Text("AI Assistant")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)

                                    Text("Start a conversation to see your chat history here")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 80)
                        } else {
                            ForEach(screenAssistantManager.chatMessages) { message in
                                StreamingChatMessageBubble(message: message)
                                    .id(message.id)
                            }

                            if screenAssistantManager.isLoading {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("AI is thinking...")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                .onChange(of: screenAssistantManager.chatMessages.count) { _, _ in
                    if let lastMessage = screenAssistantManager.chatMessages.last {
                        withAnimation(.easeOut(duration: 0.5)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: screenAssistantManager.isLoading) { _, _ in
                    if screenAssistantManager.isLoading {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                if let lastMessage = screenAssistantManager.chatMessages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(ChatPanelsVisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
    }
}
