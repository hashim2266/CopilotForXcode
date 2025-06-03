import SwiftUI

public struct CardGroupBoxStyle: GroupBoxStyle {
    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            configuration.label.foregroundColor(.primary)
            configuration.content.foregroundColor(.primary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color("GroupBoxBackgroundColor"))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .inset(by: 0.5)
                .stroke(Color("GroupBoxStrokeColor"), lineWidth: 1)
        )
    }
}
