import SwiftUI

let ITEM_SELECTED_COLOR = Color("ItemSelectedColor")

struct HoverBackgroundModifier: ViewModifier {
    var isHovered: Bool

    func body(content: Content) -> some View {
        content
            .background(isHovered ? ITEM_SELECTED_COLOR : Color.clear)
    }
}

struct HoverRadiusBackgroundModifier: ViewModifier {
    var isHovered: Bool
    var hoverColor: Color?
    var cornerRadius: CGFloat = 0
    var showBorder: Bool = false
    var borderColor: Color = .white.opacity(0.07)
    var borderWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isHovered ? hoverColor ?? ITEM_SELECTED_COLOR : Color.clear)
            )
            .overlay(
                Group {
                    if isHovered && showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    }
                }
            )
    }
}

struct HoverForegroundModifier: ViewModifier {
    var isHovered: Bool
    var defaultColor: Color

    func body(content: Content) -> some View {
        content.foregroundColor(isHovered ? Color.white : defaultColor)
    }
}

extension View {
    public func hoverBackground(isHovered: Bool) -> some View {
        self.modifier(HoverBackgroundModifier(isHovered: isHovered))
    }

    public func hoverRadiusBackground(isHovered: Bool, cornerRadius: CGFloat) -> some View {
        self.modifier(HoverRadiusBackgroundModifier(isHovered: isHovered, cornerRadius: cornerRadius))
    }

    public func hoverRadiusBackground(isHovered: Bool, hoverColor: Color?, cornerRadius: CGFloat) -> some View {
        self.modifier(HoverRadiusBackgroundModifier(isHovered: isHovered, hoverColor: hoverColor, cornerRadius: cornerRadius))
    }
    
    public func hoverRadiusBackground(isHovered: Bool, hoverColor: Color?, cornerRadius: CGFloat, showBorder: Bool) -> some View {
        self.modifier(HoverRadiusBackgroundModifier(isHovered: isHovered, hoverColor: hoverColor, cornerRadius: cornerRadius, showBorder: showBorder))
    }

    public func hoverForeground(isHovered: Bool, defaultColor: Color) -> some View {
        self.modifier(HoverForegroundModifier(isHovered: isHovered, defaultColor: defaultColor))
    }

    public func hoverPrimaryForeground(isHovered: Bool) -> some View {
        self.hoverForeground(isHovered: isHovered, defaultColor: .primary)
    }

    public func hoverSecondaryForeground(isHovered: Bool) -> some View {
        self.hoverForeground(isHovered: isHovered, defaultColor: .secondary)
    }
}
