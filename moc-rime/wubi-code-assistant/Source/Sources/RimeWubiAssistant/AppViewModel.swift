import AppKit
import Foundation
import RimeWubiCore

@MainActor
final class AppViewModel: ObservableObject {
  @Published var word = ""
  @Published var code = ""
  @Published var explanation = "输入常用简体词语，将自动生成编码。"
  @Published var characterBreakdowns: [CharacterBreakdown] = []
  @Published var weightText = "50000"
  @Published var isBusy = false
  @Published var statusMessage = ""
  @Published var statusKind: StatusKind = .neutral
  @Published var showConfirmation = false
  @Published private(set) var canReplaceExistingText = false
  @Published private(set) var confirmationMessage = ""

  private let environment: RimeEnvironment
  private let store: PersonalDictionaryStore
  private let reloader: SquirrelReloader
  private var encoder: WubiEncoder?
  private var lastSuggestedWord = ""
  private var personalMatches: [DictionaryEntry] = []
  private var personalDictionaryReady = false
  @Published private(set) var hasBuiltinExactMatch = false
  private var suggestionTask: Task<Void, Never>?

  enum StatusKind {
    case neutral
    case success
    case warning
    case error
  }

  init(environment: RimeEnvironment = .current()) {
    self.environment = environment
    self.store = PersonalDictionaryStore(
      dictionaryURL: environment.userDictionaryURL,
      backupDirectoryURL: environment.backupDirectoryURL
    )
    self.reloader = SquirrelReloader(executableURL: environment.squirrelExecutableURL)
  }

  var canRequestAdd: Bool {
    let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let normalizedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
    let isUnchangedPersonalEntry = personalMatches.contains {
      $0.text == normalizedWord && $0.code == normalizedCode
    }
    return !isBusy && personalDictionaryReady
      && !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !normalizedCode.isEmpty
      && (1...99_999).contains(Int(weightText) ?? 0)
      && !isUnchangedPersonalEntry
  }

  func wordDidChange(_ newValue: String, isComposing: Bool) {
    word = newValue
    suggestionTask?.cancel()
    if newValue.trimmingCharacters(in: .whitespacesAndNewlines) != lastSuggestedWord {
      code = ""
      explanation = newValue.isEmpty ? "输入常用简体词语，将自动生成编码。" : "正在识别…"
      characterBreakdowns = []
      personalMatches = []
      personalDictionaryReady = false
      hasBuiltinExactMatch = false
      clearStatus()
    }

    let normalizedWord = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !isComposing, !normalizedWord.isEmpty else { return }
    suggestionTask = Task { [weak self] in
      try? await Task.sleep(nanoseconds: 260_000_000)
      guard !Task.isCancelled else { return }
      self?.generateSuggestion(expectedWord: normalizedWord)
    }
  }

  func generateSuggestion(expectedWord: String? = nil) {
    clearStatus()
    let normalizedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
    guard expectedWord == nil || expectedWord == normalizedWord else { return }
    do {
      if encoder == nil { encoder = try WubiEncoder.bundled() }
      guard let encoder else { return }
      let suggestion = try encoder.suggest(for: normalizedWord)
      word = suggestion.text
      lastSuggestedWord = suggestion.text
      code = suggestion.code
      explanation = suggestion.explanation
      characterBreakdowns = suggestion.characterBreakdowns
      refreshDuplicateStatus()
    } catch {
      characterBreakdowns = []
      explanation = "也可以直接手动填写编码。"
      setStatus(error.localizedDescription, kind: .error)
    }
  }

  func refreshDuplicateStatus() {
    let text = word.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !text.isEmpty, !normalizedCode.isEmpty else { return }
    var messages: [String] = []
    var warning = false
    do {
      let entries = try RimeDictionaryParser.parseFile(
        at: environment.userDictionaryURL, source: .personal, strict: true)
      personalMatches = entries.filter { $0.text == text }
      personalDictionaryReady = true
      if personalMatches.contains(where: { $0.code == normalizedCode }) {
        messages.append("个人词库已有同词同码，无需重复添加。")
        warning = true
      } else if !personalMatches.isEmpty {
        messages.append("个人词库已有编码：\(personalMatches.map(\.code).joined(separator: "、"))。")
        warning = true
      }
    } catch {
      personalDictionaryReady = false
      personalMatches = []
      messages.append("个人词库检查未完成，写入前需先解决：\(error.localizedDescription)")
      warning = true
    }
    let status = SchemeDictionaryReader(rimeDirectoryURL: environment.rimeDirectoryURL).read()
    hasBuiltinExactMatch = status.check(text: text, code: normalizedCode)?.hasExactMatch == true
    messages.append(contentsOf: schemeMessages(status, text: text, code: normalizedCode))
    if case .unavailable = status { warning = true }
    if hasBuiltinExactMatch { warning = true }
    setStatus(messages.joined(separator: "\n"), kind: warning ? .warning : .neutral)
  }

  private func schemeMessages(_ status: SchemeDictionaryStatus, text: String, code: String)
    -> [String]
  {
    switch status {
    case .unavailable(let reason):
      return ["当前方案比对未完成：\(reason)。仍可按规则生成编码。"]
    case .available(_, let name, _):
      guard let check = status.check(text: text, code: code) else { return [] }
      if check.hasExactMatch {
        return ["\(name)已有同词同码，通常无需添加；需要个人权重时仍可添加。"]
      }
      var messages = ["本次比对：\(name)。"]
      if !check.sameTextEntries.isEmpty {
        let codes = Array(Set(check.sameTextEntries.map(\.code))).sorted().joined(separator: "、")
        messages.append("词库已有其他编码：\(codes)；本次编码仍按规则生成。")
      } else {
        messages.append("未发现同词同码。")
      }
      if !check.sameCodeEntries.isEmpty {
        messages.append("存在\(check.sameCodeEntries.count)条其他词重码，属于正常候选。")
      }
      return messages
    }
  }

  func requestAdd() {
    guard let weight = Int(weightText) else {
      setStatus(RimeCoreError.invalidWeight.localizedDescription, kind: .error)
      return
    }
    do {
      let check = try store.inspect(text: word, code: code)
      guard !check.hasExactMatch else {
        throw RimeCoreError.exactDuplicate
      }

      canReplaceExistingText = !check.sameTextEntries.isEmpty
      var messages = ["将添加：\(word)  →  \(code.lowercased())，权重 \(weight)。"]
      if !check.sameTextEntries.isEmpty {
        let oldCodes = check.sameTextEntries.map(\.code).joined(separator: "、")
        messages.append("个人词典已有同词编码：\(oldCodes)。")
      }
      if !check.sameCodeEntries.isEmpty {
        messages.append("同码已有 \(check.sameCodeEntries.count) 个词，这是正常的候选重码。")
      }
      let status = SchemeDictionaryReader(rimeDirectoryURL: environment.rimeDirectoryURL).read()
      hasBuiltinExactMatch =
        status.check(
          text: word.trimmingCharacters(in: .whitespacesAndNewlines),
          code: code.trimmingCharacters(in: .whitespacesAndNewlines))?.hasExactMatch == true
      messages.append(
        contentsOf: schemeMessages(
          status, text: word.trimmingCharacters(in: .whitespacesAndNewlines),
          code: code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()))
      messages.append("确认后将备份词典、写入并请求鼠须管重新部署。")
      confirmationMessage = messages.joined(separator: "\n\n")
      showConfirmation = true
    } catch {
      setStatus(error.localizedDescription, kind: .error)
    }
  }

  func confirmAdd(mode: AddMode) {
    showConfirmation = false
    guard let weight = Int(weightText) else {
      setStatus(RimeCoreError.invalidWeight.localizedDescription, kind: .error)
      return
    }
    isBusy = true
    do {
      let result = try store.add(text: word, code: code, weight: weight, mode: mode)
      do {
        try reloader.requestReload()
        finishSuccessfulAdd(
          "已添加“\(result.entry.text)”，并已请求鼠须管重新部署。"
        )
      } catch {
        finishSuccessfulAdd(
          "词条已经安全保存并备份，但\(error.localizedDescription)",
          kind: .warning
        )
      }
    } catch {
      setStatus(error.localizedDescription, kind: .error)
    }
    isBusy = false
  }

  func revealDictionary() {
    let url = environment.userDictionaryURL
    guard FileManager.default.fileExists(atPath: url.path) else {
      setStatus(RimeCoreError.missingFile(url.path).localizedDescription, kind: .error)
      return
    }
    NSWorkspace.shared.activateFileViewerSelecting([url])
  }

  func openDictionary() {
    let url = environment.userDictionaryURL
    guard FileManager.default.fileExists(atPath: url.path) else {
      setStatus(RimeCoreError.missingFile(url.path).localizedDescription, kind: .error)
      return
    }
    if !NSWorkspace.shared.open(url) {
      setStatus("无法使用默认编辑器打开词典。", kind: .error)
    }
  }

  private func finishSuccessfulAdd(_ message: String, kind: StatusKind = .success) {
    word = ""
    code = ""
    lastSuggestedWord = ""
    personalMatches = []
    personalDictionaryReady = false
    hasBuiltinExactMatch = false
    characterBreakdowns = []
    explanation = "可以继续输入下一个词语。"
    setStatus(message, kind: kind)
  }

  private func clearStatus() {
    statusMessage = ""
    statusKind = .neutral
  }

  private func setStatus(_ message: String, kind: StatusKind) {
    statusMessage = message
    statusKind = kind
  }
}
