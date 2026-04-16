//
//  QuizModules.swift
//  aws-ccp
//

import Foundation

enum QuizModules {
    /// Use `nil` as `QuizView` filter for all questions.
    static let allQuestions = "All Questions"

    static let homeOrder: [String] = [
        allQuestions,
        "Compute in the Cloud",
        "Going Global",
        "Networking",
        "Storage",
        "Databases",
        "AI ML and Data Analytics",
        "Security",
        "Monitoring, Compliance and Governance in the AWS Cloud",
        "Pricing and Support",
        "Migrating to the AWS Cloud",
        "Well-Architected Solutions",
    ]
}
