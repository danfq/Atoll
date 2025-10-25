//
//  ChatPanels.swift
//  DynamicIsland
//
//  Created by DanFQ

import AppKit
import SwiftUI
import Defaults

// MARK: - Screenshot Options Popover (Hidden from Screen Recording)
struct ScreenshotOptionsPopover: View {
    let onOptionSelected: (ScreenshotSnippingTool.ScreenshotType) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("Screenshot Type")
                .font(.headline)
                .padding(.top, 8)

            VStack(spacing: 4) {
                ScreenshotOptionButton(
                    type: .area,
                    description: "Select an area",
                    onTap: onOptionSelected
                )

                ScreenshotOptionButton(
                    type: .window,
                    description: "Select a window",
                    onTap: onOptionSelected
                )

                ScreenshotOptionButton(
                    type: .full,
                    description: "Capture full screen",
                    onTap: onOptionSelected
                )
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 12)
        .frame(width: 200)
        .background(
            ScreenshotPopoverBackground()
        )
    }
}
