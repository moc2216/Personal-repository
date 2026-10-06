import Foundation

public enum DictionarySource: String, CaseIterable, Sendable {
  case personal
  case core

  public var displayName: String {
    switch self {
    case .personal: "个人词典"
    case .core: "方案词典"
    }
  }
}

public struct DictionaryEntry: Equatable, Hashable, Sendable {
  public let text: String
  public let code: String
  public let weight: Int
  public let stem: String
  public let source: DictionarySource

  public init(
    text: String,
    code: String,
    weight: Int,
    stem: String = "",
    source: DictionarySource
  ) {
    self.text = text
    self.code = code.lowercased()
    self.weight = weight
    self.stem = stem
    self.source = source
  }
}

public struct CharacterBreakdown: Equatable, Hashable, Sendable, Identifiable {
  public let character: String
  public let fullCode: String
  public let selectedCount: Int

  public init(character: String, fullCode: String, selectedCount: Int) {
    self.character = character
    self.fullCode = fullCode.lowercased()
    self.selectedCount = max(0, min(selectedCount, fullCode.count))
  }

  public var id: String { "\(character)-\(fullCode)-\(selectedCount)" }
  public var selectedCode: String { String(fullCode.prefix(selectedCount)) }
}

public struct EncodingSuggestion: Equatable, Sendable {
  public let text: String
  public let code: String
  public let explanation: String
  public let characterBreakdowns: [CharacterBreakdown]

  public init(
    text: String,
    code: String,
    explanation: String,
    characterBreakdowns: [CharacterBreakdown] = []
  ) {
    self.text = text
    self.code = code
    self.explanation = explanation
    self.characterBreakdowns = characterBreakdowns
  }
}

public enum RimeCoreError: Error, Equatable, Sendable {
  case missingDataMarker
  case malformedRow(Int)
  case emptyText
  case invalidText
  case invalidCode
  case invalidWeight
  case missingCharacterCodes([String])
  case exactDuplicate
  case missingFile(String)
  case deploymentUnavailable
  case deploymentFailed(String)
}

extension RimeCoreError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .missingDataMarker:
      "词典缺少正文标记（...），没有写入。"
    case .malformedRow(let line):
      "词典第 \(line) 行格式不正确，没有写入。"
    case .emptyText:
      "请先输入词语。"
    case .invalidText:
      "词语中不能包含制表符或换行。"
    case .invalidCode:
      "编码只能包含 1～4 个英文字母。"
    case .invalidWeight:
      "权重必须是 1～99999 的整数。"
    case .missingCharacterCodes(let characters):
      "找不到“\(characters.joined(separator: "、"))”的完整五笔码，可手动填写编码。"
    case .exactDuplicate:
      "个人词典中已经有完全相同的词语和编码。"
    case .missingFile(let path):
      "找不到文件：\(path)"
    case .deploymentUnavailable:
      "找不到鼠须管程序，词条已保存，但无法自动重新部署。"
    case .deploymentFailed(let message):
      "重新部署请求失败：\(message)"
    }
  }
}

public struct DictionaryCheck: Equatable, Sendable {
  public let hasExactMatch: Bool
  public let sameTextEntries: [DictionaryEntry]
  public let sameCodeEntries: [DictionaryEntry]

  public init(
    hasExactMatch: Bool,
    sameTextEntries: [DictionaryEntry],
    sameCodeEntries: [DictionaryEntry]
  ) {
    self.hasExactMatch = hasExactMatch
    self.sameTextEntries = sameTextEntries
    self.sameCodeEntries = sameCodeEntries
  }
}

public enum AddMode: Sendable {
  case addVariant
  case replaceSameText
}

public struct AddResult: Sendable {
  public let entry: DictionaryEntry
  public let backupURL: URL
  public let replacedCount: Int
  public let sameCodeEntries: [DictionaryEntry]

  public init(
    entry: DictionaryEntry,
    backupURL: URL,
    replacedCount: Int,
    sameCodeEntries: [DictionaryEntry]
  ) {
    self.entry = entry
    self.backupURL = backupURL
    self.replacedCount = replacedCount
    self.sameCodeEntries = sameCodeEntries
  }
}
