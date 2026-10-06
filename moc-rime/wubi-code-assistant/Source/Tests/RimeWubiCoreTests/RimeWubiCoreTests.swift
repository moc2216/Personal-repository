import Foundation
import XCTest

@testable import RimeWubiCore

final class RimeWubiCoreTests: XCTestCase {
  private let header = """
    # Rime dictionary
    ---
    name: test
    columns:
      - text
      - code
      - weight
      - stem
    ...
    """ + "\n"

  func testParsesRowsAfterHeaderAndIgnoresComments() throws {
    let contents = header + "# note\n仓\twbb\t40000\t\n仓位\twbwu\t50000\t\n"

    let entries = try RimeDictionaryParser.parse(contents, source: .core, strict: true)

    XCTAssertEqual(entries.map(\.text), ["仓", "仓位"])
    XCTAssertEqual(entries[0].code, "wbb")
    XCTAssertEqual(entries[1].weight, 50_000)
    XCTAssertEqual(entries[1].source, .core)
  }

  func testStrictParserRejectsMalformedDataRow() {
    let contents = header + "坏行\tonly-code\n"

    XCTAssertThrowsError(
      try RimeDictionaryParser.parse(contents, source: .personal, strict: true)
    )
  }

  func testExistingPhraseDoesNotOverrideRuleGeneratedEncoding() throws {
    let entries = [
      DictionaryEntry(text: "我", code: "trnt", weight: 40_000, source: .core),
      DictionaryEntry(text: "们", code: "wun", weight: 40_000, source: .core),
      DictionaryEntry(text: "我们", code: "zzzz", weight: 39_999, source: .core),
    ]

    let suggestion = try WubiEncoder(referenceEntries: entries).suggest(for: "我们")

    XCTAssertEqual(suggestion.code, "trwu")
    XCTAssertEqual(suggestion.explanation, "我取 tr，们取 wu，组成 trwu。")
  }

  func testDerivesTwoCharacterCodeFromCanonicalFullCodes() throws {
    let entries = [
      DictionaryEntry(text: "仓", code: "wb", weight: 80_000, source: .core),
      DictionaryEntry(text: "仓", code: "wbb", weight: 40_000, source: .core),
      DictionaryEntry(text: "位", code: "wu", weight: 80_000, source: .core),
      DictionaryEntry(text: "位", code: "wug", weight: 40_000, source: .core),
    ]

    let suggestion = try WubiEncoder(referenceEntries: entries).suggest(for: "仓位")

    XCTAssertEqual(suggestion.code, "wbwu")
    XCTAssertEqual(suggestion.explanation, "仓取 wb，位取 wu，组成 wbwu。")
    XCTAssertEqual(
      suggestion.characterBreakdowns,
      [
        CharacterBreakdown(character: "仓", fullCode: "wbb", selectedCount: 2),
        CharacterBreakdown(character: "位", fullCode: "wug", selectedCount: 2),
      ]
    )
    XCTAssertEqual(suggestion.characterBreakdowns.map(\.selectedCode), ["wb", "wu"])
  }

  func testDerivesThreeAndFourCharacterCodes() throws {
    let entries = [
      DictionaryEntry(text: "普", code: "uogj", weight: 40_000, source: .core),
      DictionaryEntry(text: "适", code: "tdpd", weight: 40_000, source: .core),
      DictionaryEntry(text: "性", code: "ntgg", weight: 40_000, source: .core),
      DictionaryEntry(text: "人", code: "wwww", weight: 40_000, source: .core),
      DictionaryEntry(text: "工", code: "aaaa", weight: 40_000, source: .core),
      DictionaryEntry(text: "智", code: "tdkj", weight: 40_000, source: .core),
      DictionaryEntry(text: "能", code: "cexx", weight: 40_000, source: .core),
    ]
    let encoder = WubiEncoder(referenceEntries: entries)

    XCTAssertEqual(try encoder.suggest(for: "普适性").code, "utnt")
    XCTAssertEqual(try encoder.suggest(for: "人工智能").code, "watc")
    XCTAssertEqual(
      try encoder.suggest(for: "普适性").characterBreakdowns.map(\.selectedCount),
      [1, 1, 2]
    )
    XCTAssertEqual(
      try encoder.suggest(for: "人工智能").characterBreakdowns.map(\.selectedCount),
      [1, 1, 1, 1]
    )
    XCTAssertEqual(
      try encoder.suggest(for: "人工智能").explanation,
      "人取 w，工取 a，智取 t，能取 c，组成 watc。"
    )
  }

  func testLongPhraseMarksMiddleCharactersAsNotSelected() throws {
    let entries = [
      DictionaryEntry(text: "中", code: "khk", weight: 40_000, source: .core),
      DictionaryEntry(text: "华", code: "wxfj", weight: 40_000, source: .core),
      DictionaryEntry(text: "人", code: "wwww", weight: 40_000, source: .core),
      DictionaryEntry(text: "民", code: "nav", weight: 40_000, source: .core),
      DictionaryEntry(text: "共", code: "awu", weight: 40_000, source: .core),
      DictionaryEntry(text: "和", code: "tkg", weight: 40_000, source: .core),
      DictionaryEntry(text: "国", code: "lgyi", weight: 40_000, source: .core),
    ]

    let suggestion = try WubiEncoder(referenceEntries: entries).suggest(for: "中华人民共和国")

    XCTAssertEqual(suggestion.code, "kwwl")
    XCTAssertEqual(suggestion.characterBreakdowns.map(\.selectedCount), [1, 1, 1, 0, 0, 0, 1])
    XCTAssertEqual(
      suggestion.characterBreakdowns.map(\.selectedCode), ["k", "w", "w", "", "", "", "l"])
  }

  func testReportsCharactersWithoutAFullCode() {
    let entries = [DictionaryEntry(text: "仓", code: "wbb", weight: 40_000, source: .core)]

    XCTAssertThrowsError(try WubiEncoder(referenceEntries: entries).suggest(for: "仓𠮷")) { error in
      XCTAssertEqual(error as? RimeCoreError, .missingCharacterCodes(["𠮷"]))
    }
  }

  func testDictionaryInspectionDistinguishesExactSameTextAndSameCode() throws {
    let fixture = try makeFixture(
      rows: [
        "仓位\twbwu\t50000\t",
        "回撤\tlkry\t50000\t",
        "旧词\twbwu\t45000\t",
      ]
    )
    let store = PersonalDictionaryStore(
      dictionaryURL: fixture.dictionary,
      backupDirectoryURL: fixture.backups
    )

    let exact = try store.inspect(text: "仓位", code: "wbwu")
    XCTAssertTrue(exact.hasExactMatch)

    let sameText = try store.inspect(text: "仓位", code: "zzzz")
    XCTAssertEqual(sameText.sameTextEntries.map(\.code), ["wbwu"])

    let sameCode = try store.inspect(text: "新词", code: "wbwu")
    XCTAssertEqual(Set(sameCode.sameCodeEntries.map(\.text)), Set(["仓位", "旧词"]))
  }

  func testAddPreservesExistingContentCreatesBackupAndUsesFourColumns() throws {
    let fixture = try makeFixture(rows: ["仓位\twbwu\t50000\t"])
    let original = try String(contentsOf: fixture.dictionary, encoding: .utf8)
    let store = PersonalDictionaryStore(
      dictionaryURL: fixture.dictionary,
      backupDirectoryURL: fixture.backups
    )

    let result = try store.add(text: "新词", code: "abcd", weight: 50_000, mode: .addVariant)

    let updated = try String(contentsOf: fixture.dictionary, encoding: .utf8)
    XCTAssertTrue(updated.hasPrefix(original))
    XCTAssertTrue(updated.hasSuffix("新词\tabcd\t50000\t\n"))
    XCTAssertEqual(try String(contentsOf: result.backupURL, encoding: .utf8), original)
  }

  func testReplaceModeRemovesPriorPersonalCodesForSameText() throws {
    let fixture = try makeFixture(rows: [
      "同词\taaaa\t40000\t",
      "保留\tbbbb\t40000\t",
      "同词\tcccc\t45000\t",
    ])
    let store = PersonalDictionaryStore(
      dictionaryURL: fixture.dictionary,
      backupDirectoryURL: fixture.backups
    )

    let result = try store.add(text: "同词", code: "dddd", weight: 50_000, mode: .replaceSameText)

    let updated = try String(contentsOf: fixture.dictionary, encoding: .utf8)
    XCTAssertFalse(updated.contains("同词\taaaa"))
    XCTAssertFalse(updated.contains("同词\tcccc"))
    XCTAssertTrue(updated.contains("保留\tbbbb"))
    XCTAssertTrue(updated.contains("同词\tdddd\t50000\t"))
    XCTAssertEqual(result.replacedCount, 2)
  }

  func testExactDuplicateDoesNotCreateBackupOrModifyFile() throws {
    let fixture = try makeFixture(rows: ["仓位\twbwu\t50000\t"])
    let original = try Data(contentsOf: fixture.dictionary)
    let store = PersonalDictionaryStore(
      dictionaryURL: fixture.dictionary,
      backupDirectoryURL: fixture.backups
    )

    XCTAssertThrowsError(
      try store.add(text: "仓位", code: "WBWU", weight: 50_000, mode: .addVariant)
    ) { error in
      XCTAssertEqual(error as? RimeCoreError, .exactDuplicate)
    }
    XCTAssertEqual(try Data(contentsOf: fixture.dictionary), original)
    XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.backups.path))
  }

  func testRejectsUnsafeTextCodeAndWeight() throws {
    let fixture = try makeFixture(rows: [])
    let store = PersonalDictionaryStore(
      dictionaryURL: fixture.dictionary,
      backupDirectoryURL: fixture.backups
    )

    XCTAssertThrowsError(
      try store.add(text: "坏\t词", code: "abcd", weight: 50_000, mode: .addVariant))
    XCTAssertThrowsError(try store.add(text: "新词", code: "ab1d", weight: 50_000, mode: .addVariant))
    XCTAssertThrowsError(
      try store.add(text: "新词", code: "abcde", weight: 50_000, mode: .addVariant))
    XCTAssertThrowsError(
      try store.add(text: "新词", code: "abcd", weight: 100_000, mode: .addVariant))
  }

  private func makeFixture(rows: [String]) throws -> (dictionary: URL, backups: URL) {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let dictionary = directory.appendingPathComponent("moc_wubi86_user.dict.yaml")
    let contents = header + rows.joined(separator: "\n") + (rows.isEmpty ? "" : "\n")
    try contents.write(to: dictionary, atomically: true, encoding: .utf8)
    return (dictionary, directory.appendingPathComponent(".moc_wubi86_backups", isDirectory: true))
  }
}
