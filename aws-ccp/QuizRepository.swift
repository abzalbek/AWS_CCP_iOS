//
//  QuizRepository.swift
//  aws-ccp
//

import Foundation

enum QuizRepositoryError: LocalizedError {
    case missingAsset
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .missingAsset: return "questions.json not found in bundle"
        case .invalidFormat: return "Invalid questions JSON"
        }
    }
}

enum QuizRepository {
    private static let assetName = "questions"
    private static let assetExtension = "json"

    static func loadQuestions() throws -> [QuizItem] {
        guard let url = Bundle.main.url(forResource: assetName, withExtension: assetExtension) else {
            throw QuizRepositoryError.missingAsset
        }
        let data = try Data(contentsOf: url)
        let obj = try JSONSerialization.jsonObject(with: data)
        guard let root = obj as? [String: Any],
              let array = root["questions"] as? [[String: Any]] else {
            throw QuizRepositoryError.invalidFormat
        }
        return try array.map { try parseQuestion($0) }
    }

    private static func parseQuestion(_ o: [String: Any]) throws -> QuizItem {
        guard let id = o["id"] as? String,
              let question = o["question"] as? String else {
            throw QuizRepositoryError.invalidFormat
        }
        let module = o["module"] as? String ?? ""
        let typeStr = o["type"] as? String ?? ""
        let isMatching = typeStr == "matching" || o["matchingPairs"] != nil

        if isMatching {
            guard let arr = o["matchingPairs"] as? [[String: Any]], !arr.isEmpty else {
                throw QuizRepositoryError.invalidFormat
            }
            let pairs: [MatchingPair] = try arr.map { p in
                guard let term = p["term"] as? String,
                      let definition = p["definition"] as? String else {
                    throw QuizRepositoryError.invalidFormat
                }
                return MatchingPair(term: term, definition: definition)
            }
            return .matching(
                MatchingQuestion(id: id, question: question, module: module, pairs: pairs)
            )
        }

        guard let opts = o["options"] as? [String] else {
            throw QuizRepositoryError.invalidFormat
        }
        let correct = parseCorrectIndices(o)
        guard !correct.isEmpty else {
            throw QuizRepositoryError.invalidFormat
        }
        return .choice(
            ChoiceQuestion(
                id: id,
                question: question,
                module: module,
                options: opts,
                correctIndices: correct
            )
        )
    }

    private static func parseCorrectIndices(_ o: [String: Any]) -> Set<Int> {
        if let arr = o["correctIndices"] as? [Any] {
            let ints = arr.compactMap { any -> Int? in
                if let i = any as? Int { return i }
                if let n = any as? NSNumber { return n.intValue }
                return nil
            }
            return Set(ints)
        }
        if let idx = o["correctIndex"] as? Int {
            return [idx]
        }
        if let n = o["correctIndex"] as? NSNumber {
            return [n.intValue]
        }
        return []
    }
}
