//
//  HomeView.swift
//  aws-ccp
//

import SwiftUI

struct HomeView: View {
    var onModuleSelected: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle()
                .fill(AWSQuizColors.orange)
                .frame(height: 3)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose a module")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AWSQuizColors.textPrimary)
                        .padding(.top, 8)
                    Text("Practice questions grouped by topic. Your progress resets when you leave a session.")
                        .font(.body)
                        .foregroundStyle(AWSQuizColors.textSecondary)
                        .padding(.bottom, 8)

                    ForEach(QuizModules.homeOrder, id: \.self) { title in
                        Button {
                            onModuleSelected(title)
                        } label: {
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(AWSQuizColors.orange)
                                    .frame(width: 4)
                                Text(title)
                                    .font(.body)
                                    .foregroundStyle(AWSQuizColors.textPrimary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 18)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AWSQuizColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AWSQuizColors.outline.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AWSQuizColors.pageBackground)
    }

    private var header: some View {
        HStack {
            Text("AWS CCP Quiz")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 44, maxHeight: 44)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(AWSQuizColors.squidInk)
    }
}

#Preview {
    HomeView(onModuleSelected: { _ in })
}
