//
//  AWSQuizTheme.swift
//  aws-ccp
//

import SwiftUI

enum AWSQuizColors {
    static let orange = Color(red: 1, green: 0.6, blue: 0)
    static let orangePressed = Color(red: 0.925, green: 0.447, blue: 0.067)
    static let squidInk = Color(red: 0.137, green: 0.184, blue: 0.243)
    static let pageBackground = Color(red: 0.949, green: 0.953, blue: 0.953)
    static let surface = Color.white
    static let outline = Color(red: 0.835, green: 0.859, blue: 0.859)
    static let linkBlue = Color(red: 0, green: 0.451, blue: 0.733)
    static let textPrimary = Color(red: 0.086, green: 0.098, blue: 0.122)
    static let textSecondary = Color(red: 0.329, green: 0.357, blue: 0.392)
}

struct AWSQuizTheme: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .tint(AWSQuizColors.orange)
            .background(backgroundColor)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.071, green: 0.086, blue: 0.110) : AWSQuizColors.pageBackground
    }
}

extension View {
    func awsQuizTheme() -> some View {
        modifier(AWSQuizTheme())
    }
}
