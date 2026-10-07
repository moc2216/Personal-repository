import Foundation
import XCTest

@testable import RimeWubiCore

final class BundledCharacterTests: XCTestCase {
  func testBundledRulesWorkWithoutInstalledRimeDictionaries() throws {
    let encoder = try WubiEncoder.bundled()
    for (word, code) in [
      ("仓位", "wbwu"), ("普适性", "utnt"), ("回撤", "lkry"), ("人工智能", "watc"), ("我们", "trwu"),
    ] {
      XCTAssertEqual(try encoder.suggest(for: word).code, code)
    }
    // 候选精简删除的字仍可用于个人造词。
    XCTAssertEqual(try encoder.suggest(for: "黼").code, "oguy")
    XCTAssertThrowsError(try encoder.suggest(for: "𠮷"))
  }

  func testAll6500NormativeCharactersHaveIndependentCodes() throws {
    let encoder = try WubiEncoder.bundled()
    let contents = try String(
      contentsOf: XCTUnwrap(Bundle.module.url(forResource: "wubi86", withExtension: "tsv")),
      encoding: .utf8)
    let lines = contents.split(separator: "\n").filter { !$0.hasPrefix("#") }
    XCTAssertEqual(lines.count, 6500)
    for line in lines {
      let fields = line.split(separator: "\t").map(String.init)
      XCTAssertEqual(try encoder.suggest(for: fields[0]).code, fields[1])
    }
  }

  func testIsolatedDeployedDataIfProvided() throws {
    guard let path = ProcessInfo.processInfo.environment["MOC_RIME_TEST_DIR"] else {
      throw XCTSkip("隔离部署验证由维护步骤单独提供，不读取真实用户词库")
    }
    let reader = SchemeDictionaryReader(rimeDirectoryURL: URL(fileURLWithPath: path))
    guard case .available(let schemaID, _, _) = reader.read() else {
      return XCTFail("隔离部署方案未完成读取")
    }
    XCTAssertTrue(reader.read().check(text: "我们", code: "trwu")?.hasExactMatch == true)
    let artificial = reader.read().check(text: "人工智能", code: "watc")
    XCTAssertEqual(artificial?.hasExactMatch, schemaID == "moc_wubi86_simp_plus")
  }
}
