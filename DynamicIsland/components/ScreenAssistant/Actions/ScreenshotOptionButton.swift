//
//  ChatPanels.swift
//  DynamicIsland
//
//  Created by DanFQ

import AppKit
import SwiftUI
import Defaults

// MARK: - Screenshot Option Button
struct ScreenshotOptionButton: View {
    let type: ScreenshotSnippingTool.ScreenshotType
    let description: String
    let onTap: (ScreenshotSnippingTool.ScreenshotType) -> Void

    var body: some View {
        Button(action: { onTap(type) }) {
            HStack(spacing: 12) {
                Image(systemName: type.iconName)
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 20, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
                    .contentShape(Rectangle())
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor))
                .opacity(0.5)
        )
        .onHover { isHovered in
            // Add subtle hover effect if needed
        }
    }
}
