//
//  FlowLayout.swift
//  TaskSheet
//
//  Created by Claude Code on 15/10/2025.
//

import SwiftUI

@available(iOS 16.0, *)
struct FlowLayout: Layout {
    let alignment: HorizontalAlignment
    let spacing: CGFloat

    init(alignment: HorizontalAlignment = .leading, spacing: CGFloat = 8) {
        self.alignment = alignment
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
}

@available(iOS 16.0, *)
private struct FlowResult {
    let bounds: CGSize
    let positions: [CGPoint]

    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var positions: [CGPoint] = []
        var currentRowY: CGFloat = 0
        var currentRowX: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Check if we need to wrap to next row
            if currentRowX + size.width > maxWidth && currentRowX > 0 {
                // Move to next row
                currentRowY += currentRowHeight + spacing
                currentRowX = 0
                currentRowHeight = 0
            }

            positions.append(CGPoint(x: currentRowX, y: currentRowY))

            currentRowX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }

        self.positions = positions
        self.bounds = CGSize(
            width: maxWidth,
            height: currentRowY + currentRowHeight
        )
    }
}
