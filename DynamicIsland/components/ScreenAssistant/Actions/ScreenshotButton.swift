//
//  ChatPanels.swift
//  DynamicIsland
//
//  Created by DanFQ

import AppKit
import SwiftUI
import Defaults

// MARK: - Screenshot Button Component
struct ScreenshotButton: View {
    @ObservedObject var screenAssistantManager = ScreenAssistantManager.shared
    @StateObject private var screenshotTool = ScreenshotSnippingTool.shared
    @State private var showingScreenshotOptions = false

    var body: some View {
        HStack(spacing: 4) {
            // Main screenshot button
            Button(action: startQuickScreenshot) {
                Image(systemName: getIconName())
                    .foregroundColor(getIconColor())
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Take area screenshot")
            .disabled(screenshotTool.isSnipping)
            .scaleEffect(screenshotTool.isSnipping ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: screenshotTool.isSnipping)

            // Options dropdown button
            Button(action: { showingScreenshotOptions.toggle() }) {
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Screenshot options")
            .disabled(screenshotTool.isSnipping)
            .popover(isPresented: $showingScreenshotOptions) {
                ScreenshotOptionsPopover { type in
                    startScreenshot(type: type)
                    showingScreenshotOptions = false
                }
            }
        }
    }

    private func getIconName() -> String {
        if screenshotTool.isSnipping {
            return "camera.viewfinder"
        } else {
            return "camera.aperture"
        }
    }

    private func getIconColor() -> Color {
        if screenshotTool.isSnipping {
            return .red
        } else {
            return .green
        }
    }

    private func startQuickScreenshot() {
        // Default to area screenshot for quick action
        startScreenshot(type: .area)
    }

    private func startScreenshot(type: ScreenshotSnippingTool.ScreenshotType) {
        // Start snipping with direct callback (ScreenshotApp-based approach)
        screenshotTool.startSnipping(type: type) { [weak screenAssistantManager] screenshotURL in
            guard let manager = screenAssistantManager else {
                print("❌ ScreenshotTool: ScreenAssistantManager deallocated during callback")
                return
            }

            print("📁 ScreenshotTool: Adding \(type.displayName.lowercased()) screenshot to chat: \(screenshotURL.lastPathComponent)")
            manager.addFiles([screenshotURL])
            print("📸 \(type.displayName) screenshot captured and added to chat successfully")
        }
    }
}
