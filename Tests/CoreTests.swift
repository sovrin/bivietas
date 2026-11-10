import Foundation
import Testing
@testable import BivietasCore

private func url(_ s: String) -> URL { URL(string: s)! }
private let vivaldi = "com.vivaldi.Vivaldi", chrome = "com.google.Chrome"
private func target(_ profile: String, _ browser: String = vivaldi) -> Target { Target(browserID: browser, profileID: profile) }
private func rule(_ c: Condition..., enabled: Bool = true, to t: Target = target("W")) -> Rule {
    Rule(name: "r", enabled: enabled, conditions: c, target: t)
}

@Suite struct RuleEngineTests {
    @Test func hostSuffixMatchesOnLabelBoundaries() {
        let r = rule(.hostSuffix(".Example.com"))
        #expect(RuleEngine.firstMatch(url("https://example.com"), source: nil, rules: [r]) == r)
        #expect(RuleEngine.firstMatch(url("https://A.EXAMPLE.com/x"), source: nil, rules: [r]) == r)
        #expect(RuleEngine.firstMatch(url("https://badexample.com"), source: nil, rules: [r]) == nil)
    }

    @Test func hostEqualsIsExactAndCaseInsensitive() {
        let r = rule(.hostEquals("GitHub.com"))
        #expect(RuleEngine.firstMatch(url("https://github.com/a"), source: nil, rules: [r]) == r)
        #expect(RuleEngine.firstMatch(url("https://gist.github.com"), source: nil, rules: [r]) == nil)
    }

    @Test func firstEnabledMatchWins() {
        let off = rule(.hostSuffix("a.com"), enabled: false, to: target("X"))
        let first = rule(.hostSuffix("a.com"), to: target("Y"))
        let second = rule(.hostSuffix("a.com"), to: target("Z"))
        #expect(RuleEngine.firstMatch(url("https://a.com"), source: nil, rules: [off, first, second]) == first)
    }

    @Test func conditionsAreANDedAndNilSourceNeverMatchesSourceApp() {
        let r = rule(.sourceApp(bundleID: "com.tinyspeck.slackmacgap"), .hostSuffix("a.com"))
        #expect(RuleEngine.firstMatch(url("https://a.com"), source: "com.tinyspeck.SlackMacGap", rules: [r]) == r)
        #expect(RuleEngine.firstMatch(url("https://b.com"), source: "com.tinyspeck.slackmacgap", rules: [r]) == nil)
        #expect(RuleEngine.firstMatch(url("https://a.com"), source: nil, rules: [r]) == nil)
    }

    @Test func regexAndEdgeCases() {
        #expect(RuleEngine.firstMatch(url("https://x.com/jira/1"), source: nil, rules: [rule(.urlRegex("/jira/\\d+"))]) != nil)
        #expect(RuleEngine.firstMatch(url("https://x.com"), source: nil, rules: [rule(.urlRegex("(unclosed"))]) == nil)
        #expect(RuleEngine.firstMatch(url("https://x.com"), source: nil, rules: [rule()]) == nil) // no conditions
        #expect(RuleEngine.firstMatch(url("https://x.com"), source: nil, rules: [rule(.hostSuffix(""))]) == nil)
        #expect(RuleEngine.firstMatch(url("https://x.com"), source: nil, rules: [rule(.urlRegex(""))]) == nil) // empty never matches
    }

    @Test func regexMatchReportsTheMatchedRange() {
        let text = "https://x.com/jira/PROJ-42?a=1"
        let range = RuleEngine.regexMatch("/jira/[A-Z]+-\\d+", in: text)
        #expect(range.map { String(text[$0]) } == "/jira/PROJ-42")
        #expect(RuleEngine.regexMatch("/wiki/", in: text) == nil)
        #expect(RuleEngine.regexMatch("(", in: text) == nil)
    }
}

@Suite struct URLUnwrapperTests {
    @Test func safeLinks() {
        let u = url("https://eur01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fgithub.com%2Fa%3Fb%3D1&data=x")
        #expect(URLUnwrapper.unwrap(u) == url("https://github.com/a?b=1"))
    }

    @Test func googleAndSlackNested() {
        let inner = "https://www.google.com/url?q=https%3A%2F%2Fexample.org%2Fp&sa=D"
        let u = url("https://slack-redir.net/link?url=" + inner.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)
        #expect(URLUnwrapper.unwrap(u) == url("https://example.org/p"))
    }

    @Test func leavesNonWrappersAlone() {
        let search = url("https://www.google.com/search?q=https%3A%2F%2Fexample.org")
        #expect(URLUnwrapper.unwrap(search) == search)
        let notURL = url("https://www.google.com/url?q=hello")
        #expect(URLUnwrapper.unwrap(notURL) == notURL)
    }

    @Test func userDefinedRule() {
        let u = url("https://t.corp.com/r?to=https%3A%2F%2Fa.com")
        #expect(URLUnwrapper.unwrap(u, extra: [UnwrapRule(host: "corp.com", param: "to")]) == url("https://a.com"))
    }
}

@Suite struct ProfileTests {
    @Test func parsesChromiumLocalState() throws {
        let json = #"{"profile":{"info_cache":{"Profile 1":{"name":"Private"},"Default":{"name":"Work"},"Profile 2":{}}}}"#
        let profiles = try ChromiumProfiles.parse(Data(json.utf8), browserID: chrome)
        #expect(profiles.map(\.name) == ["Work", "Private", "Profile 2"])
        #expect(profiles[1].target == target("Profile 1", chrome))
    }

    @Test func parsesFirefoxProfilesIni() {
        let ini = """
        [Install4F96D1932A9F858E]
        Default=Profiles/abc.default-release

        [Profile1]
        Name=Work
        IsRelative=1
        Path=Profiles/xyz.work

        [Profile0]
        Name=default-release
        Path=Profiles/abc.default-release

        [General]
        Version=2
        """
        let profiles = FirefoxProfiles.parse(ini, browserID: "org.mozilla.firefox")
        #expect(profiles.map(\.name) == ["Work", "default-release"])
        #expect(profiles[0].target == target("Work", "org.mozilla.firefox"))
    }

    @Test func seedUsesProfileNamesAcrossBrowsers() {
        let profiles = [Profile(target: target("Default"), name: "Work"), Profile(target: target("Profile 1"), name: "Private"),
                        Profile(target: target("Profile 1", chrome), name: "Private")]
        let c = Config.seed(profiles: profiles)
        #expect(c.defaultTarget == target("Profile 1")) // first match wins: Vivaldi before Chrome
        #expect(c.rules.allSatisfy { $0.target == target("Default") })
    }
}

@Suite struct ConfigTests {
    @Test func roundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ConfigStore(url: dir.appending(path: "config.json"))
        #expect(try store.load() == nil)
        var c = Config.seed(profiles: [])
        c.fallback = .picker
        c.unwrapRules = [UnwrapRule(host: "a.com", param: "u", path: "/r")]
        c.rules.append(rule(.urlRegex("x"), .hostEquals("y"), to: target("Private", chrome)))
        try store.save(c)
        #expect(try store.load() == c)
    }

    @Test func migratesVivaldiOnlyConfig() throws {
        // The shape written before multi-browser support (including the dropped vivaldiAppPath).
        let old = """
        {"defaultProfileID":"Profile 1","fallback":"picker","openUnwrapped":false,"unwrapRules":[],"vivaldiAppPath":"/x",
         "rules":[{"id":"4DE8BD8B-23FC-4306-8118-0866500F34B4","name":"Slack","enabled":true,"profileID":"Default",
                   "conditions":[{"sourceApp":{"bundleID":"com.tinyspeck.slackmacgap"}}]}]}
        """
        let c = try JSONDecoder().decode(Config.self, from: Data(old.utf8))
        #expect(c.defaultTarget == target("Profile 1"))
        #expect(c.fallback == .picker)
        #expect(c.rules.first?.target == target("Default"))
        #expect(c.rules.first?.conditions == [.sourceApp(bundleID: "com.tinyspeck.slackmacgap")])
    }

    @Test func missingOptionalFieldsUseDefaults() throws {
        let minimal = #"{"defaultTarget":{"browserID":"com.google.Chrome","profileID":"Default"}}"#
        let c = try JSONDecoder().decode(Config.self, from: Data(minimal.utf8))
        #expect(c == Config(rules: [], defaultTarget: target("Default", chrome)))
    }
}

@Suite struct RoutingPolicyTests {
    private let config: Config = {
        var c = Config(rules: [rule(.hostSuffix("work.com"), to: target("W"))], defaultTarget: target("P"))
        c.fallback = .picker
        return c
    }()

    @Test func matchesOnUnwrappedButOpensOriginal() {
        let wrapped = url("https://slack-redir.net/link?url=https%3A%2F%2Fa.work.com%2Fx")
        let route = RoutingPolicy.route(wrapped, source: nil, config: config, paused: false, canAsk: true)
        #expect(route.decision == .open(target("W"), rule: "r"))
        #expect(route.target == wrapped)
        #expect(route.destination == url("https://a.work.com/x"))

        var unwrapping = config
        unwrapping.openUnwrapped = true
        #expect(RoutingPolicy.route(wrapped, source: nil, config: unwrapping, paused: false, canAsk: true).target == url("https://a.work.com/x"))
    }

    @Test func fallbackAsksOnlyWhenItCan() {
        let other = url("https://other.org")
        #expect(RoutingPolicy.route(other, source: nil, config: config, paused: false, canAsk: true).decision == .ask)
        #expect(RoutingPolicy.route(other, source: nil, config: config, paused: false, canAsk: false).decision == .open(target("P"), rule: nil))
    }

    @Test func pausedAndFileURLsGoToDefault() {
        #expect(RoutingPolicy.route(url("https://a.work.com"), source: nil, config: config, paused: true, canAsk: true).decision
                == .open(target("P"), rule: "(paused)"))
        #expect(RoutingPolicy.route(URL(fileURLWithPath: "/tmp/a.html"), source: nil, config: config, paused: false, canAsk: true).decision
                == .open(target("P"), rule: nil))
    }

    @Test func acceptsOnlyWebAndFileSchemes() {
        #expect(RoutingPolicy.accepts(url("HTTPS://a.com")))
        #expect(RoutingPolicy.accepts(URL(fileURLWithPath: "/tmp/a.html")))
        #expect(!RoutingPolicy.accepts(url("mailto:a@b.com")))
    }

    @Test func unknownProfileFallsBackPerBrowser() {
        let known = [Profile(target: target("Default"), name: "Work")]
        #expect(RoutingPolicy.safeTarget(target("Default"), known: known, fallback: target("X")) == target("Default"))
        #expect(RoutingPolicy.safeTarget(target("Profile 9"), known: known, fallback: target("Default")) == target("Default"))
        // Nothing known about Chrome's profiles: trust the config rather than redirect elsewhere.
        #expect(RoutingPolicy.safeTarget(target("Profile 9", chrome), known: known, fallback: target("Default")) == target("Profile 9", chrome))
    }
}

@Suite struct ActivityLogTests {
    @Test func keepsNewestWithinCapacity() {
        var log = ActivityLog(capacity: 2)
        for i in 1...3 { log.record(LogEntry(url: url("https://a\(i).com"), source: nil, rule: nil, target: target("P"))) }
        #expect(log.entries.map(\.host) == ["a3.com", "a2.com"])
    }
}
