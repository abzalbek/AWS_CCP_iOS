//
//  QuizView.swift
//  aws-ccp
//

import SwiftUI

private func canSubmitChoice(displayCorrect: Set<Int>, selected: Set<Int>) -> Bool {
    selected.count == displayCorrect.count && !selected.isEmpty
}

private func canSubmitMatching(_ selections: [Int?]) -> Bool {
    !selections.isEmpty && selections.allSatisfy { $0 != nil }
}

struct QuizView: View {
    /// `nil` means include every question.
    var moduleFilter: String?
    var onExitToHome: () -> Void

    @State private var questions: [QuizItem]?
    @State private var loadError: String?
    @State private var roundOrder: [QuizItem] = []
    @State private var roundIndex = 0
    @State private var selectedIndices: Set<Int> = []
    @State private var revealed = false

    private var subtitle: String {
        if let moduleFilter, !moduleFilter.isEmpty { return moduleFilter }
        return QuizModules.allQuestions
    }

    private var current: QuizItem? {
        guard roundIndex >= 0, roundIndex < roundOrder.count else { return nil }
        return roundOrder[roundIndex]
    }

    private func filteredBank(_ loaded: [QuizItem]) -> [QuizItem] {
        guard let moduleFilter, !moduleFilter.isEmpty else { return loaded }
        return loaded.filter { $0.module == moduleFilter }
    }

    private func applyFilterAndShuffle() {
        guard let loaded = questions else { return }
        let bank = filteredBank(loaded)
        if bank.isEmpty {
            roundOrder = []
            roundIndex = 0
            revealed = false
            selectedIndices = []
            return
        }
        roundOrder = bank.shuffled()
        roundIndex = 0
        revealed = false
        selectedIndices = []
    }

    var body: some View {
        VStack(spacing: 0) {
            quizHeader
            Rectangle()
                .fill(AWSQuizColors.orange)
                .frame(height: 3)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !roundOrder.isEmpty {
                        let progress = Double(roundIndex + 1) / Double(roundOrder.count)
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(AWSQuizColors.orange)
                        Text("Question \(roundIndex + 1) of \(roundOrder.count)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AWSQuizColors.textSecondary)
                    }

                    if roundIndex > 0 && !roundOrder.isEmpty {
                        Button("← Previous question") {
                            roundIndex -= 1
                            revealed = false
                            selectedIndices = []
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AWSQuizColors.linkBlue)
                    }

                    contentBody
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AWSQuizColors.pageBackground)
        .task {
            do {
                questions = try QuizRepository.loadQuestions()
            } catch {
                loadError = error.localizedDescription
            }
        }
        .onChange(of: questions) { _, new in
            if new != nil { applyFilterAndShuffle() }
        }
        .onChange(of: moduleFilter) { _, _ in
            if questions != nil { applyFilterAndShuffle() }
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        if let loadError {
            Text("Could not load questions: \(loadError)")
                .foregroundStyle(Color.red)
        } else if questions == nil {
            HStack {
                Spacer()
                ProgressView()
                    .tint(AWSQuizColors.orange)
                Spacer()
            }
        } else if current == nil {
            let loaded = questions ?? []
            let bank = filteredBank(loaded)
            if loaded.isEmpty {
                Text("No questions in the bank yet. Add entries to questions.json.")
            } else if bank.isEmpty {
                Text("No questions for this module yet.")
                    .foregroundStyle(AWSQuizColors.textSecondary)
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(AWSQuizColors.orange)
                    Spacer()
                }
            }
        } else if let item = current {
            switch item {
            case .choice(let q):
                ChoiceQuestionContent(
                    q: q,
                    roundIndex: roundIndex,
                    roundOrder: roundOrder,
                    selectedIndices: $selectedIndices,
                    revealed: $revealed,
                    onNext: { advanceChoice() }
                )
            case .matching(let mq):
                MatchingQuestionContent(
                    mq: mq,
                    roundIndex: roundIndex,
                    roundOrder: roundOrder,
                    revealed: $revealed,
                    onNext: { advanceMatching() }
                )
            }
        }
    }

    private func advanceChoice() {
        guard let loaded = questions else { return }
        let bank = filteredBank(loaded)
        guard !bank.isEmpty else { return }
        revealed = false
        selectedIndices = []
        let next = roundIndex + 1
        if next >= roundOrder.count {
            roundOrder = bank.shuffled()
            roundIndex = 0
        } else {
            roundIndex = next
        }
    }

    private func advanceMatching() {
        guard let loaded = questions else { return }
        let bank = filteredBank(loaded)
        guard !bank.isEmpty else { return }
        revealed = false
        let next = roundIndex + 1
        if next >= roundOrder.count {
            roundOrder = bank.shuffled()
            roundIndex = 0
        } else {
            roundIndex = next
        }
    }

    private var quizHeader: some View {
        ZStack {
            HStack {
                Button("Home") {
                    onExitToHome()
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AWSQuizColors.orange)
                Spacer(minLength: 0)
            }
            Text(subtitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 72)
        }
        .frame(minHeight: 44, maxHeight: 56)
        .padding(.horizontal, 8)
        .background(AWSQuizColors.squidInk)
    }
}

// MARK: - Choice

private struct ChoiceQuestionContent: View {
    let q: ChoiceQuestion
    let roundIndex: Int
    let roundOrder: [QuizItem]
    @Binding var selectedIndices: Set<Int>
    @Binding var revealed: Bool
    var onNext: () -> Void

    @State private var optionPermutation: [Int] = []

    private var shuffleKey: String {
        "\(q.id)|\(roundIndex)|\(roundOrder.map(\.id).joined(separator: ","))"
    }

    private var displayCorrectIndices: Set<Int> {
        Set(optionPermutation.indices.filter { q.correctIndices.contains(optionPermutation[$0]) })
    }

    private var isMultiSelect: Bool { displayCorrectIndices.count > 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(q.question)
                .font(.headline.weight(.medium))
                .foregroundStyle(AWSQuizColors.textPrimary)

            ForEach(Array(optionPermutation.enumerated()), id: \.offset) { displayPos, originalIndex in
                let option = q.options[originalIndex]
                let isSelected = selectedIndices.contains(displayPos)
                let showResult = revealed
                let isCorrect = displayCorrectIndices.contains(displayPos)
                let container = choiceBackground(showResult: showResult, isCorrect: isCorrect, isSelected: isSelected)

                Button {
                    guard !revealed else { return }
                    if isMultiSelect {
                        if selectedIndices.contains(displayPos) {
                            selectedIndices.remove(displayPos)
                        } else {
                            selectedIndices.insert(displayPos)
                        }
                    } else {
                        selectedIndices = [displayPos]
                    }
                } label: {
                    HStack(alignment: .center, spacing: 8) {
                        if isMultiSelect {
                            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                .foregroundStyle(isSelected ? AWSQuizColors.orange : AWSQuizColors.textSecondary)
                        } else {
                            Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                                .foregroundStyle(isSelected ? AWSQuizColors.orange : AWSQuizColors.textSecondary)
                        }
                        Text(option)
                            .font(.body)
                            .foregroundStyle(AWSQuizColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if showResult {
                            if isCorrect {
                                Text("Correct")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AWSQuizColors.orange)
                            } else if isSelected {
                                Text("Incorrect")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.red)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(container)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
                .disabled(revealed)
            }

            HStack(spacing: 12) {
                Button("Check answer") {
                    revealed = true
                }
                .buttonStyle(.borderedProminent)
                .tint(AWSQuizColors.orange)
                .disabled(!canSubmitChoice(displayCorrect: displayCorrectIndices, selected: selectedIndices) || revealed)
                .frame(maxWidth: .infinity)

                Button("Next") {
                    onNext()
                }
                .buttonStyle(.bordered)
                .tint(AWSQuizColors.orange)
                .frame(maxWidth: .infinity)
            }
        }
        .task(id: shuffleKey) {
            optionPermutation = Array(q.options.indices).shuffled()
        }
    }

    private func choiceBackground(showResult: Bool, isCorrect: Bool, isSelected: Bool) -> Color {
        if !showResult { return AWSQuizColors.surface }
        if isCorrect { return Color(red: 1, green: 0.957, blue: 0.898) }
        if isSelected && !isCorrect { return Color(red: 1, green: 0.898, blue: 0.898) }
        return AWSQuizColors.pageBackground
    }
}

// MARK: - Matching

private struct MatchingQuestionContent: View {
    let mq: MatchingQuestion
    let roundIndex: Int
    let roundOrder: [QuizItem]
    @Binding var revealed: Bool
    var onNext: () -> Void

    @State private var definitionOrder: [Int] = []
    @State private var matchSelections: [Int?] = []

    private var shuffleKey: String {
        "\(mq.id)|\(roundIndex)|\(roundOrder.map(\.id).joined(separator: ","))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mq.question)
                .font(.headline.weight(.medium))
                .foregroundStyle(AWSQuizColors.textPrimary)
            Text("For each service, choose the matching definition.")
                .font(.caption)
                .foregroundStyle(AWSQuizColors.textSecondary)

            ForEach(Array(mq.pairs.enumerated()), id: \.offset) { termIndex, pair in
                let selectedDefIndex = termIndex < matchSelections.count ? matchSelections[termIndex] : nil
                let rowCorrect = selectedDefIndex == termIndex
                let showResult = revealed
                let container = matchBackground(
                    showResult: showResult,
                    rowCorrect: rowCorrect,
                    hasSelection: selectedDefIndex != nil
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(pair.term)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AWSQuizColors.textPrimary)

                    Menu {
                        ForEach(definitionOrder, id: \.self) { defIndex in
                            Button(mq.pairs[defIndex].definition) {
                                guard termIndex < matchSelections.count else { return }
                                matchSelections[termIndex] = defIndex
                            }
                        }
                    } label: {
                        HStack {
                            Text(menuLabel(selectedDefIndex: selectedDefIndex))
                                .font(.caption)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(AWSQuizColors.linkBlue)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundStyle(AWSQuizColors.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AWSQuizColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AWSQuizColors.outline, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(revealed)

                    if showResult {
                        Text(rowCorrect ? "Correct" : "Incorrect")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(rowCorrect ? AWSQuizColors.orange : Color.red)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(container)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
            }

            HStack(spacing: 12) {
                Button("Check answer") {
                    revealed = true
                }
                .buttonStyle(.borderedProminent)
                .tint(AWSQuizColors.orange)
                .disabled(!canSubmitMatching(matchSelections) || revealed)
                .frame(maxWidth: .infinity)

                Button("Next") {
                    onNext()
                }
                .buttonStyle(.bordered)
                .tint(AWSQuizColors.orange)
                .frame(maxWidth: .infinity)
            }
        }
        .task(id: shuffleKey) {
            definitionOrder = mq.pairs.indices.shuffled()
            matchSelections = Array(repeating: nil, count: mq.pairs.count)
        }
    }

    private func menuLabel(selectedDefIndex: Int?) -> String {
        guard let selectedDefIndex else { return "Select definition…" }
        return mq.pairs[selectedDefIndex].definition
    }

    private func matchBackground(showResult: Bool, rowCorrect: Bool, hasSelection: Bool) -> Color {
        if !showResult { return AWSQuizColors.surface }
        if rowCorrect { return Color(red: 1, green: 0.957, blue: 0.898) }
        if hasSelection && !rowCorrect { return Color(red: 1, green: 0.898, blue: 0.898) }
        return AWSQuizColors.pageBackground
    }
}

#Preview {
    QuizView(moduleFilter: nil, onExitToHome: {})
}
