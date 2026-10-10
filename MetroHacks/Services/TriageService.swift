import Foundation
import NaturalLanguage

struct TriageSuggestion {
    let category: IncidentCategory?
    let severity: Severity
    let team: ResponseTeam?
    let reasons: [String]
}

/// On-device auto-triage. Reads the free-text note and suggests category, severity and
/// the team to route to. Uses Apple's NaturalLanguage lemmatizer, so it works fully offline.
enum TriageService {
    private static let highStems = [
        "fire", "smok", "spark", "stuck", "trap", "injur", "fell", "fall", "collaps", "block",
        "emergenc", "electr", "shock", "stampede", "overcrowd", "offline", "outage", "stop",
        "broken", "leak", "flood", "unsafe"
    ]
    private static let mediumStems = [
        "slow", "nois", "grind", "wrong", "spill", "wet", "flicker", "overflow", "queue",
        "delay", "crowd", "jam", "dirty", "error", "intermittent", "loose", "dim", "smell"
    ]

    // Order matters: earlier categories win ties.
    private static let categoryStems: [(IncidentCategory, [String])] = [
        (.safety, ["fire", "smok", "injur", "unsafe", "exit", "slip", "wet", "tile", "railing", "emergenc", "spark", "shock", "fell", "fall", "trap"]),
        (.escalator, ["escalat", "lift", "elevator", "stair", "handrail", "step"]),
        (.ticketGate, ["gate", "qr", "card", "fare", "ticket", "token", "reader", "turnstile"]),
        (.lighting, ["light", "lamp", "dark", "dim", "bulb", "flicker"]),
        (.crowding, ["crowd", "queue", "rush", "packed", "overcrowd", "congest"]),
        (.cleanliness, ["clean", "spill", "garbage", "bin", "dirty", "toilet", "restroom", "smell", "trash"])
    ]

    static func suggest(from note: String) -> TriageSuggestion? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return nil }

        let tokens = tokenize(trimmed)

        func matches(_ stems: [String]) -> [String] {
            var found: [String] = []
            for stem in stems {
                if let token = tokens.first(where: { $0.hasPrefix(stem) }), !found.contains(token) {
                    found.append(token)
                }
            }
            return found
        }

        let highHits = matches(highStems)
        let mediumHits = matches(mediumStems)

        var bestCategory: IncidentCategory?
        var bestHits: [String] = []
        for (category, stems) in categoryStems {
            let hits = matches(stems)
            if hits.count > bestHits.count {
                bestCategory = category
                bestHits = hits
            }
        }

        let severity: Severity
        if !highHits.isEmpty { severity = .high }
        else if !mediumHits.isEmpty { severity = .medium }
        else { severity = .low }

        var reasons: [String] = []
        for word in highHits + mediumHits + bestHits where !reasons.contains(word) {
            reasons.append(word)
        }
        guard bestCategory != nil || !highHits.isEmpty || !mediumHits.isEmpty else { return nil }

        return TriageSuggestion(
            category: bestCategory,
            severity: severity,
            team: bestCategory.map(ResponseTeam.suggested(for:)),
            reasons: Array(reasons.prefix(4))
        )
    }

    /// Lowercased words plus their lemmas ("stopped" -> "stop").
    private static func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lemma,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            let word = String(text[range]).lowercased()
            if !tokens.contains(word) { tokens.append(word) }
            if let lemma = tag?.rawValue.lowercased(), !tokens.contains(lemma) { tokens.append(lemma) }
            return true
        }
        return tokens
    }
}
