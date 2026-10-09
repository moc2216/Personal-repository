import Foundation

public struct PersonalDictionaryStore: Sendable {
  public let dictionaryURL: URL
  public let backupDirectoryURL: URL

  public init(dictionaryURL: URL, backupDirectoryURL: URL) {
    self.dictionaryURL = dictionaryURL
    self.backupDirectoryURL = backupDirectoryURL
  }

  public func inspect(text rawText: String, code rawCode: String) throws -> DictionaryCheck {
    let (text, code) = try Self.validate(text: rawText, code: rawCode, weight: nil)
    let entries = try RimeDictionaryParser.parseFile(
      at: dictionaryURL, source: .personal, strict: true)
    return Self.check(entries: entries, text: text, code: code)
  }

  @discardableResult
  public func add(
    text rawText: String,
    code rawCode: String,
    weight: Int,
    mode: AddMode
  ) throws -> AddResult {
    let (text, code) = try Self.validate(text: rawText, code: rawCode, weight: weight)
    guard FileManager.default.fileExists(atPath: dictionaryURL.path) else {
      throw RimeCoreError.missingFile(dictionaryURL.path)
    }

    let originalData = try Data(contentsOf: dictionaryURL)
    guard let original = String(data: originalData, encoding: .utf8) else {
      throw RimeCoreError.malformedRow(1)
    }
    let entries = try RimeDictionaryParser.parse(original, source: .personal, strict: true)
    let check = Self.check(entries: entries, text: text, code: code)
    guard !check.hasExactMatch else { throw RimeCoreError.exactDuplicate }

    var updated = original
    var replacedCount = 0
    if mode == .replaceSameText {
      let result = Self.removingEntries(for: text, from: updated)
      updated = result.contents
      replacedCount = result.removedCount
    }
    if !updated.hasSuffix("\n") { updated.append("\n") }
    updated.append("\(text)\t\(code)\t\(weight)\n")

    let parsedUpdated = try RimeDictionaryParser.parse(updated, source: .personal, strict: true)
    guard
      parsedUpdated.contains(where: { $0.text == text && $0.code == code && $0.weight == weight })
    else {
      throw RimeCoreError.malformedRow(updated.split(separator: "\n").count)
    }

    let fileManager = FileManager.default
    try fileManager.createDirectory(at: backupDirectoryURL, withIntermediateDirectories: true)
    let backupURL = backupDirectoryURL.appendingPathComponent(Self.backupFilename())
    try originalData.write(to: backupURL, options: .atomic)

    do {
      try Data(updated.utf8).write(to: dictionaryURL, options: .atomic)
      _ = try RimeDictionaryParser.parseFile(at: dictionaryURL, source: .personal, strict: true)
    } catch {
      try? originalData.write(to: dictionaryURL, options: .atomic)
      throw error
    }

    return AddResult(
      entry: DictionaryEntry(text: text, code: code, weight: weight, source: .personal),
      backupURL: backupURL,
      replacedCount: replacedCount,
      sameCodeEntries: check.sameCodeEntries
    )
  }

  private static func check(
    entries: [DictionaryEntry],
    text: String,
    code: String
  ) -> DictionaryCheck {
    DictionaryCheck(
      hasExactMatch: entries.contains { $0.text == text && $0.code == code },
      sameTextEntries: entries.filter { $0.text == text && $0.code != code },
      sameCodeEntries: entries.filter { $0.code == code && $0.text != text }
    )
  }

  private static func validate(
    text rawText: String,
    code rawCode: String,
    weight: Int?
  ) throws -> (String, String) {
    let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !text.isEmpty else { throw RimeCoreError.emptyText }
    guard !text.contains("\t"), !text.contains("\n"), !text.contains("\r") else {
      throw RimeCoreError.invalidText
    }
    guard (1...4).contains(code.count),
      code.unicodeScalars.allSatisfy({ (97...122).contains($0.value) })
    else {
      throw RimeCoreError.invalidCode
    }
    if let weight, !(1...99_999).contains(weight) {
      throw RimeCoreError.invalidWeight
    }
    return (text, code)
  }

  private static func removingEntries(for text: String, from contents: String) -> (
    contents: String, removedCount: Int
  ) {
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var inData = false
    var kept: [String] = []
    var removedCount = 0
    for line in lines {
      if !inData {
        kept.append(line)
        if line.trimmingCharacters(in: .whitespaces) == "..." { inData = true }
        continue
      }
      let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
      if !line.trimmingCharacters(in: .whitespaces).hasPrefix("#"),
        fields.first.map(String.init) == text
      {
        removedCount += 1
      } else {
        kept.append(line)
      }
    }
    return (kept.joined(separator: "\n"), removedCount)
  }

  private static func backupFilename() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    let suffix = UUID().uuidString.prefix(8)
    return "moc_wubi86_user.\(formatter.string(from: Date()))-\(suffix).dict.yaml"
  }
}
