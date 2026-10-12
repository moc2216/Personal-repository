import Foundation
import XCTest

@testable import RimeWubiCore

final class SchemeDictionaryReaderTests: XCTestCase {
  private var root: URL!
  private let marker = "columns: [text, code, weight, stem]\n...\n"

  override func setUpWithError() throws {
    root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("build"), withIntermediateDirectories: true)
    try write(
      "moc_wubi86_core.dict.yaml",
      "name: moc_wubi86_core\n" + marker + "我们\ttrwu\t40000\n旧编码词\tzzzz\t40000\n重码词\twatc\t40000\n")
    try write(
      "moc_wubi86_extra.dict.yaml", "name: moc_wubi86_extra\n" + marker + "人工智能\twatc\t40000\n")
    try write(
      "moc_wubi86_user.dict.yaml", "name: moc_wubi86_user\n" + marker + "个人词\tabcd\t50000\t\n")
    try configure("moc_wubi86_simp", imports: ["moc_wubi86_user", "moc_wubi86_core"])
  }

  override func tearDownWithError() throws { try FileManager.default.removeItem(at: root) }

  func testPureDoesNotClaimUnusedExtraWordsAlreadyExist() throws {
    let status = read()
    XCTAssertTrue(status.check(text: "我们", code: "trwu")!.hasExactMatch)
    XCTAssertFalse(status.check(text: "人工智能", code: "watc")!.hasExactMatch)
    XCTAssertFalse(status.check(text: "个人词", code: "abcd")!.hasExactMatch)
    XCTAssertTrue(
      status.check(text: "旧编码词", code: "xxxx")!.sameTextEntries.contains { $0.code == "zzzz" })
    XCTAssertEqual(status.check(text: "人工智能", code: "watc")!.sameCodeEntries.map(\.text), ["重码词"])
  }

  func testFullUsesOnlyItsImportedTables() throws {
    try configure(
      "moc_wubi86_simp_plus", imports: ["moc_wubi86_user", "moc_wubi86_core", "moc_wubi86_extra"])
    XCTAssertTrue(read().check(text: "人工智能", code: "watc")!.hasExactMatch)
  }

  func testThreeColumnTablesSupportSchemeDuplicateCheck() throws {
    try write("moc_wubi86_user.dict.yaml", "columns: [text, code, weight]\n...\n个人词\tabcd\t50000\n")
    try write("moc_wubi86_core.dict.yaml", "columns:\n  - text\n  - code\n  - weight\n...\n我们\ttrwu\t40000\n")
    XCTAssertEqual(read().check(text: "我们", code: "trwu")?.hasExactMatch, true)
    XCTAssertEqual(read().check(text: "个人词", code: "abcd")?.hasExactMatch, false)
  }

  func testSchemeSwitchIsObservedWithoutRestartingReader() throws {
    let reader = SchemeDictionaryReader(rimeDirectoryURL: root)
    XCTAssertFalse(reader.read().check(text: "人工智能", code: "watc")!.hasExactMatch)
    try configure("moc_wubi86_simp_plus", imports: ["moc_wubi86_extra"])
    XCTAssertTrue(reader.read().check(text: "人工智能", code: "watc")!.hasExactMatch)
  }

  func testMissingStateOrUnknownSchemeDoesNotAssertAbsence() throws {
    try FileManager.default.removeItem(at: root.appendingPathComponent("user.yaml"))
    assertUnavailable()
    try write("user.yaml", "var:\n  previously_selected_schema: other\n")
    assertUnavailable()
    XCTAssertEqual(try WubiEncoder.bundled().suggest(for: "人工智能").code, "watc")
  }

  func testMissingImportedDictionaryIsIncomplete() throws {
    try configure("moc_wubi86_simp_plus", imports: ["moc_wubi86_core", "not_found"])
    assertUnavailable()
  }

  func testModifiedSourceNeedsRedeployment() throws {
    try FileManager.default.setAttributes(
      [.modificationDate: Date().addingTimeInterval(100)],
      ofItemAtPath: root.appendingPathComponent("moc_wubi86_core.dict.yaml").path)
    assertUnavailable()
  }

  func testCyclesAndUnsafeNamesAreIncomplete() throws {
    try configure("moc_wubi86_simp", imports: ["moc_wubi86_simp"])
    assertUnavailable()
    try configure("moc_wubi86_simp", imports: ["../private"])
    assertUnavailable()
  }

  func testNestedImportsAndSharedTablesAreLoadedOnce() throws {
    try write("nested.dict.yaml", "import_tables:\n  - moc_wubi86_core\n" + marker)
    try configure("moc_wubi86_simp", imports: ["nested", "moc_wubi86_core"])
    XCTAssertEqual(read().check(text: "新词", code: "trwu")!.sameCodeEntries.count, 1)
  }

  func testUnrecognizedColumnsAndMalformedRowsAreIncomplete() throws {
    try write("moc_wubi86_core.dict.yaml", "columns: [code, text, weight]\n...\ntrwu\t我们\t40000\n")
    assertUnavailable()
    try write("moc_wubi86_core.dict.yaml", marker + "我们\ttrwu\tpercent%\n")
    assertUnavailable()
  }

  func testEmptyAggregateWithoutColumnsIsSupported() throws {
    try write(
      "moc_wubi86_simp.dict.yaml",
      "name: moc_wubi86_simp\nimport_tables:\n  - moc_wubi86_core\n...\n")
    XCTAssertTrue(read().check(text: "我们", code: "trwu")!.hasExactMatch)
  }

  func testUnresolvedIncludesAndDictionaryPatchesAreIncomplete() throws {
    try write("moc_wubi86_simp.dict.custom.yaml", "patch:\n  import_tables: [other]\n")
    assertUnavailable()
    try FileManager.default.removeItem(
      at: root.appendingPathComponent("moc_wubi86_simp.dict.custom.yaml"))
    try write("moc_wubi86_simp.dict.yaml", "__include: other:/\n...\n")
    assertUnavailable()
    try write("moc_wubi86_simp.dict.yaml", "import_tables:\n- moc_wubi86_extra\n...\n")
    assertUnavailable()
  }

  func testUnsupportedInlineImportsDoNotProduceFalseNegative() throws {
    try write("moc_wubi86_simp.dict.yaml", "import_tables: [moc_wubi86_extra]\n" + marker)
    assertUnavailable()
  }

  private func read() -> SchemeDictionaryStatus {
    SchemeDictionaryReader(rimeDirectoryURL: root).read()
  }

  func testCacheObservesSchemeAndImportChanges() async throws {
    let cache = SchemeDictionaryCache(rimeDirectoryURL: root)
    let pure = await cache.read()
    XCTAssertFalse(pure.check(text: "人工智能", code: "watc")!.hasExactMatch)
    let again = await cache.read()
    XCTAssertTrue(again.check(text: "我们", code: "trwu")!.hasExactMatch)
    try configure("moc_wubi86_simp_plus", imports: ["moc_wubi86_extra"])
    let full = await cache.read()
    XCTAssertTrue(full.check(text: "人工智能", code: "watc")!.hasExactMatch)
    XCTAssertFalse(full.check(text: "我们", code: "trwu")!.hasExactMatch)
    try configure("moc_wubi86_simp_plus", imports: ["moc_wubi86_core"])
    let changedImports = await cache.read()
    XCTAssertFalse(changedImports.check(text: "人工智能", code: "watc")!.hasExactMatch)
    XCTAssertTrue(changedImports.check(text: "我们", code: "trwu")!.hasExactMatch)
  }

  func testCacheRejectsUndeployedChangesAndRefreshesAfterDeployment() async throws {
    let cache = SchemeDictionaryCache(rimeDirectoryURL: root)
    _ = await cache.read()
    try write("moc_wubi86_core.dict.yaml", marker + "更新词\tabcd\t40000\n")
    try FileManager.default.setAttributes(
      [.modificationDate: Date().addingTimeInterval(100)],
      ofItemAtPath: root.appendingPathComponent("moc_wubi86_core.dict.yaml").path)
    let stale = await cache.read()
    XCTAssertNil(stale.check(text: "更新词", code: "abcd"))
    try FileManager.default.setAttributes(
      [.modificationDate: Date().addingTimeInterval(200)],
      ofItemAtPath: root.appendingPathComponent("build/moc_wubi86_simp.table.bin").path)
    let deployed = await cache.read()
    XCTAssertTrue(deployed.check(text: "更新词", code: "abcd")!.hasExactMatch)
    XCTAssertFalse(deployed.check(text: "我们", code: "trwu")!.hasExactMatch)
  }

  func testCacheDetectsAtomicReplacementWithSameSizeAndMtime() async throws {
    let cache = SchemeDictionaryCache(rimeDirectoryURL: root)
    _ = await cache.read()
    let url = root.appendingPathComponent("moc_wubi86_core.dict.yaml")
    let date = try url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate!
    let old = try String(contentsOf: url, encoding: .utf8)
    let new = old.replacingOccurrences(of: "我们", with: "你们")
    XCTAssertEqual(old.utf8.count, new.utf8.count)
    try new.write(to: url, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
    let replaced = await cache.read()
    XCTAssertTrue(replaced.check(text: "你们", code: "trwu")!.hasExactMatch)
    XCTAssertFalse(replaced.check(text: "我们", code: "trwu")!.hasExactMatch)
  }

  func testCacheObservesAddedAndRemovedDictionaryPatch() async throws {
    let cache = SchemeDictionaryCache(rimeDirectoryURL: root)
    _ = await cache.read()
    try write("moc_wubi86_core.dict.custom.yaml", "patch:\n  other: value\n")
    let patched = await cache.read()
    XCTAssertNil(patched.check(text: "我们", code: "trwu"))
    try FileManager.default.removeItem(at: root.appendingPathComponent("moc_wubi86_core.dict.custom.yaml"))
    let restored = await cache.read()
    XCTAssertTrue(restored.check(text: "我们", code: "trwu")!.hasExactMatch)
  }

  func testCacheTracksPersonalDependencyWithoutCallingItBuiltin() async throws {
    let cache = SchemeDictionaryCache(rimeDirectoryURL: root)
    let initial = await cache.read()
    XCTAssertFalse(initial.check(text: "个人词", code: "abcd")!.hasExactMatch)
    try FileManager.default.setAttributes(
      [.modificationDate: Date().addingTimeInterval(100)],
      ofItemAtPath: root.appendingPathComponent("moc_wubi86_user.dict.yaml").path)
    let stale = await cache.read()
    XCTAssertNil(stale.check(text: "个人词", code: "abcd"))
  }

  func testCacheTracksCompiledSchema() async throws {
    let cache = SchemeDictionaryCache(rimeDirectoryURL: root)
    _ = await cache.read()
    try write("build/moc_wubi86_simp.schema.yaml", "translator:\n  dictionary: not_found\n")
    let changed = await cache.read()
    XCTAssertNil(changed.check(text: "我们", code: "trwu"))
  }

  func testCacheDoesNotKeepSuccessWhenTableMissingOrFailureAfterRecovery() async throws {
    let cache = SchemeDictionaryCache(rimeDirectoryURL: root)
    _ = await cache.read()
    try FileManager.default.removeItem(at: root.appendingPathComponent("build/moc_wubi86_simp.table.bin"))
    let missing = await cache.read()
    XCTAssertNil(missing.check(text: "我们", code: "trwu"))
    try configure("moc_wubi86_simp", imports: ["moc_wubi86_core"])
    let recovered = await cache.read()
    XCTAssertTrue(recovered.check(text: "我们", code: "trwu")!.hasExactMatch)
  }
  private func assertUnavailable(file: StaticString = #filePath, line: UInt = #line) {
    if case .available = read() { XCTFail("应该明确显示未完成比对", file: file, line: line) }
    XCTAssertNil(read().check(text: "人工智能", code: "watc"), file: file, line: line)
  }
  private func write(_ name: String, _ text: String) throws {
    try text.write(to: root.appendingPathComponent(name), atomically: true, encoding: .utf8)
  }
  private func configure(_ id: String, imports: [String]) throws {
    try write("user.yaml", "var:\n  previously_selected_schema: \"\(id)\"\n")
    try write(
      "build/\(id).schema.yaml",
      "schema:\n  schema_id: \(id)\n  name: \"测试方案\"\nreverse_lookup:\n  dictionary: ignored\ntranslator:\n  dictionary: \(id)\n"
    )
    try write(
      "\(id).dict.yaml",
      "name: \(id)\nimport_tables:\n" + imports.map { "  - \($0)\n" }.joined() + marker)
    let table = root.appendingPathComponent("build/\(id).table.bin")
    try Data().write(to: table)
    try FileManager.default.setAttributes(
      [.modificationDate: Date().addingTimeInterval(2)], ofItemAtPath: table.path)
  }
}
