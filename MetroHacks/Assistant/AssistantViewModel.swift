import Foundation
import Observation
import SwiftUI

struct ChatChip: Identifiable {
    let id = UUID()
    let title: String
    /// Command handled by the assistant. Prefixes: "stn:" station for a report, "sts:" station status,
    /// "rpt:" start a report at a station, "cat:" category. "__x" are plain intents.
    let payload: String
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    var chips: [ChatChip] = []
}

/// On-device assistant. No network, no API key: it understands English / Gujarati / Hindi keywords
/// (plus Apple's NaturalLanguage triage) and performs the same actions as the app screens:
/// file a report, check a station, find the nearest station.
@Observable
@MainActor
final class AssistantViewModel {
    private(set) var messages: [ChatMessage] = []
    private(set) var isBusy = false
    var input = ""

    private enum Awaiting { case station, category, statusStation }
    private var awaiting: Awaiting?
    private var draftStation: String?
    private var draftCategory: IncidentCategory?
    private var draftNote = ""

    private let listViewModel: IncidentListViewModel
    private let location = LocationService()
    private let resolver = StationResolver()

    init(listViewModel: IncidentListViewModel) {
        self.listViewModel = listViewModel
        messages = [greeting()]
    }

    /// Starts a fresh conversation (also re-translates the greeting after a language change).
    func reset() {
        resetDraft()
        withAnimation { messages = [greeting()] }
    }

    // MARK: - Input

    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isBusy else { return }
        input = ""
        Task { await handle(text: text, display: text) }
    }

    func tap(_ chip: ChatChip) {
        guard !isBusy else { return }
        Task { await handle(text: chip.payload, display: chip.title) }
    }

    private func handle(text: String, display: String) async {
        withAnimation(.spring(duration: 0.35)) { messages.append(ChatMessage(isUser: true, text: display)) }
        isBusy = true
        try? await Task.sleep(for: .milliseconds(350)) // lets the typing dots show
        let reply = await respond(to: text)
        withAnimation(.spring(duration: 0.35)) {
            messages.append(reply)
            isBusy = false
        }
    }

    // MARK: - Brain

    private func respond(to text: String) async -> ChatMessage {
        // Chip commands
        if text.hasPrefix("stn:") { return applyStation(String(text.dropFirst(4))) }
        if text.hasPrefix("sts:") { awaiting = nil; return status(for: String(text.dropFirst(4))) }
        if text.hasPrefix("rpt:") {
            resetDraft()
            draftStation = String(text.dropFirst(4))
            return continueReport()
        }
        if text.hasPrefix("cat:") {
            if let category = IncidentCategory(rawValue: String(text.dropFirst(4))) { draftCategory = category }
            awaiting = nil
            return continueReport()
        }
        switch text {
        case "__report": resetDraft(); return continueReport()
        case "__status": awaiting = .statusStation; return ask("Which station do you want to check?", chips: locationChip())
        case "__nearest": return await nearest()
        case "__issues": return allStatus()
        case "__loc": return await useLocation()
        default: break
        }

        let lower = text.lowercased()
        let station = findStation(lower)
        let category = detectCategory(text)

        if isCancel(lower) {
            resetDraft()
            return say("Okay, cancelled. Anything else?", chips: mainChips())
        }

        // Answering a question I asked
        switch awaiting {
        case .station:
            if let station { return applyStation(station) }
            if wantsLocation(lower) { return await useLocation() }
            return ask("I couldn't find that station. Please type it again or use your location.", chips: locationChip())
        case .statusStation:
            if let station { awaiting = nil; return status(for: station) }
            if wantsLocation(lower) { return await useLocation() }
            return ask("I couldn't find that station. Please type it again or use your location.", chips: locationChip())
        case .category:
            if let category {
                draftCategory = category
                if draftNote.isEmpty { draftNote = text }
                awaiting = nil
                return continueReport()
            }
            return ask("I didn't catch the problem. Please pick one:", chips: categoryChips())
        case nil:
            break
        }

        // Fresh requests
        if has(lower, Self.issuesWords), station == nil, category == nil { return allStatus() }
        if has(lower, Self.nearestWords) { return await nearest() }
        if has(lower, Self.statusWords) {
            if let station { return status(for: station) }
            awaiting = .statusStation
            return ask("Which station do you want to check?", chips: locationChip())
        }
        if category != nil || has(lower, Self.reportWords) {
            resetDraft()
            draftStation = station
            draftCategory = category
            draftNote = text
            if station == nil, wantsLocation(lower) { return await useLocation() }
            return continueReport()
        }
        if let station { return status(for: station) }
        if has(lower, Self.greetWords) { return greeting() }
        return say("Sorry, I didn't get that. Try “escalator not working at Gandhigram” or tap an option.", chips: mainChips())
    }

    // MARK: - Actions

    private func continueReport() -> ChatMessage {
        guard let station = draftStation else {
            awaiting = .station
            return ask("Which station are you at? Type its name or use your location.", chips: locationChip())
        }
        guard let category = draftCategory else {
            awaiting = .category
            return ask("What's the problem?", chips: categoryChips())
        }
        awaiting = nil

        let form = AddIncidentViewModel(
            repository: listViewModel.repository,
            source: .passenger,
            onSaved: { [listViewModel] in
                listViewModel.load()
                Task { await listViewModel.syncPending() }
            }
        )
        form.station = station
        form.category = category
        form.note = draftNote
        form.save()
        resetDraft()

        guard let result = form.submitted else {
            return say("Sorry, I didn't get that. Try “escalator not working at Gandhigram” or tap an option.", chips: mainChips())
        }
        if let merged = result.mergedCount {
            return say(trf("Added to an existing report at %2$@ — %1$d passengers have reported this.", merged, tr(station)),
                       chips: mainChips())
        }
        return say(
            trf("Done! I reported “%1$@” at %2$@. Priority: %3$@ · Routed to %4$@.",
                category.localizedTitle, tr(station), result.severity.localizedTitle,
                result.team?.localizedName ?? "—"),
            chips: mainChips()
        )
    }

    private func applyStation(_ name: String) -> ChatMessage {
        if awaiting == .statusStation {
            awaiting = nil
            return status(for: name)
        }
        draftStation = name
        if awaiting == .station { awaiting = nil }
        return continueReport()
    }

    private func status(for station: String) -> ChatMessage {
        let key = StationDirectory.key(station)
        let active = listViewModel.incidents.filter {
            $0.status != .resolved && StationDirectory.key($0.station) == key
        }
        let chips = [ChatChip(title: trf("Report at %@", tr(station)), payload: "rpt:" + station)] + mainChips()
        guard !active.isEmpty else {
            return say(trf("%@ is running normally. No known issues.", tr(station)), chips: chips)
        }
        var seen = Set<IncidentCategory>()
        let lines = active.compactMap { incident -> String? in
            guard seen.insert(incident.category).inserted else { return nil }
            return "• " + incident.category.passengerMessage
        }
        return say(trf("%@ has issues right now:", tr(station)) + "\n" + lines.joined(separator: "\n"), chips: chips)
    }

    private func allStatus() -> ChatMessage {
        var names: [String: String] = [:]
        for incident in listViewModel.incidents where incident.status != .resolved {
            names[StationDirectory.key(incident.station)] = incident.station
        }
        guard !names.isEmpty else { return say("All stations are running normally.", chips: mainChips()) }
        let list = names.values.sorted().prefix(5).map { tr($0) }.joined(separator: ", ")
        return say(trf("%d stations have issues: %@", names.count, list), chips: mainChips())
    }

    private func nearest() async -> ChatMessage {
        guard let found = await locate() else {
            return say(location.isDeniedNow ? "Location is off for this app. Opening Settings — allow it there, then try again."
                                            : "Couldn't get your location. Please type your station name.", chips: mainChips())
        }
        let chips = [ChatChip(title: trf("Status of %@", tr(found.name)), payload: "sts:" + found.name),
                     ChatChip(title: trf("Report at %@", tr(found.name)), payload: "rpt:" + found.name)]
        let text = found.isNearby
            ? trf("Your nearest station is %@ (%@).", tr(found.name), found.distanceText)
            : trf("No metro station within 2 km. The nearest is %@ (%@).", tr(found.name), found.distanceText)
        return say(text, chips: chips)
    }

    /// "Use my location" while a question is pending: fills the station for that question.
    private func useLocation() async -> ChatMessage {
        guard let found = await locate() else {
            return ask(location.isDeniedNow ? "Location is off for this app. Opening Settings — allow it there, then try again."
                                            : "Couldn't get your location. Please type your station name.", chips: [])
        }
        guard found.isNearby else { return await nearest() }
        return applyStation(found.name)
    }

    private func locate() async -> ResolvedStation? {
        if location.isDeniedNow {
            SystemSettings.open()
            return nil
        }
        location.requestLocation()
        for _ in 0..<60 {
            if location.latitude != nil || location.failed || location.denied { break }
            try? await Task.sleep(for: .milliseconds(100))
        }
        guard let lat = location.latitude, let lon = location.longitude else { return nil }
        return resolver.nearest(latitude: lat, longitude: lon)
    }

    // MARK: - Helpers

    private func resetDraft() {
        awaiting = nil
        draftStation = nil
        draftCategory = nil
        draftNote = ""
    }

    private func say(_ key: String, chips: [ChatChip] = []) -> ChatMessage {
        ChatMessage(isUser: false, text: tr(key), chips: chips)
    }

    /// Like `say`, but also remembers that a question is pending (kept for readability).
    private func ask(_ key: String, chips: [ChatChip]) -> ChatMessage { say(key, chips: chips) }

    private func greeting() -> ChatMessage {
        say("Hi! I'm your metro assistant. I can report a problem, check a station's status or find your nearest station. Tap an option or just type.",
            chips: mainChips())
    }

    private func mainChips() -> [ChatChip] {
        [ChatChip(title: tr("Report a problem"), payload: "__report"),
         ChatChip(title: tr("Station status"), payload: "__status"),
         ChatChip(title: tr("Nearest station"), payload: "__nearest"),
         ChatChip(title: tr("Any issues now?"), payload: "__issues")]
    }

    private func locationChip() -> [ChatChip] {
        [ChatChip(title: tr("Use my location"), payload: "__loc")]
    }

    private func categoryChips() -> [ChatChip] {
        IncidentCategory.allCases.map { ChatChip(title: $0.localizedTitle, payload: "cat:" + $0.rawValue) }
    }

    // MARK: - Understanding (English / Gujarati / Hindi)

    private func has(_ text: String, _ words: [String]) -> Bool {
        words.contains { text.contains($0) }
    }

    private func wantsLocation(_ lower: String) -> Bool { has(lower, Self.hereWords) }

    private func isCancel(_ lower: String) -> Bool {
        let tokens = Set(lower.split(whereSeparator: { !$0.isLetter }).map(String.init))
        if !tokens.isDisjoint(with: ["cancel", "stop", "nevermind"]) { return true }
        return has(lower, ["never mind", "રદ", "રહેવા દો", "रद्द", "रहने दो", "छोड़ो"])
    }

    /// Longest match wins, so "Sabarmati Railway Station" beats "Sabarmati" and "Sector 16" beats "Sector 1".
    private func findStation(_ lower: String) -> String? {
        var best: (name: String, length: Int)?
        for station in StationDirectory.all {
            for variant in Localizer.shared.variants(of: station.name) {
                let v = variant.lowercased()
                if lower.contains(v), v.count > (best?.length ?? 0) {
                    best = (station.name, v.count)
                }
            }
        }
        return best?.name
    }

    private func detectCategory(_ text: String) -> IncidentCategory? {
        let lower = text.lowercased()
        for (category, words) in Self.categoryWords where has(lower, words) { return category }
        return TriageService.suggest(from: text)?.category
    }

    private static let categoryWords: [(IncidentCategory, [String])] = [
        (.escalator, ["escalator", "lift", "elevator", "stairs", "એસ્કેલેટર", "લિફ્ટ", "સીડી", "एस्केलेटर", "लिफ्ट", "सीढ़ी"]),
        (.ticketGate, ["ticket", "gate", "turnstile", "ટિકિટ", "ગેટ", "टिकट", "गेट"]),
        (.lighting, ["light", "dark", "lamp", "bulb", "લાઇટ", "અંધારું", "અંધારુ", "लाइट", "अंधेरा", "रोशनी", "बत्ती"]),
        (.crowding, ["crowd", "rush", "packed", "ભીડ", "भीड़", "भीड"]),
        (.cleanliness, ["dirty", "clean", "smell", "garbage", "trash", "toilet", "ગંદ", "સફાઈ", "કચરો", "गंदा", "गंदगी", "सफाई", "कचरा"]),
        (.safety, ["safety", "unsafe", "fight", "theft", "harass", "fire", "smoke", "danger", "સલામતી", "ચોરી", "આગ", "જોખમ", "सुरक्षा", "चोरी", "आग", "खतरा"])
    ]

    private static let statusWords = ["status", "how is", "how's", "is it ok", "is it running", "is it working", "any issue at", "any problem at",
                                      "સ્થિતિ", "કેવું", "કેવી", "ચાલુ છે", "स्थिति", "कैसा", "कैसी", "चल रहा"]
    private static let issuesWords = ["any issue", "any problem", "what's wrong", "whats wrong", "disrupted", "all stations",
                                      "બધા સ્ટેશન", "કોઈ સમસ્યા", "सभी स्टेशन", "कोई समस्या"]
    private static let nearestWords = ["nearest", "nearby", "near me", "closest", "નજીક", "નજીકનું", "नज़दीक", "नजदीक", "निकटतम", "पास"]
    private static let reportWords = ["report", "complain", "problem", "issue", "not working", "broken", "stuck", "fault", "damaged",
                                      "ફરિયાદ", "સમસ્યા", "ખરાબ", "બંધ", "शिकायत", "समस्या", "खराब", "बंद", "रिपोर्ट"]
    private static let hereWords = ["here", "my location", "current location", "અહીં", "મારું લોકેશન", "यहाँ", "यहां", "मेरी लोकेशन", "मेरा स्थान"]
    private static let greetWords = ["hi", "hello", "hey", "help", "namaste", "નમસ્તે", "મદદ", "नमस्ते", "मदद"]
}
