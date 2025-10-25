//
//  DynamicIslandApp.swift
//  DynamicIslandApp
//
//  Modified by Hariharan Mudaliar  on 20/09/25.
//

import AVFoundation
import Combine
import Defaults
import KeyboardShortcuts
import Sparkle
import SwiftUI
import SkyLightWindow

@main
struct DynamicNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Default(.menubarIcon) var showMenuBarIcon
    @Environment(\.openWindow) var openWindow

    let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

        // Initialize the settings window controller with the updater controller
        SettingsWindowController.shared.setUpdaterController(updaterController)
    }

    var body: some Scene {
        MenuBarExtra("dynamic.island", systemImage: "mountain.2.fill", isInserted: $showMenuBarIcon) {
            Button("Settings") {
                SettingsWindowController.shared.showWindow()
            }
            .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
            CheckForUpdatesView(updater: updaterController.updater)
            Divider()
            Button("Restart Atoll") {
                guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }

                let workspace = NSWorkspace.shared

                if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier)
                {

                    let configuration = NSWorkspace.OpenConfiguration()
                    configuration.createsNewApplicationInstance = true

                    workspace.openApplication(at: appURL, configuration: configuration)
                }

                NSApplication.shared.terminate(self)
            }
            Button("Quit", role: .destructive) {
                NSApplication.shared.terminate(self)
            }
            .keyboardShortcut(KeyEquivalent("Q"), modifiers: .command)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var windows: [NSScreen: NSWindow] = [:]
    var viewModels: [NSScreen: DynamicIslandViewModel] = [:]
    var window: NSWindow?
    let vm: DynamicIslandViewModel = .init()
    @ObservedObject var coordinator = DynamicIslandViewCoordinator.shared
    var whatsNewWindow: NSWindow?
    var timer: Timer?
    let calendarManager = CalendarManager.shared
    let webcamManager = WebcamManager.shared
    let dndManager = DoNotDisturbManager.shared  // NEW: DND detection
    let bluetoothAudioManager = BluetoothAudioManager.shared  // NEW: Bluetooth audio detection
    let idleAnimationManager = IdleAnimationManager.shared  // NEW: Custom idle animations
    let lockScreenPanelManager = LockScreenPanelManager.shared  // NEW: Lock screen music panel
    var closeNotchWorkItem: DispatchWorkItem?
    private var previousScreens: [NSScreen]?
    private var onboardingWindowController: NSWindowController?
    private var cancellables = Set<AnyCancellable>()
    private var windowsHiddenForLock = false

    // Debouncing mechanism for window size updates
    private var windowSizeUpdateWorkItem: DispatchWorkItem?
//    let calendarManager = CalendarManager.shared
//    let webcamManager = WebcamManager.shared
//    var closeNotchWorkItem: DispatchWorkItem?
//    private var previousScreens: [NSScreen]?
//    private var onboardingWindowController: NSWindowController?
//    private var cancellables = Set<AnyCancellable>()
//
//    // Debouncing mechanism for window size updates
//    private var windowSizeUpdateWorkItem: DispatchWorkItem?

    private func debouncedUpdateWindowSize() {
        // Cancel any existing work item
        windowSizeUpdateWorkItem?.cancel()

        // Create new work item with delay
        let workItem = DispatchWorkItem { [weak self] in
            self?.updateWindowSizeIfNeeded()
        }

        // Store reference and schedule
        windowSizeUpdateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cancel any pending window size updates
        windowSizeUpdateWorkItem?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    @objc func onScreenLocked(_: Notification) {
        print("Screen locked")
        hideWindowsForLock()
    }

    @objc func onScreenUnlocked(_: Notification) {
        print("Screen unlocked")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.restoreWindowsAfterLock()
            self.adjustWindowPosition(changeAlpha: true)
        }
    }

    private func hideWindowsForLock() {
        guard !windowsHiddenForLock else { return }
        windowsHiddenForLock = true

        if Defaults[.showOnAllDisplays] {
            for window in windows.values {
                window.alphaValue = 0
                window.orderOut(nil)
            }
        } else if let window = window {
            window.alphaValue = 0
            window.orderOut(nil)
        }
    }

    private func restoreWindowsAfterLock() {
        guard windowsHiddenForLock else { return }
        windowsHiddenForLock = false

        if Defaults[.showOnAllDisplays] {
            for window in windows.values {
                window.orderFrontRegardless()
                window.alphaValue = 1
            }
        } else if let window = window {
            window.orderFrontRegardless()
            window.alphaValue = 1
        }
    }

    private func cleanupWindows(shouldInvert: Bool = false) {
        if shouldInvert ? !Defaults[.showOnAllDisplays] : Defaults[.showOnAllDisplays] {
            for window in windows.values {
                window.close()
                NotchSpaceManager.shared.notchSpace.windows.remove(window)
            }
            windows.removeAll()
            viewModels.removeAll()
        } else if let window = window {
            window.close()
            NotchSpaceManager.shared.notchSpace.windows.remove(window)
            self.window = nil
        }
    }

    private func createDynamicIslandWindow(for screen: NSScreen, with viewModel: DynamicIslandViewModel)
        -> NSWindow
    {
        // Use the current required size instead of always using openNotchSize
        let requiredSize = calculateRequiredNotchSize()

        let window = DynamicIslandWindow(
            contentRect: NSRect(
                x: 0, y: 0, width: requiredSize.width, height: requiredSize.height),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )

        window.contentView = NSHostingView(
            rootView: ContentView()
                .environmentObject(viewModel)
                .environmentObject(webcamManager)
                //.moveToSky()
        )

        window.orderFrontRegardless()
        NotchSpaceManager.shared.notchSpace.windows.insert(window)
        //SkyLightOperator.shared.delegateWindow(window)
        return window
    }

    private func positionWindow(_ window: NSWindow, on screen: NSScreen, changeAlpha: Bool = false)
    {
        if changeAlpha {
            window.alphaValue = 0
        }

        // Use the current required size for correct placement
        let requiredSize = calculateRequiredNotchSize()
        let newFrame = targetRect(for: screen, size: requiredSize)

        // Set frame synchronously to avoid double animations when a resize is about to occur
        window.setFrame(newFrame, display: false)

        if changeAlpha {
            window.alphaValue = 1
        }
    }

    private func updateWindowSizeIfNeeded(forView view: NotchViews? = nil) {
        // Calculate required size based on current state
        let requiredSize = calculateRequiredNotchSize(forView: view)
        print("📏 updateWindowSizeIfNeeded called - requiredSize: \(requiredSize), currentView: \(view ?? coordinator.currentView)")
        print("📏 showOnAllDisplays: \(Defaults[.showOnAllDisplays])")

        if Defaults[.showOnAllDisplays] {
            // Update all windows if size has changed (multi-display mode)
            for (screen, window) in windows {
                print("📏 Multi-display: current window size: \(window.frame.size), required: \(requiredSize)")
                if window.frame.size != requiredSize {
                    let newFrame = targetRect(for: screen, size: requiredSize)
                    guard window.frame != newFrame else {
                        print("📏 Multi-display: Frame unchanged, skipping animation")
                        continue
                    }

                    print("📏 Multi-display: Animating from \(window.frame) to \(newFrame)")
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.4
                        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                        context.allowsImplicitAnimation = true
                        window.animator().setFrame(newFrame, display: true)
                    }
                }
            }
        } else {
            // Update single window if size has changed (single display mode)
            if window == nil {
                print("⚠️ Single-display: window is NIL!")
                return
            }

            if let window = window {
                print("📏 Single-display: current window size: \(window.frame.size), required: \(requiredSize)")
                print("📏 Single-display: sizes equal? \(window.frame.size == requiredSize)")
            }
            if let window = window, window.frame.size != requiredSize {
                // Find the screen this window is on
                let currentScreen = NSScreen.screens.first { screen in
                    screen.frame.intersects(window.frame)
                } ?? NSScreen.main ?? NSScreen.screens.first!

                let newFrame = targetRect(for: currentScreen, size: requiredSize)
                guard window.frame != newFrame else {
                    print("📏 Single-display: Frame unchanged, skipping animation")
                    return
                }

                print("📏 Single-display: Animating from \(window.frame) to \(newFrame)")
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.4
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    context.allowsImplicitAnimation = true
                    window.animator().setFrame(newFrame, display: true)
                }
            }
        }
    }

    private func calculateRequiredNotchSize(forView view: NotchViews? = nil) -> CGSize {
        let currentView = view ?? coordinator.currentView
        print("🔍 calculateRequiredNotchSize - currentView: \(currentView), enableScreenAssistant: \(Defaults[.enableScreenAssistant])")

        // Check if inline sneak peek is showing and notch is closed
        let isInlineSneakPeekActive = vm.notchState == .closed &&
                                      coordinator.expandingView.show &&
                                      (coordinator.expandingView.type == .music || coordinator.expandingView.type == .timer) &&
                                      Defaults[.enableSneakPeek] &&
                                      Defaults[.sneakPeekStyles] == .inline

        // If inline sneak peek is active, use a wider width to accommodate the expanded content
        if isInlineSneakPeekActive {
            // Calculate required width for inline sneak peek:
            // Album art (~32) + Middle section (380) + Visualizer (~32) + padding = ~450
            let inlineSneakPeekWidth: CGFloat = 450
            return CGSize(width: inlineSneakPeekWidth, height: vm.effectiveClosedNotchHeight)
        }

        // Use minimalistic or normal size based on settings
        let baseSize = Defaults[.enableMinimalisticUI] ? minimalisticOpenNotchSize : openNotchSize

        // required height - base by default
        var requiredHeight: CGFloat = baseSize.height

        // Only apply dynamic sizing when on stats tab and stats are enabled - same for assistant
        guard currentView == .stats && Defaults[.enableStatsFeature]
                || currentView == .assistant && Defaults[.enableScreenAssistant] else {
            print("🔍 Guard failed - returning baseSize: \(baseSize)")
            return baseSize
        }

        print("🔍 Guard passed - will calculate dynamic size")

        // for stats
        if currentView == .stats {
            let enabledGraphsCount = [
                Defaults[.showCpuGraph],
                Defaults[.showMemoryGraph],
                Defaults[.showGpuGraph],
                Defaults[.showNetworkGraph],
                Defaults[.showDiskGraph]
            ].filter { $0 }.count

            // Calculate height based on layout: 1-3 graphs = single row, 4+ graphs = two rows
            requiredHeight = baseSize.height

            if enabledGraphsCount >= 4 {
                // Two rows needed - add height for second row plus spacing
                let extraHeight: CGFloat = 120 + 12 // Graph height + spacing
                requiredHeight = baseSize.height + extraHeight
            }
        }

        // for assistant
        if currentView == .assistant {
            requiredHeight = baseSize.height + 600
            print("🔍 Assistant view - setting height to: \(requiredHeight)")
        }

        // Width stays constant - no horizontal expansion
        let finalSize = CGSize(width: baseSize.width, height: requiredHeight)
        print("🔍 Returning final size: \(finalSize)")
        return finalSize
    }

    private func targetRect(for screen: NSScreen, size: CGSize) -> NSRect {
        let screenFrame = screen.frame
        let centerX = screenFrame.origin.x + (screenFrame.width / 2)
        let newX = centerX - (size.width / 2)
        let newY = screenFrame.origin.y + screenFrame.height - size.height
        return NSRect(x: newX, y: newY, width: size.width, height: size.height)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {

        coordinator.setupWorkersNotificationObservers()
        LockScreenLiveActivityWindowManager.shared.configure(viewModel: vm)
        LockScreenManager.shared.configure(viewModel: vm)

        // Migrate legacy progress bar settings
        Defaults.Keys.migrateProgressBarStyle()

        // Initialize idle animations (load bundled + built-in face)
        idleAnimationManager.initializeDefaultAnimations()

        // Setup SystemHUD Manager
        SystemHUDManager.shared.setup(coordinator: coordinator)

        // Setup ScreenRecording Manager
        if Defaults[.enableScreenRecordingDetection] {
            ScreenRecordingManager.shared.startMonitoring()
        }

        // Setup Privacy Indicator Manager (camera and microphone monitoring)
        PrivacyIndicatorManager.shared.startMonitoring()

        // Observe tab changes - use immediate updates to sync with ContentView animation
        coordinator.$currentView.sink { [weak self] newView in
            print("👀 currentView changed to: \(newView)")
            self?.updateWindowSizeIfNeeded(forView: newView)
        }.store(in: &cancellables)

        // Observe stats settings changes - use debounced updates
        Defaults.publisher(.enableStatsFeature, options: []).sink { [weak self] _ in
            self?.debouncedUpdateWindowSize()
        }.store(in: &cancellables)

        // Observe assistant settings changes - use debounced updates
        Defaults.publisher(.enableScreenAssistant, options: []).sink { [weak self] _ in
            self?.debouncedUpdateWindowSize()
        }.store(in: &cancellables)

        Defaults.publisher(.showCpuGraph, options: []).sink { [weak self] _ in
            self?.debouncedUpdateWindowSize()
        }.store(in: &cancellables)

        Defaults.publisher(.showMemoryGraph, options: []).sink { [weak self] _ in
            self?.debouncedUpdateWindowSize()
        }.store(in: &cancellables)

        Defaults.publisher(.showGpuGraph, options: []).sink { [weak self] _ in
            self?.debouncedUpdateWindowSize()
        }.store(in: &cancellables)

        Defaults.publisher(.showNetworkGraph, options: []).sink { [weak self] _ in
            self?.debouncedUpdateWindowSize()
        }.store(in: &cancellables)

        Defaults.publisher(.showDiskGraph, options: []).sink { [weak self] _ in
            self?.debouncedUpdateWindowSize()
        }.store(in: &cancellables)

        // Observe minimalistic UI setting changes - trigger window resize
        Defaults.publisher(.enableMinimalisticUI, options: []).sink { [weak self] change in
            // Force sneak peek to standard mode when minimalistic UI is enabled
            if change.newValue == true && Defaults[.sneakPeekStyles] != .standard {
                Defaults[.sneakPeekStyles] = .standard
            }
            // Update window size IMMEDIATELY (no debouncing) to prevent position shift
            self?.updateWindowSizeIfNeeded()
        }.store(in: &cancellables)

        // Observe screen recording settings changes
        Defaults.publisher(.enableScreenRecordingDetection, options: []).sink { _ in
            if Defaults[.enableScreenRecordingDetection] {
                ScreenRecordingManager.shared.startMonitoring()
            } else {
                ScreenRecordingManager.shared.stopMonitoring()
            }
        }.store(in: &cancellables)

        // Note: Polling setting removed - now uses event-driven private API detection only

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            forName: Notification.Name.selectedScreenChanged, object: nil, queue: nil
        ) { [weak self] _ in
            self?.adjustWindowPosition(changeAlpha: true)
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name.notchHeightChanged, object: nil, queue: nil
        ) { [weak self] _ in
            self?.adjustWindowPosition()
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name.automaticallySwitchDisplayChanged, object: nil, queue: nil
        ) { [weak self] _ in
            guard let self = self, let window = self.window else { return }
            window.alphaValue =
                self.coordinator.selectedScreen == self.coordinator.preferredScreen ? 1 : 0
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name.showOnAllDisplaysChanged, object: nil, queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            self.cleanupWindows(shouldInvert: true)

            if !Defaults[.showOnAllDisplays] {
                let viewModel = self.vm
                let window = self.createDynamicIslandWindow(
                    for: NSScreen.main ?? NSScreen.screens.first!, with: viewModel)
                self.window = window
                self.adjustWindowPosition(changeAlpha: true)
            } else {
                self.adjustWindowPosition()
            }
        }

        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(onScreenLocked(_:)),
            name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"), object: nil)
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(onScreenUnlocked(_:)),
            name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"), object: nil)

        KeyboardShortcuts.onKeyDown(for: .toggleSneakPeek) { [weak self] in
            guard let self = self else { return }

            // Only execute if shortcuts are enabled
            guard Defaults[.enableShortcuts] else { return }

            self.coordinator.toggleSneakPeek(
                status: !self.coordinator.sneakPeek.show,
                type: .music,
                duration: 3.0
            )
        }

        KeyboardShortcuts.onKeyDown(for: .toggleNotchOpen) { [weak self] in
            guard let self = self else { return }

            // Only execute if shortcuts are enabled
            guard Defaults[.enableShortcuts] else { return }

            let mouseLocation = NSEvent.mouseLocation

            var viewModel = self.vm

            if Defaults[.showOnAllDisplays] {
                for screen in NSScreen.screens {
                    if screen.frame.contains(mouseLocation) {
                        if let screenViewModel = self.viewModels[screen] {
                            viewModel = screenViewModel
                            break
                        }
                    }
                }
            }

            self.closeNotchWorkItem?.cancel()
            self.closeNotchWorkItem = nil

            switch viewModel.notchState {
            case .closed:
                viewModel.open()

                let workItem = DispatchWorkItem { [weak viewModel] in
                    viewModel?.close()
                }
                self.closeNotchWorkItem = workItem

                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
            case .open:
                viewModel.close()
            }
        }

        KeyboardShortcuts.onKeyDown(for: .startDemoTimer) { [weak self] in
            guard let self = self else { return }

            // Only execute if shortcuts are enabled
            guard Defaults[.enableShortcuts] else { return }

            // Only start timer if the timer feature is enabled
            guard Defaults[.enableTimerFeature] else { return }

            // Start a 5-minute demo timer
            TimerManager.shared.startDemoTimer(duration: 300)
        }

        KeyboardShortcuts.onKeyDown(for: .clipboardHistoryPanel) { [weak self] in
            guard let self = self else { return }

            // Only execute if shortcuts are enabled
            guard Defaults[.enableShortcuts] else { return }

            // Only open clipboard if the feature is enabled
            guard Defaults[.enableClipboardManager] else { return }

            // Start clipboard monitoring if not already running
            if !ClipboardManager.shared.isMonitoring {
                ClipboardManager.shared.startMonitoring()
            }

            // Handle keyboard shortcut based on display mode
            switch Defaults[.clipboardDisplayMode] {
            case .panel:
                ClipboardPanelManager.shared.toggleClipboardPanel()
            case .popover:
                // For popover mode, first ensure notch is open, then toggle popover

                // If notch is closed, open it first
                if self.vm.notchState == .closed {
                    self.vm.open()
                    // Wait a moment for the notch to open, then show popover
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(name: NSNotification.Name("ToggleClipboardPopover"), object: nil)
                    }
                } else {
                    // Notch is already open, toggle popover immediately
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleClipboardPopover"), object: nil)
                }
            }
        }

        KeyboardShortcuts.onKeyDown(for: .colorPickerPanel) { [weak self] in
            guard let self = self else { return }

            // Only execute if shortcuts are enabled
            guard Defaults[.enableShortcuts] else { return }

            // Only open color picker panel if the feature is enabled
            guard Defaults[.enableColorPickerFeature] else { return }

            // Toggle color picker panel
            ColorPickerPanelManager.shared.toggleColorPickerPanel()
        }

        KeyboardShortcuts.onKeyDown(for: .screenAssistantPanel) { [weak self] in
            guard let self = self else { return }

            // Only execute if shortcuts are enabled
            guard Defaults[.enableShortcuts] else { return }

            // Only open screen assistant if the feature is enabled
            guard Defaults[.enableScreenAssistant] else { return }

            // Handle keyboard shortcut based on display mode
            switch Defaults[.screenAssistantDisplayMode] {
            case .panel:
                ScreenAssistantPanelManager.shared.toggleScreenAssistantPanel()
            case .notch:
                // For notch mode, first ensure notch is open, then toggle new view

                // If notch is closed, open it first
                if self.vm.notchState == .closed {
                    self.vm.open()
                    // Wait a moment for the notch to open, then show popover
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(name: NSNotification.Name("ToggleScreenAssistantPopover"), object: nil)
                    }
                } else {
                    // Notch is already open, toggle popover immediately
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleScreenAssistantPopover"), object: nil)
                }
            }
        }

        KeyboardShortcuts.onKeyDown(for: .statsPanel) { [weak self] in
            guard let self = self else { return }

            // Only execute if shortcuts are enabled
            guard Defaults[.enableShortcuts] else { return }

            // Only open stats panel if both stats feature and panel are enabled
            guard Defaults[.enableStatsFeature] && Defaults[.showStatsPanel] else { return }

            // Start stats monitoring if not already running
            if !StatsManager.shared.isMonitoring {
                StatsManager.shared.startMonitoring()
            }

            // Toggle stats panel
            StatsPanelManager.shared.toggleStatsPanel()
        }

        if !Defaults[.showOnAllDisplays] {
            let viewModel = self.vm
            let window = createDynamicIslandWindow(
                for: NSScreen.main ?? NSScreen.screens.first!, with: viewModel)
            self.window = window
            adjustWindowPosition(changeAlpha: true)
        } else {
            adjustWindowPosition(changeAlpha: true)
        }

        if coordinator.firstLaunch {
            DispatchQueue.main.async {
                self.showOnboardingWindow()
            }
            playWelcomeSound()
        }

        previousScreens = NSScreen.screens

        if Defaults[.enableLockScreenWeatherWidget] {
            LockScreenWeatherManager.shared.prepareLocationAccess()
            Task { @MainActor in
                await LockScreenWeatherManager.shared.refresh(force: true)
            }
        }
    }

    func playWelcomeSound() {
        let audioPlayer = AudioPlayer()
        audioPlayer.play(fileName: "dynamic", fileExtension: "m4a")
    }

    func deviceHasNotch() -> Bool {
        if #available(macOS 12.0, *) {
            for screen in NSScreen.screens {
                if screen.safeAreaInsets.top > 0 {
                    return true
                }
            }
        }
        return false
    }

    @objc func screenConfigurationDidChange() {
        let currentScreens = NSScreen.screens

        let screensChanged =
            currentScreens.count != previousScreens?.count
            || Set(currentScreens.map { $0.localizedName })
                != Set(previousScreens?.map { $0.localizedName } ?? [])
            || Set(currentScreens.map { $0.frame }) != Set(previousScreens?.map { $0.frame } ?? [])

        previousScreens = currentScreens

        if screensChanged {
            DispatchQueue.main.async { [weak self] in
                self?.cleanupWindows()
                self?.adjustWindowPosition()
            }
        }
    }

    @objc func adjustWindowPosition(changeAlpha: Bool = false) {
        if Defaults[.showOnAllDisplays] {
            let currentScreens = Set(NSScreen.screens)

            for screen in windows.keys where !currentScreens.contains(screen) {
                if let window = windows[screen] {
                    window.close()
                    NotchSpaceManager.shared.notchSpace.windows.remove(window)
                    windows.removeValue(forKey: screen)
                    viewModels.removeValue(forKey: screen)
                }
            }

            for screen in currentScreens {
                if windows[screen] == nil {
                    let viewModel = DynamicIslandViewModel(screen: screen.localizedName)
                    let window = createDynamicIslandWindow(for: screen, with: viewModel)

                    windows[screen] = window
                    viewModels[screen] = viewModel
                }

                if let window = windows[screen], let viewModel = viewModels[screen] {
                    positionWindow(window, on: screen, changeAlpha: changeAlpha)

                    if viewModel.notchState == .closed {
                        viewModel.close()
                    }
                }
            }
        } else {
            let selectedScreen: NSScreen

            if let preferredScreen = NSScreen.screens.first(where: {
                $0.localizedName == coordinator.preferredScreen
            }) {
                coordinator.selectedScreen = coordinator.preferredScreen
                selectedScreen = preferredScreen
            } else if Defaults[.automaticallySwitchDisplay], let mainScreen = NSScreen.main {
                coordinator.selectedScreen = mainScreen.localizedName
                selectedScreen = mainScreen
            } else {
                if let window = window {
                    window.alphaValue = 0
                }
                return
            }

            vm.screen = selectedScreen.localizedName
            vm.notchSize = getClosedNotchSize(screen: selectedScreen.localizedName)

            if window == nil {
                window = createDynamicIslandWindow(for: selectedScreen, with: vm)
            }

            if let window = window {
                positionWindow(window, on: selectedScreen, changeAlpha: changeAlpha)

                if vm.notchState == .closed {
                    vm.close()
                }
            }
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        if window?.isVisible == true {
            window?.orderOut(nil)
        } else {
            window?.orderFrontRegardless()
        }
    }

    @objc func showMenu() {
        statusItem?.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    @objc func quitAction() {
        NSApplication.shared.terminate(nil)
    }



    private func showOnboardingWindow() {
        if onboardingWindowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
                styleMask: [.titled, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Onboarding"
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.contentView = NSHostingView(rootView: OnboardingView(
                onFinish: {
                    window.orderOut(nil)
                    NSApp.setActivationPolicy(.accessory)
                    window.close()
                    NSApp.deactivate()
                },
                onOpenSettings: {
                    window.close()
                    SettingsWindowController.shared.showWindow()
                }
            ))
            window.isRestorable = false
            window.identifier = NSUserInterfaceItemIdentifier("OnboardingWindow")

            onboardingWindowController = NSWindowController(window: window)
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindowController?.window?.makeKeyAndOrderFront(nil)
        onboardingWindowController?.window?.orderFrontRegardless()
    }
}

extension Notification.Name {
    static let selectedScreenChanged = Notification.Name("SelectedScreenChanged")
    static let notchHeightChanged = Notification.Name("NotchHeightChanged")
    static let showOnAllDisplaysChanged = Notification.Name("showOnAllDisplaysChanged")
    static let automaticallySwitchDisplayChanged = Notification.Name("automaticallySwitchDisplayChanged")
}

extension CGRect: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin.x)
        hasher.combine(origin.y)
        hasher.combine(size.width)
        hasher.combine(size.height)
    }

    public static func == (lhs: CGRect, rhs: CGRect) -> Bool {
        return lhs.origin == rhs.origin && lhs.size == rhs.size
    }
}
