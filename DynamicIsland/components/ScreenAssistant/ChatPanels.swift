//
//  ChatPanels.swift
//  DynamicIsland
//
//  Created by DanFQ

import AppKit
import SwiftUI
import Defaults

// MARK: - Chat Messages Panel (Left Side)
class ChatMessagesPanel: NSPanel {

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        setupWindow()
        setupContentView()
    }

    override var canBecomeKey: Bool {
        return false  // Don't steal focus from input panel
    }

    override var canBecomeMain: Bool {
        return false
    }

    private func setupWindow() {
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        level = .floating
        isMovableByWindowBackground = false  // Fixed position
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isFloatingPanel = true

        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary
        ]

        // Apply screen capture hiding setting
        updateScreenCaptureVisibility()
        setupScreenCaptureObserver()

        acceptsMouseMovedEvents = true
    }

    private func setupContentView() {
        let contentView = ChatMessagesView()
        let hostingView = NSHostingView(rootView: contentView)
        self.contentView = hostingView

        // Set size for chat messages panel (wider and taller)
        let preferredSize = CGSize(width: 600, height: 500)
        hostingView.setFrameSize(preferredSize)
        setContentSize(preferredSize)
    }

    func positionOnLeftSide() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let panelFrame = frame

        // Position on the left side of the screen
        let xPosition = screenFrame.minX + 50 // 50pt from left edge
        let yPosition = screenFrame.maxY - panelFrame.height - 100 // 100pt from top

        setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
    }

    private func setupScreenCaptureObserver() {
        // Observe changes to hidePanelsFromScreenCapture setting
        Defaults.observe(.hidePanelsFromScreenCapture) { [weak self] change in
            DispatchQueue.main.async {
                self?.updateScreenCaptureVisibility()
            }
        }
    }

    private func updateScreenCaptureVisibility() {
        let shouldHide = Defaults[.hidePanelsFromScreenCapture]

        if shouldHide {
            // Hide from screen capture and recording
            self.sharingType = .none
            print("🙈 ChatMessagesPanel: Hidden from screen capture and recordings")
        } else {
            // Allow normal screen capture
            self.sharingType = .readOnly
            print("👁️ ChatMessagesPanel: Visible in screen capture and recordings")
        }
    }
}

// MARK: - Chat Input Panel (Center)
class ChatInputPanel: NSPanel {

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        setupWindow()
        setupContentView()
    }

    override var canBecomeKey: Bool {
        return true  // Can receive focus for text input
    }

    override var canBecomeMain: Bool {
        return true
    }

    // Handle ESC key globally for the panel
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            ScreenAssistantManager.shared.closePanels()
        } else {
            super.keyDown(with: event)
        }
    }

    private func setupWindow() {
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        level = .floating
        isMovableByWindowBackground = true  // Enable dragging
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isFloatingPanel = true

        styleMask.insert(.fullSizeContentView)

        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary
        ]

        // Apply screen capture hiding setting
        updateScreenCaptureVisibility()
        setupScreenCaptureObserver()

        acceptsMouseMovedEvents = true
    }

    private func setupContentView() {
        let contentView = ChatInputView()
        let hostingView = NSHostingView(rootView: contentView)
        self.contentView = hostingView

        // Set compact size for single-line input panel
        let preferredSize = CGSize(width: 500, height: 60)
        hostingView.setFrameSize(preferredSize)
        setContentSize(preferredSize)
    }

    func positionInCenter() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let panelFrame = frame

        // Position in the center-bottom of the screen (like a search bar)
        let xPosition = (screenFrame.width - panelFrame.width) / 2 + screenFrame.minX
        let yPosition = screenFrame.minY + 100 // 100pt from bottom

        setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
    }

    private func setupScreenCaptureObserver() {
        // Observe changes to hidePanelsFromScreenCapture setting
        Defaults.observe(.hidePanelsFromScreenCapture) { [weak self] change in
            DispatchQueue.main.async {
                self?.updateScreenCaptureVisibility()
            }
        }
    }

    private func updateScreenCaptureVisibility() {
        let shouldHide = Defaults[.hidePanelsFromScreenCapture]

        if shouldHide {
            // Hide from screen capture and recording
            self.sharingType = .none
            print("🙈 ChatInputPanel: Hidden from screen capture and recordings")
        } else {
            // Allow normal screen capture
            self.sharingType = .readOnly
            print("👁️ ChatInputPanel: Visible in screen capture and recordings")
        }
    }
}

// MARK: - Note: Shared Components (MarkdownText, AttachedFileChip, AddFilesButton, RecordingButton, ApiKeyAlertView)
// are defined in ScreenAssistantPanel.swift to avoid redeclaration conflicts.
