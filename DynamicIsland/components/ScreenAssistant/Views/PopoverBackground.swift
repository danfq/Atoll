//
//  PopoverBackground.swift
//  DynamicIsland
//
//  Created by DanFQ

import AppKit
import SwiftUI
import Defaults

// MARK: - Screenshot Popover Background (Hidden from Screen Recording)
struct ScreenshotPopoverBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        // Apply screen capture protection like our other panels
        DispatchQueue.main.async {
            if let window = view.window {
                self.updateScreenCaptureVisibility(window: window)
                self.setupScreenCaptureObserver(window: window)
            }
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Update screen capture protection when view updates
        if let window = nsView.window {
            updateScreenCaptureVisibility(window: window)
        }
    }

    private func updateScreenCaptureVisibility(window: NSWindow) {
        let shouldHide = Defaults[.hidePanelsFromScreenCapture]

        if shouldHide {
            // Hide from screen capture and recording
            window.sharingType = .none
            print("🙈 ScreenshotPopover: Hidden from screen capture and recordings")
        } else {
            // Allow normal screen capture
            window.sharingType = .readOnly
            print("👁️ ScreenshotPopover: Visible in screen capture and recordings")
        }
    }

    private func setupScreenCaptureObserver(window: NSWindow) {
        // Observe changes to hidePanelsFromScreenCapture setting
        Defaults.observe(.hidePanelsFromScreenCapture) { [weak window] change in
            DispatchQueue.main.async {
                guard let window = window else { return }
                self.updateScreenCaptureVisibility(window: window)
            }
        }
    }
}
