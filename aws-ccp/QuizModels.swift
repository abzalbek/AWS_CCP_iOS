//
//  QuizModels.swift
//  aws-ccp
//

import Foundation

struct ChoiceQuestion: Hashable {
    let id: String
    let question: String
    let module: String
    let options: [String]
    let correctIndices: Set<Int>

    var isMultiSelect: Bool { correctIndices.count > 1 }
}

struct MatchingPair: Hashable {
    let term: String
    let definition: String
}

struct MatchingQuestion: Hashable {
    let id: String
    let question: String
    let module: String
    let pairs: [MatchingPair]
}

enum QuizItem: Identifiable, Hashable {
    case choice(ChoiceQuestion)
    case matching(MatchingQuestion)

    var id: String {
        switch self {
        case .choice(let q): return q.id
        case .matching(let q): return q.id
        }
    }

    var question: String {
        switch self {
        case .choice(let q): return q.question
        case .matching(let q): return q.question
        }
    }

    var module: String {
        switch self {
        case .choice(let q): return q.module
        case .matching(let q): return q.module
        }
    }
}
