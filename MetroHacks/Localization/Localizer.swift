import Foundation
import Observation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, gu, hi
    var id: String { rawValue }
    var nativeName: String {
        switch self {
        case .en: "English"
        case .gu: "ગુજરાતી"
        case .hi: "हिन्दी"
        }
    }
}

/// In-app language switcher (works instantly, no restart). English text is the lookup key.
/// Missing keys fall back to English. Passenger-facing screens are translated; the control room stays English.
@Observable
@MainActor
final class Localizer {
    static let shared = Localizer()

    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage")
        language = saved.flatMap(AppLanguage.init(rawValue:)) ?? .en
    }

    func t(_ key: String) -> String {
        guard language != .en, let entry = Self.table[key] else { return key }
        return language == .gu ? entry.gu : entry.hi
    }

    func variants(of key: String) -> [String] {
        guard let entry = Self.table[key] else { return [key] }
        return [key, entry.gu, entry.hi]
    }

    func f(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }

    // swiftlint:disable line_length
    private static let table: [String: (gu: String, hi: String)] = [
        // Tabs / titles
        "Control": ("નિયંત્રણ", "नियंत्रण"),
        "Stations": ("સ્ટેશન", "स्टेशन"),
        "Report": ("ફરિયાદ", "शिकायत"),
        "Report a problem": ("સમસ્યાની જાણ કરો", "समस्या की रिपोर्ट करें"),
        "Station status": ("સ્ટેશન સ્થિતિ", "स्टेशन स्थिति"),
        "Language": ("ભાષા", "भाषा"),
        // Report form
        "Where are you?": ("તમે ક્યાં છો?", "आप कहाँ हैं?"),
        "What's wrong?": ("શું સમસ્યા છે?", "क्या समस्या है?"),
        "Tell us what you see (optional)": ("તમે શું જુઓ છો તે જણાવો (વૈકલ્પિક)", "आप क्या देख रहे हैं बताएं (वैकल्पिक)"),
        "We'll treat this as %@ priority": ("અમે આને %@ પ્રાથમિકતા ગણીશું", "हम इसे %@ प्राथमिकता मानेंगे"),
        "Photo (optional)": ("ફોટો (વૈકલ્પિક)", "फोटो (वैकल्पिक)"),
        "Attach photo": ("ફોટો જોડો", "फोटो जोड़ें"),
        "Change photo": ("ફોટો બદલો", "फोटो बदलें"),
        "Remove photo": ("ફોટો હટાવો", "फोटो हटाएं"),
        "Send report": ("રિપોર્ટ મોકલો", "रिपोर्ट भेजें"),
        "Works offline. If you have no signal, your report is saved and sent automatically.": ("ઑફલાઇન પણ કામ કરે છે. સિગ્નલ ન હોય તો રિપોર્ટ સેવ થશે અને આપમેળે મોકલાશે.", "ऑफ़लाइन भी काम करता है। सिग्नल न हो तो रिपोर्ट सेव होगी और अपने-आप भेजी जाएगी।"),
        "Report sent": ("રિપોર્ટ મોકલાયો", "रिपोर्ट भेज दी गई"),
        "%1$@ at %2$@": ("%2$@ ખાતે %1$@", "%2$@ पर %1$@"),
        "Priority: %@": ("પ્રાથમિકતા: %@", "प्राथमिकता: %@"),
        "Routed to %@": ("%@ ટીમને મોકલ્યું", "%@ टीम को भेजा गया"),
        "Saved on your phone. It will send automatically when you're back online.": ("ફોનમાં સેવ થયું. ઇન્ટરનેટ આવતા જ આપમેળે મોકલાશે.", "फ़ोन में सेव हो गया। इंटरनेट आते ही अपने-आप भेजा जाएगा।"),
        "Report another": ("બીજી જાણ કરો", "एक और रिपोर्ट करें"),
        "Added to an existing issue. %d passengers have reported it.": ("હાલની સમસ્યામાં ઉમેરાયું. %d મુસાફરોએ તેની જાણ કરી છે.", "मौजूदा समस्या में जोड़ा गया। %d यात्रियों ने इसकी रिपोर्ट की है।"),
        "%d passengers reported this": ("%d મુસાફરોએ આની જાણ કરી", "%d यात्रियों ने इसकी रिपोर्ट की"),
        // Station picker
        "Station": ("સ્ટેશન", "स्टेशन"),
        "Select station": ("સ્ટેશન પસંદ કરો", "स्टेशन चुनें"),
        "Finding nearest station…": ("નજીકનું સ્ટેશન શોધી રહ્યા છીએ…", "निकटतम स्टेशन खोज रहे हैं…"),
        "Nearest: %@ · %@": ("નજીકનું: %@ · %@", "निकटतम: %@ · %@"),
        "No metro station within 2 km of you.": ("તમારાથી 2 કિમીમાં કોઈ મેટ્રો સ્ટેશન નથી.", "आपके 2 किमी में कोई मेट्रो स्टेशन नहीं है।"),
        "Nearest is %@ (%@) – use it": ("નજીકનું %@ (%@) છે – પસંદ કરો", "निकटतम %@ (%@) है – चुनें"),
        "Use my location": ("મારું લોકેશન વાપરો", "मेरा स्थान उपयोग करें"),
        "Location is off for this app. Enable it in Settings, or pick a station below.": ("આ એપ માટે લોકેશન બંધ છે. સેટિંગ્સમાં ચાલુ કરો અથવા નીચે સ્ટેશન પસંદ કરો.", "इस ऐप के लिए लोकेशन बंद है। सेटिंग्स में चालू करें या नीचे स्टेशन चुनें।"),
        "Couldn't get a GPS fix. Pick your station below.": ("GPS લોકેશન મળ્યું નહીં. નીચે તમારું સ્ટેશન પસંદ કરો.", "GPS लोकेशन नहीं मिला। नीचे अपना स्टेशन चुनें।"),
        "No metro station nearby. Pick one below.": ("નજીકમાં કોઈ મેટ્રો સ્ટેશન નથી. નીચે પસંદ કરો.", "आस-पास कोई मेट्रो स्टेशन नहीं है। नीचे चुनें।"),
        // Categories
        "Escalator fault": ("એસ્કેલેટર ખામી", "एस्केलेटर खराबी"),
        "Ticket gate": ("ટિકિટ ગેટ", "टिकट गेट"),
        "Lighting": ("લાઇટિંગ", "रोशनी"),
        "Crowding": ("ભીડ", "भीड़"),
        "Cleanliness": ("સફાઈ", "सफ़ाई"),
        "Safety": ("સલામતી", "सुरक्षा"),
        // Severity
        "Low": ("નીચી", "कम"),
        "Medium": ("મધ્યમ", "मध्यम"),
        "High": ("ઉચ્ચ", "उच्च"),
        // Passenger messages
        "Escalator or lift may be unavailable": ("એસ્કેલેટર કે લિફ્ટ બંધ હોઈ શકે છે", "एस्केलेटर या लिफ्ट बंद हो सकती है"),
        "Some ticket gates are affected": ("કેટલાક ટિકિટ ગેટ પ્રભાવિત છે", "कुछ टिकट गेट प्रभावित हैं"),
        "Lighting is being repaired": ("લાઇટિંગનું સમારકામ ચાલુ છે", "रोशनी की मरम्मत जारी है"),
        "Platform is crowded": ("પ્લેટફોર્મ પર ભીડ છે", "प्लेटफ़ॉर्म पर भीड़ है"),
        "Cleaning in progress": ("સફાઈ ચાલુ છે", "सफ़ाई जारी है"),
        "Safety check in progress": ("સલામતી તપાસ ચાલુ છે", "सुरक्षा जांच जारी है"),
        // Station status
        "Normal": ("સામાન્ય", "सामान्य"),
        "Minor issues": ("નાની સમસ્યાઓ", "छोटी समस्याएं"),
        "Disrupted": ("વિક્ષેપિત", "बाधित"),
        "All stations running normally": ("બધા સ્ટેશન સામાન્ય ચાલે છે", "सभी स्टेशन सामान्य रूप से चल रहे हैं"),
        "%d station affected": ("%d સ્ટેશન પ્રભાવિત", "%d स्टेशन प्रभावित"),
        "%d stations affected": ("%d સ્ટેશન પ્રભાવિત", "%d स्टेशन प्रभावित"),
        "Show only affected stations": ("ફક્ત પ્રભાવિત સ્ટેશન બતાવો", "केवल प्रभावित स्टेशन दिखाएं"),
        "Interchange: %@": ("ઇન્ટરચેન્જ: %@", "इंटरचेंज: %@"),
        "Interchange": ("ઇન્ટરચેન્જ", "इंटरचेंज"),
        "Change here for the %@": ("%@ માટે અહીં બદલો", "%@ के लिए यहाँ बदलें"),
        "Ahmedabad NS line": ("અમદાવાદ NS લાઇન", "अहमदाबाद NS लाइन"),
        "Ahmedabad EW line": ("અમદાવાદ EW લાઇન", "अहमदाबाद EW लाइन"),
        "Gandhinagar line": ("ગાંધીનગર લાઇન", "गांधीनगर लाइन"),
        "GIFT City line": ("ગિફ્ટ સિટી લાઇન", "गिफ्ट सिटी लाइन"),
        "Airport line (planned)": ("એરપોર્ટ લાઇન (આયોજિત)", "एयरपोर्ट लाइन (प्रस्तावित)"),
        "Other stations": ("અન્ય સ્ટેશન", "अन्य स्टेशन"),
        // Station detail
        "Right now": ("અત્યારે", "अभी"),
        "No known issues": ("કોઈ જાણીતી સમસ્યા નથી", "कोई ज्ञात समस्या नहीं"),
        "Reported": ("જાણ કરી", "रिपोर्ट किया"),
        "ago": ("પહેલાં", "पहले"),
        "Team assigned: %@": ("ટીમ સોંપાઈ: %@", "टीम नियुक्त: %@"),
        "Recently fixed": ("તાજેતરમાં ઠીક થયું", "हाल ही में ठीक हुआ"),
        "Report a problem at this station": ("આ સ્ટેશન પરની સમસ્યાની જાણ કરો", "इस स्टेशन की समस्या रिपोर्ट करें"),
        // Staff / control room
        "Metro Control": ("મેટ્રો કંટ્રોલ", "मेट्रो कंट्रोल"),
        "Load sample data": ("નમૂનાનો ડેટા લોડ કરો", "नमूना डेटा लोड करें"),
        "Demo SLA (1 / 2 / 5 min)": ("ડેમો SLA (1 / 2 / 5 મિનિટ)", "डेमो SLA (1 / 2 / 5 मिनट)"),
        "Delete all": ("બધું કાઢી નાખો", "सब हटाएं"),
        "Delete all incidents?": ("બધી ઘટનાઓ કાઢી નાખવી?", "सभी घटनाएं हटाएं?"),
        "Filter": ("ફિલ્ટર", "फ़िल्टर"),
        "Incidents": ("ઘટનાઓ", "घटनाएं"),
        "Nothing here": ("અહીં કંઈ નથી", "यहाँ कुछ नहीं है"),
        "Tap + to log an incident, or load sample data from the menu.": ("ઘટના નોંધવા + દબાવો, અથવા મેનૂમાંથી નમૂનાનો ડેટા લોડ કરો.", "घटना दर्ज करने के लिए + दबाएं, या मेनू से नमूना डेटा लोड करें।"),
        "Reopen": ("ફરી ખોલો", "फिर से खोलें"),
        "Resolve": ("ઉકેલો", "हल करें"),
        "Open": ("ખુલ્લી", "खुली"),
        "Assigned": ("સોંપાયેલ", "सौंपी गई"),
        "Resolved": ("ઉકેલાયેલ", "हल हुई"),
        "Active": ("સક્રિય", "सक्रिय"),
        "Overdue": ("મુદત વીતેલ", "समय सीमा पार"),
        "All": ("બધી", "सभी"),
        "Mechanical": ("મિકેનિકલ", "मैकेनिकल"),
        "Electrical": ("ઇલેક્ટ્રિકલ", "इलेक्ट्रिकल"),
        "Housekeeping": ("હાઉસકીપિંગ", "हाउसकीपिंग"),
        "Security": ("સુરક્ષા", "सिक्योरिटी"),
        "Station Controller": ("સ્ટેશન કંટ્રોલર", "स्टेशन कंट्रोलर"),
        "Unassigned": ("સોંપાયેલ નથી", "असाइन नहीं"),
        "Incident": ("ઘટના", "घटना"),
        "Escalated: past SLA": ("ઉપર મોકલાયું: SLA સમય વીત્યો", "आगे बढ़ाया गया: SLA समय पार"),
        "Workflow": ("કાર્યપ્રવાહ", "कार्यप्रवाह"),
        "Status": ("સ્થિતિ", "स्थिति"),
        "Assigned to": ("કોને સોંપ્યું", "किसे सौंपा"),
        "Mark resolved": ("ઉકેલાયેલ તરીકે ચિહ્નિત કરો", "हल हुआ चिह्नित करें"),
        "Details": ("વિગતો", "विवरण"),
        "Sync": ("સિંક", "सिंक"),
        "Synced": ("સિંક થયું", "सिंक हुआ"),
        "Pending": ("બાકી", "लंबित"),
        "Triaged automatically on device": ("ફોન પર આપમેળે વર્ગીકૃત", "फ़ोन पर अपने-आप वर्गीकृत"),
        "New Incident": ("નવી ઘટના", "नई घटना"),
        "Describe the problem": ("સમસ્યાનું વર્ણન કરો", "समस्या का वर्णन करें"),
        "Category": ("શ્રેણી", "श्रेणी"),
        "Severity": ("ગંભીરતા", "गंभीरता"),
        "Route to": ("આને મોકલો", "इसे भेजें"),
        "Auto-triage": ("ઓટો-ટ્રાયેજ", "ऑटो-ट्राइएज"),
        "Suggested: %@": ("સૂચવેલ: %@", "सुझाया गया: %@"),
        "Route to %@ · matched: %@": ("%@ ને મોકલો · મેળ: %@", "%@ को भेजें · मिलान: %@"),
        "none": ("કોઈ નહીં", "कोई नहीं"),
        "Apply suggestion": ("સૂચન લાગુ કરો", "सुझाव लागू करें"),
        "Photo": ("ફોટો", "फोटो"),
        "Cancel": ("રદ કરો", "रद्द करें"),
        "Save": ("સેવ કરો", "सेव करें"),
        "No data yet": ("હજી ડેટા નથી", "अभी कोई डेटा नहीं"),
        "Log incidents or load sample data to see charts.": ("ચાર્ટ જોવા ઘટનાઓ નોંધો અથવા નમૂનાનો ડેટા લોડ કરો.", "चार्ट देखने के लिए घटनाएं दर्ज करें या नमूना डेटा लोड करें।"),
        "Avg fix": ("સરેરાશ ઉકેલ", "औसत समाधान"),
        "By status": ("સ્થિતિ મુજબ", "स्थिति के अनुसार"),
        "By category": ("શ્રેણી મુજબ", "श्रेणी के अनुसार"),
        "By severity": ("ગંભીરતા મુજબ", "गंभीरता के अनुसार"),
        "Control room": ("કંટ્રોલ રૂમ", "कंट्रोल रूम"),
        "Done": ("પૂર્ણ", "हो गया"),
        "Online": ("ઓનલાઇન", "ऑनलाइन"),
        "Offline": ("ઓફલાઇન", "ऑफ़लाइन"),
        "%d overdue": ("%d મુદત વીતેલ", "%d समय सीमा पार"),
        "Syncing…": ("સિંક થઈ રહ્યું છે…", "सिंक हो रहा है…"),
        "%d pending sync": ("%d સિંક બાકી", "%d सिंक लंबित"),
        "Passenger": ("મુસાફર", "यात्री"),
        "%d reports": ("%d રિપોર્ટ", "%d रिपोर्ट"),
        "Overdue by %d min": ("%d મિનિટ મોડું", "%d मिनट की देरी"),
        "SLA: %d min left": ("SLA: %d મિનિટ બાકી", "SLA: %d मिनट शेष"),
        // Onboarding
        "Report metro problems in seconds, even without internet.": ("મેટ્રોની સમસ્યાની જાણ સેકન્ડોમાં કરો, ઇન્ટરનેટ વગર પણ.", "मेट्रो की समस्या सेकंडों में रिपोर्ट करें, बिना इंटरनेट के भी।"),
        "Continue": ("આગળ વધો", "आगे बढ़ें"),
        "Get started": ("શરૂ કરો", "शुरू करें"),
        "Choose your language": ("તમારી ભાષા પસંદ કરો", "अपनी भाषा चुनें"),
        "You can change it any time from the 🌐 menu.": ("તમે 🌐 મેનૂમાંથી ગમે ત્યારે બદલી શકો છો.", "आप 🌐 मेनू से कभी भी बदल सकते हैं।"),
        "Two quick permissions": ("બે ઝડપી પરવાનગી", "दो ज़रूरी अनुमतियाँ"),
        "Location": ("લોકેશન", "स्थान"),
        "We use it only to find the metro station nearest to you, so you don't have to pick it yourself. It stays on your phone.": ("તમારી નજીકનું મેટ્રો સ્ટેશન શોધવા માટે જ વપરાય છે, જેથી તમારે જાતે પસંદ ન કરવું પડે. તે તમારા ફોનમાં જ રહે છે.", "आपके सबसे नज़दीकी मेट्रो स्टेशन को खोजने के लिए ही इस्तेमाल होता है, ताकि आपको खुद न चुनना पड़े। यह आपके फ़ोन में ही रहता है।"),
        "Allow location": ("લોકેશનની મંજૂરી આપો", "स्थान की अनुमति दें"),
        "Notifications": ("સૂચનાઓ", "सूचनाएं"),
        "We alert you when a reported problem is taking too long to fix. Works without internet.": ("નોંધાયેલ સમસ્યા ઠીક થવામાં વધુ સમય લે ત્યારે તમને જણાવીએ છીએ. ઇન્ટરનેટ વગર પણ કામ કરે છે.", "जब कोई रिपोर्ट की गई समस्या ठीक होने में बहुत समय लेती है तो हम आपको बताते हैं। बिना इंटरनेट के भी काम करता है।"),
        "Allow notifications": ("સૂચનાઓની મંજૂરી આપો", "सूचनाओं की अनुमति दें"),
        // Assistant
        "Assistant": ("સહાયક", "सहायक"),
        "Type a message…": ("સંદેશ લખો…", "संदेश लिखें…"),
        "Hi! I'm your metro assistant. I can report a problem, check a station's status or find your nearest station. Tap an option or just type.": ("નમસ્તે! હું તમારો મેટ્રો સહાયક છું. હું સમસ્યાની જાણ કરી શકું, સ્ટેશનની સ્થિતિ જણાવી શકું અથવા નજીકનું સ્ટેશન શોધી શકું. વિકલ્પ દબાવો અથવા લખો.", "नमस्ते! मैं आपका मेट्रो सहायक हूँ। मैं समस्या रिपोर्ट कर सकता हूँ, स्टेशन की स्थिति बता सकता हूँ या नज़दीकी स्टेशन ढूँढ सकता हूँ। विकल्प दबाएं या लिखें।"),
        "Nearest station": ("નજીકનું સ્ટેશન", "निकटतम स्टेशन"),
        "Any issues now?": ("અત્યારે કોઈ સમસ્યા?", "अभी कोई समस्या?"),
        "Which station are you at? Type its name or use your location.": ("તમે કયા સ્ટેશન પર છો? નામ લખો અથવા લોકેશન વાપરો.", "आप किस स्टेशन पर हैं? नाम लिखें या अपना स्थान उपयोग करें।"),
        "Which station do you want to check?": ("કયું સ્ટેશન તપાસવું છે?", "कौन सा स्टेशन जांचना है?"),
        "What's the problem?": ("શું સમસ્યા છે?", "क्या समस्या है?"),
        "I didn't catch the problem. Please pick one:": ("સમસ્યા સમજાઈ નહીં. કૃપા કરીને એક પસંદ કરો:", "समस्या समझ नहीं आई। कृपया एक चुनें:"),
        "I couldn't find that station. Please type it again or use your location.": ("તે સ્ટેશન મળ્યું નહીં. ફરી લખો અથવા લોકેશન વાપરો.", "वह स्टेशन नहीं मिला। फिर से लिखें या अपना स्थान उपयोग करें।"),
        "Done! I reported “%1$@” at %2$@. Priority: %3$@ · Routed to %4$@.": ("થઈ ગયું! મેં %2$@ પર “%1$@” ની જાણ કરી. પ્રાથમિકતા: %3$@ · %4$@ ટીમને મોકલ્યું.", "हो गया! मैंने %2$@ पर “%1$@” की रिपोर्ट की। प्राथमिकता: %3$@ · %4$@ टीम को भेजा गया।"),
        "Added to an existing report at %2$@ — %1$d passengers have reported this.": ("%2$@ ની હાલની જાણમાં ઉમેરાયું — %1$d મુસાફરોએ આની જાણ કરી છે.", "%2$@ की मौजूदा रिपोर्ट में जोड़ा गया — %1$d यात्रियों ने इसकी रिपोर्ट की है।"),
        "%@ is running normally. No known issues.": ("%@ સામાન્ય ચાલે છે. કોઈ જાણીતી સમસ્યા નથી.", "%@ सामान्य रूप से चल रहा है। कोई ज्ञात समस्या नहीं।"),
        "%@ has issues right now:": ("%@ પર અત્યારે સમસ્યાઓ છે:", "%@ पर अभी समस्याएं हैं:"),
        "All stations are running normally.": ("બધા સ્ટેશન સામાન્ય ચાલે છે.", "सभी स्टेशन सामान्य रूप से चल रहे हैं।"),
        "%d stations have issues: %@": ("%d સ્ટેશન પર સમસ્યાઓ છે: %@", "%d स्टेशनों पर समस्याएं हैं: %@"),
        "Your nearest station is %@ (%@).": ("તમારું નજીકનું સ્ટેશન %@ (%@) છે.", "आपका निकटतम स्टेशन %@ (%@) है।"),
        "No metro station within 2 km. The nearest is %@ (%@).": ("2 કિમીમાં કોઈ મેટ્રો સ્ટેશન નથી. સૌથી નજીકનું %@ (%@) છે.", "2 किमी में कोई मेट्रो स्टेशन नहीं है। सबसे नज़दीकी %@ (%@) है।"),
        "Couldn't get your location. Please type your station name.": ("તમારું લોકેશન મળ્યું નહીં. કૃપા કરીને સ્ટેશનનું નામ લખો.", "आपका स्थान नहीं मिला। कृपया स्टेशन का नाम लिखें।"),
        "Sorry, I didn't get that. Try “escalator not working at Gandhigram” or tap an option.": ("માફ કરશો, સમજાયું નહીં. “ગાંધીગ્રામમાં એસ્કેલેટર બંધ છે” લખી જુઓ અથવા વિકલ્પ દબાવો.", "क्षमा करें, समझ नहीं आया। “गांधीग्राम में एस्केलेटर बंद है” लिखकर देखें या कोई विकल्प दबाएं।"),
        "Okay, cancelled. Anything else?": ("ઠીક છે, રદ કર્યું. બીજું કંઈ?", "ठीक है, रद्द किया। और कुछ?"),
        "Status of %@": ("%@ ની સ્થિતિ", "%@ की स्थिति"),
        "Report at %@": ("%@ પર જાણ કરો", "%@ पर रिपोर्ट करें"),
        "Allowed": ("મંજૂર", "अनुमति मिली"),
        "Not allowed": ("મંજૂર નથી", "अनुमति नहीं"),
        "Open Settings": ("સેટિંગ્સ ખોલો", "सेटिंग्स खोलें"),
        "Location is off for this app. Opening Settings — allow it there, then try again.": ("આ એપ માટે લોકેશન બંધ છે. સેટિંગ્સ ખોલી રહ્યા છીએ — ત્યાં મંજૂરી આપો, પછી ફરી પ્રયાસ કરો.", "इस ऐप के लिए लोकेशन बंद है। सेटिंग्स खोल रहे हैं — वहाँ अनुमति दें, फिर दोबारा कोशिश करें।"),
        "Report problems, check stations, find your nearest one — even offline.": ("સમસ્યાની જાણ કરો, સ્ટેશન તપાસો, નજીકનું સ્ટેશન શોધો — ઑફલાઇન પણ.", "समस्या रिपोर्ट करें, स्टेशन जांचें, नज़दीकी स्टेशन खोजें — ऑफ़लाइन भी।"),
        // Station names
        "APMC": ("એપીએમસી", "एपीएमसी"),
        "Jivraj Park": ("જીવરાજ પાર્ક", "जीवराज पार्क"),
        "Rajiv Nagar": ("રાજીવ નગર", "राजीव नगर"),
        "Shreyas": ("શ્રેયસ", "श्रेयस"),
        "Paldi": ("પાલડી", "पालडी"),
        "Gandhigram": ("ગાંધીગ્રામ", "गांधीग्राम"),
        "Old High Court": ("જૂની હાઈ કોર્ટ", "पुराना हाई कोर्ट"),
        "Usmanpura": ("ઉસ્માનપુરા", "उस्मानपुरा"),
        "Vijay Nagar": ("વિજય નગર", "विजय नगर"),
        "Vadaj": ("વાડજ", "वाड़ज"),
        "Ranip": ("રાણીપ", "राणिप"),
        "Sabarmati Railway Station": ("સાબરમતી રેલવે સ્ટેશન", "साबरमती रेलवे स्टेशन"),
        "AEC": ("એઇસી", "एईसी"),
        "Sabarmati": ("સાબરમતી", "साबरमती"),
        "Thaltej Gam": ("થલતેજ ગામ", "थलतेज गाँव"),
        "Thaltej": ("થલતેજ", "थलतेज"),
        "Doordarshan Kendra": ("દૂરદર્શન કેન્દ્ર", "दूरदर्शन केंद्र"),
        "Gurukul Road": ("ગુરુકુલ રોડ", "गुरुकुल रोड"),
        "Gujarat University": ("ગુજરાત યુનિવર્સિટી", "गुजरात यूनिवर्सिटी"),
        "Commerce Six Road": ("કોમર્સ સિક્સ રોડ", "कॉमर्स सिक्स रोड"),
        "S P Stadium": ("એસ પી સ્ટેડિયમ", "एस पी स्टेडियम"),
        "Shahpur": ("શાહપુર", "शाहपुर"),
        "Gheekanta": ("ઘીકાંટા", "घीकांटा"),
        "Kalupur": ("કાલુપુર", "कालूपुर"),
        "Kankariya East": ("કાંકરિયા ઈસ્ટ", "कांकरिया ईस्ट"),
        "Apparel Park": ("એપેરલ પાર્ક", "अपैरल पार्क"),
        "Amraivadi": ("અમરાઈવાડી", "अमराईवाड़ी"),
        "Rabari Colony": ("રબારી કોલોની", "रबारी कॉलोनी"),
        "Vastral": ("વસ્ત્રાલ", "वस्त्राल"),
        "Nirant Cross Road": ("નિરંત ક્રોસ રોડ", "निरंत क्रॉस रोड"),
        "Vastral Gam": ("વસ્ત્રાલ ગામ", "वस्त्राल गाँव"),
        "Motera Stadium": ("મોટેરા સ્ટેડિયમ", "मोटेरा स्टेडियम"),
        "Koteshwar Road": ("કોટેશ્વર રોડ", "कोटेश्वर रोड"),
        "Viswakarama College": ("વિશ્વકર્મા કોલેજ", "विश्वकर्मा कॉलेज"),
        "Tapovan Circle": ("તપોવન સર્કલ", "तपोवन सर्कल"),
        "Narmada Canal": ("નર્મદા કેનાલ", "नर्मदा कैनाल"),
        "Koba Circle": ("કોબા સર્કલ", "कोबा सर्कल"),
        "Juna Koba": ("જૂના કોબા", "जूना कोबा"),
        "Koba Gaam": ("કોબા ગામ", "कोबा गाँव"),
        "GNLU": ("જીએનએલયુ", "जीएनएलयू"),
        "Raysan": ("રાયસણ", "रायसण"),
        "Randesan": ("રાંદેસણ", "रांदेसण"),
        "Dholakuva Circle": ("ઢોલાકૂવા સર્કલ", "ढोलाकुवा सर्कल"),
        "Infocity": ("ઇન્ફોસિટી", "इन्फोसिटी"),
        "Sector 1": ("સેક્ટર 1", "सेक्टर 1"),
        "Sector 10A": ("સેક્ટર 10A", "सेक्टर 10A"),
        "Sachivalaya": ("સચિવાલય", "सचिवालय"),
        "Akshardham": ("અક્ષરધામ", "अक्षरधाम"),
        "Juna Sachivalaya": ("જૂના સચિવાલય", "पुराना सचिवालय"),
        "Sector 16": ("સેક્ટર 16", "सेक्टर 16"),
        "Sector 24": ("સેક્ટર 24", "सेक्टर 24"),
        "Mahatma Mandir": ("મહાત્મા મંદિર", "महात्मा मंदिर"),
        "PDEU": ("પીડીઈયુ", "पीडीईयू"),
        "GIFT City": ("ગિફ્ટ સિટી", "गिफ्ट सिटी"),
    ]
}

/// Short helpers used by views.
@MainActor func tr(_ key: String) -> String { Localizer.shared.t(key) }
@MainActor func trf(_ key: String, _ args: CVarArg...) -> String {
    String(format: Localizer.shared.t(key), arguments: args)
}

extension IncidentCategory {
    @MainActor var localizedTitle: String { tr(rawValue) }
}

extension Severity {
    @MainActor var localizedTitle: String { tr(title) }
}

extension IncidentStatus {
    @MainActor var localizedTitle: String { tr(rawValue) }
}

extension IncidentFilter {
    @MainActor var localizedTitle: String { tr(rawValue) }
}

extension ResponseTeam {
    @MainActor var localizedName: String { tr(rawValue) }
    @MainActor static func display(_ raw: String?) -> String {
        guard let raw else { return tr("Unassigned") }
        return tr(raw)
    }
}

struct LanguageMenu: View {
    @Bindable private var localizer = Localizer.shared

    var body: some View {
        Menu {
            Picker(localizer.t("Language"), selection: $localizer.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.nativeName).tag(language)
                }
            }
        } label: {
            Label(localizer.language.nativeName, systemImage: "globe")
        }
    }
}
