import Foundation

public struct WubiEncoder: Sendable {
  private let fullCodeByCharacter: [String: String]

  public init(referenceEntries: [DictionaryEntry]) {
    let singleCharacters = referenceEntries.filter {
      $0.text.count == 1 && Self.isLettersOnly($0.code) && (1...4).contains($0.code.count)
    }
    let grouped = Dictionary(grouping: singleCharacters, by: \.text)
    var fullCodes: [String: String] = [:]
    for (character, entries) in grouped {
      let selected = entries.sorted(by: Self.prefersFullCode).first
      fullCodes[character] = selected?.code
    }
    self.fullCodeByCharacter = fullCodes
  }

  public static func bundled() throws -> WubiEncoder {
    guard let url = Bundle.module.url(forResource: "wubi86", withExtension: "tsv") else {
      throw RimeCoreError.missingFile("内置单字编码表")
    }
    var entries: [DictionaryEntry] = []
    var seen: Set<String> = []
    for (index, line) in try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
      .enumerated()
    {
      if line.hasPrefix("#") { continue }
      let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
      guard fields.count == 2, fields[0].count == 1,
        seen.insert(fields[0]).inserted, Self.isLettersOnly(fields[1]),
        (1...4).contains(fields[1].count)
      else { throw RimeCoreError.malformedRow(index + 1) }
      entries.append(DictionaryEntry(text: fields[0], code: fields[1], weight: 0, source: .core))
    }
    guard entries.count == 6500 else { throw RimeCoreError.malformedRow(1) }
    return WubiEncoder(referenceEntries: entries)
  }

  public func suggest(for rawText: String) throws -> EncodingSuggestion {
    let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { throw RimeCoreError.emptyText }
    guard !text.contains("\t"), !text.contains("\n"), !text.contains("\r") else {
      throw RimeCoreError.invalidText
    }

    let characters = text.map(String.init)
    let availableFullCodes = characters.map { fullCodeByCharacter[$0] }
    let breakdowns = Self.makeBreakdowns(
      characters: characters,
      fullCodes: availableFullCodes
    )

    var missing: [String] = []
    let fullCodes = zip(characters, availableFullCodes).compactMap {
      character, availableCode -> String? in
      guard let code = availableCode else {
        if !missing.contains(character) { missing.append(character) }
        return nil
      }
      return code
    }
    guard missing.isEmpty else { throw RimeCoreError.missingCharacterCodes(missing) }

    let code: String
    switch fullCodes.count {
    case 1:
      code = fullCodes[0]
    case 2:
      code = Self.prefix(fullCodes[0], count: 2) + Self.prefix(fullCodes[1], count: 2)
    case 3:
      code =
        Self.prefix(fullCodes[0], count: 1)
        + Self.prefix(fullCodes[1], count: 1)
        + Self.prefix(fullCodes[2], count: 2)
    default:
      code =
        Self.prefix(fullCodes[0], count: 1)
        + Self.prefix(fullCodes[1], count: 1)
        + Self.prefix(fullCodes[2], count: 1)
        + Self.prefix(fullCodes[fullCodes.count - 1], count: 1)
    }

    return EncodingSuggestion(
      text: text,
      code: code,
      explanation: Self.detailedExplanation(for: breakdowns, resultCode: code),
      characterBreakdowns: breakdowns
    )
  }

  private static func makeBreakdowns(
    characters: [String],
    fullCodes: [String?]
  ) -> [CharacterBreakdown] {
    zip(characters, fullCodes).enumerated().compactMap { index, pair in
      let (character, fullCode) = pair
      guard let fullCode else { return nil }
      return CharacterBreakdown(
        character: character,
        fullCode: fullCode,
        selectedCount: selectedCount(
          at: index, wordLength: characters.count, codeLength: fullCode.count)
      )
    }
  }

  private static func selectedCount(at index: Int, wordLength: Int, codeLength: Int) -> Int {
    switch wordLength {
    case 1:
      codeLength
    case 2:
      2
    case 3:
      index == 2 ? 2 : 1
    default:
      (index < 3 || index == wordLength - 1) ? 1 : 0
    }
  }

  private static func detailedExplanation(
    for breakdowns: [CharacterBreakdown],
    resultCode: String
  ) -> String {
    guard breakdowns.count != 1 else {
      return "\(breakdowns[0].character)采用完整码 \(resultCode)。"
    }
    return "\(selectionDescription(for: breakdowns))，组成 \(resultCode)。"
  }

  private static func selectionDescription(for breakdowns: [CharacterBreakdown]) -> String {
    breakdowns
      .filter { !$0.selectedCode.isEmpty }
      .map { "\($0.character)取 \($0.selectedCode)" }
      .joined(separator: "，")
  }

  private static func prefersFullCode(_ lhs: DictionaryEntry, _ rhs: DictionaryEntry) -> Bool {
    if lhs.code.count != rhs.code.count { return lhs.code.count > rhs.code.count }
    if lhs.weight != rhs.weight { return lhs.weight > rhs.weight }
    return lhs.code < rhs.code
  }

  private static func prefix(_ code: String, count: Int) -> String {
    String(code.prefix(count))
  }

  private static func isLettersOnly(_ code: String) -> Bool {
    !code.isEmpty && code.unicodeScalars.allSatisfy { (97...122).contains($0.value) }
  }
}
