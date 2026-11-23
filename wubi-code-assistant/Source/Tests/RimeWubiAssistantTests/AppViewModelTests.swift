import AppKit
import Foundation
import RimeWubiCore
import XCTest

@testable import RimeWubiAssistant

final class AppViewModelTests: XCTestCase {
  @MainActor
  func testGenerationReturnsBeforeDuplicateIOAndDisablesAddUntilChecked() async throws {
    let (model, root) = try fixture(rows: "")
    defer { try? FileManager.default.removeItem(at: root) }
    try addBuiltin(to: root)
    model.word = "仓位"
    model.generateSuggestion()
    XCTAssertEqual(model.code, "wbwu")
    XCTAssertFalse(model.canRequestAdd, "查重应在后台完成，等待期间不能使用旧结果添加")
    XCTAssertFalse(model.hasBuiltinExactMatch)
    await model.duplicateTask?.value
    XCTAssertTrue(model.hasBuiltinExactMatch)
    XCTAssertTrue(model.canRequestAdd)
  }

  @MainActor
  func testLatestManualCodeWinsOverPendingDuplicateResult() async throws {
    let (model, root) = try fixture(rows: "仓位\tzzzz\t50000\n")
    defer { try? FileManager.default.removeItem(at: root) }
    try addBuiltin(to: root)
    model.word = "仓位"
    model.generateSuggestion()
    let previous = model.duplicateTask
    model.code = "zzzz"
    model.refreshDuplicateStatus()
    await previous?.value
    await model.duplicateTask?.value
    XCTAssertEqual(model.code, "zzzz")
    XCTAssertFalse(model.hasBuiltinExactMatch)
    XCTAssertFalse(model.canRequestAdd)
    XCTAssertTrue(model.statusMessage.contains("个人词库已有同词同码"))
  }

  @MainActor
  func testClearingAndCompositionCannotApplyPendingResult() async throws {
    let (model, root) = try fixture(rows: "")
    defer { try? FileManager.default.removeItem(at: root) }
    model.word = "仓位"
    model.generateSuggestion()
    let previous = model.duplicateTask
    model.wordDidChange("", isComposing: false)
    await previous?.value
    XCTAssertFalse(model.canRequestAdd)
    XCTAssertTrue(model.code.isEmpty)
    model.wordDidChange("仓位", isComposing: true)
    XCTAssertTrue(model.code.isEmpty)
    XCTAssertFalse(model.canRequestAdd)
    model.wordDidChange("仓位", isComposing: false)
    XCTAssertEqual(model.code, "wbwu", "组合输入提交后应立即生成，不额外等待260毫秒")
    await model.duplicateTask?.value
    XCTAssertTrue(model.canRequestAdd)
  }

  @MainActor
  func testPersonalEditAfterCheckOrConfirmationStillBlocksDuplicateWrite() async throws {
    let (model, root) = try fixture(rows: "")
    defer { try? FileManager.default.removeItem(at: root) }
    let user = root.appendingPathComponent("moc_wubi86_user.dict.yaml")
    let empty = try String(contentsOf: user, encoding: .utf8)
    let duplicate = empty + "仓位\twbwu\t50000\n"
    model.word = "仓位"
    model.generateSuggestion()
    await model.duplicateTask?.value
    try duplicate.write(to: user, atomically: true, encoding: .utf8)
    model.requestAdd()
    XCTAssertFalse(model.showConfirmation)
    try empty.write(to: user, atomically: true, encoding: .utf8)
    model.requestAdd()
    XCTAssertTrue(model.showConfirmation)
    try duplicate.write(to: user, atomically: true, encoding: .utf8)
    model.confirmAdd(mode: .addVariant)
    XCTAssertEqual(try String(contentsOf: user, encoding: .utf8), duplicate)
    XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("backups").path))
  }

  @MainActor
  func testFinishingUnchangedWordEditingDoesNotOverwriteManualCode() async throws {
    let (model, root) = try fixture(rows: "")
    defer { try? FileManager.default.removeItem(at: root) }
    model.word = "仓位"
    model.generateSuggestion()
    await model.duplicateTask?.value
    model.wordDidChange("仓位", isComposing: false)
    model.code = "zzzz"
    try await Task.sleep(nanoseconds: 500_000_000)
    XCTAssertEqual(model.code, "zzzz")
    // 清空后重新输入相同词语，仍须重新生成，不能沿用上一次的显示状态。
    model.wordDidChange("", isComposing: false)
    model.wordDidChange("仓位", isComposing: false)
    try await Task.sleep(nanoseconds: 500_000_000)
    XCTAssertEqual(model.code, "wbwu")
    XCTAssertFalse(model.characterBreakdowns.isEmpty)
  }

  @MainActor
  func testRuleCodeIsNotOverriddenByPersonalCode() async throws {
    let (model, root) = try fixture(rows: "仓位\tzzzz\t50000\t\n")
    defer { try? FileManager.default.removeItem(at: root) }
    model.word = "仓位"
    model.generateSuggestion()
    await model.duplicateTask?.value
    XCTAssertEqual(model.code, "wbwu")
    XCTAssertTrue(model.canRequestAdd)
    model.requestAdd()
    XCTAssertTrue(model.canReplaceExistingText)
    XCTAssertTrue(model.confirmationMessage.contains("zzzz"))
  }

  @MainActor
  func testExactPersonalDuplicateIsBlockedAndManualVariantIsAllowed() async throws {
    let (model, root) = try fixture(rows: "仓位\twbwu\t50000\t\n")
    defer { try? FileManager.default.removeItem(at: root) }
    model.word = "仓位"
    model.generateSuggestion()
    await model.duplicateTask?.value
    XCTAssertFalse(model.canRequestAdd)
    model.requestAdd()
    XCTAssertFalse(model.showConfirmation)
    model.code = "zzzz"
    model.refreshDuplicateStatus()
    await model.duplicateTask?.value
    XCTAssertTrue(model.canRequestAdd)
    model.requestAdd()
    XCTAssertTrue(model.showConfirmation)
    XCTAssertTrue(model.canReplaceExistingText)
  }

  @MainActor
  func testMissingSchemeDoesNotPreventGenerationAndIsExplicitBeforeAdding() async throws {
    let (model, root) = try fixture(rows: "")
    defer { try? FileManager.default.removeItem(at: root) }
    model.word = "仓位"
    model.generateSuggestion()
    await model.duplicateTask?.value
    XCTAssertEqual(model.code, "wbwu")
    XCTAssertTrue(model.statusMessage.contains("未完成"))
    model.requestAdd()
    XCTAssertTrue(model.showConfirmation)
    XCTAssertTrue(model.confirmationMessage.contains("未完成"))
  }

  @MainActor
  func testMissingPersonalDictionaryAllowsGenerationButBlocksWrite() async throws {
    let (model, root) = try fixture(rows: "")
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.removeItem(at: root.appendingPathComponent("moc_wubi86_user.dict.yaml"))
    model.word = "仓位"
    model.generateSuggestion()
    await model.duplicateTask?.value
    XCTAssertEqual(model.code, "wbwu")
    XCTAssertFalse(model.canRequestAdd)
    model.requestAdd()
    XCTAssertFalse(model.showConfirmation)
  }

  @MainActor
  func testBuiltinExactMatchRequiresExplicitPersonalConfirmation() async throws {
    let (model, root) = try fixture(rows: "")
    defer { try? FileManager.default.removeItem(at: root) }
    try addBuiltin(to: root)
    model.word = "仓位"
    model.generateSuggestion()
    await model.duplicateTask?.value
    XCTAssertTrue(model.hasBuiltinExactMatch)
    XCTAssertTrue(model.canRequestAdd)
    model.requestAdd()
    XCTAssertTrue(model.confirmationMessage.contains("通常无需添加"))
    XCTAssertTrue(model.showConfirmation)
    // 修改编码后必须按最终编码重新比对，不沿用先前相同结论。
    model.code = "zzzz"
    model.refreshDuplicateStatus()
    await model.duplicateTask?.value
    model.requestAdd()
    XCTAssertFalse(model.hasBuiltinExactMatch)
    XCTAssertTrue(model.confirmationMessage.contains("wbwu"))
  }

  @MainActor
  func testConfirmedWriteUsesFixtureAndMakesBackup() async throws {
    let (model, root) = try fixture(rows: "")
    defer { try? FileManager.default.removeItem(at: root) }
    let dictionary = root.appendingPathComponent("moc_wubi86_user.dict.yaml")
    let before = try Data(contentsOf: dictionary)
    model.word = "仓位"
    model.generateSuggestion()
    await model.duplicateTask?.value
    model.requestAdd()
    XCTAssertTrue(model.showConfirmation)
    XCTAssertEqual(try Data(contentsOf: dictionary), before)
    model.confirmAdd(mode: .addVariant)
    XCTAssertTrue(
      try String(contentsOf: dictionary, encoding: .utf8).contains("仓位\twbwu\t50000\n"))
    let backups = try FileManager.default.contentsOfDirectory(
      at: root.appendingPathComponent("backups"), includingPropertiesForKeys: nil)
    XCTAssertEqual(backups.count, 1)
    XCTAssertEqual(try Data(contentsOf: backups[0]), before)
    XCTAssertTrue(model.statusMessage.contains("词条已经安全保存"))  // 没有调用真实鼠须管。
  }

  @MainActor
  func testLastWindowCloseRequestsTermination() async {
    XCTAssertTrue(
      AppDelegate().applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared))
  }

  @MainActor
  private func fixture(rows: String) throws -> (AppViewModel, URL) {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let user = root.appendingPathComponent("moc_wubi86_user.dict.yaml")
    try ("name: moc_wubi86_user\ncolumns: [text, code, weight]\n...\n" + rows).write(
      to: user, atomically: true, encoding: .utf8)
    let environment = RimeEnvironment(
      rimeDirectoryURL: root, userDictionaryURL: user,
      backupDirectoryURL: root.appendingPathComponent("backups"), squirrelExecutableURL: nil)
    return (AppViewModel(environment: environment), root)
  }

  private func addBuiltin(to root: URL) throws {
    let fm = FileManager.default
    try fm.createDirectory(
      at: root.appendingPathComponent("build"), withIntermediateDirectories: true)
    try "var:\n  previously_selected_schema: moc_wubi86_simp\n".write(
      to: root.appendingPathComponent("user.yaml"), atomically: true, encoding: .utf8)
    try "schema:\n  name: 测试纯净\ntranslator:\n  dictionary: moc_wubi86_simp\n".write(
      to: root.appendingPathComponent("build/moc_wubi86_simp.schema.yaml"), atomically: true,
      encoding: .utf8)
    try "columns: [text, code, weight, stem]\n...\n仓位\twbwu\t40000\n".write(
      to: root.appendingPathComponent("moc_wubi86_simp.dict.yaml"), atomically: true,
      encoding: .utf8)
    let table = root.appendingPathComponent("build/moc_wubi86_simp.table.bin")
    try Data().write(to: table)
    try fm.setAttributes(
      [.modificationDate: Date().addingTimeInterval(2)], ofItemAtPath: table.path)
  }
}
