import Foundation

public enum SchemeDictionaryStatus: Sendable {
  case available(schemaID: String, name: String, entries: [DictionaryEntry])
  case unavailable(String)

  public func check(text: String, code: String) -> DictionaryCheck? {
    guard case .available(_, _, let entries) = self else { return nil }
    let normalizedCode = code.lowercased()
    return DictionaryCheck(
      hasExactMatch: entries.contains { $0.text == text && $0.code == normalizedCode },
      sameTextEntries: entries.filter { $0.text == text && $0.code != normalizedCode },
      sameCodeEntries: entries.filter { $0.code == normalizedCode && $0.text != text }
    )
  }
}

/// 仅缓存成功读取的数据；每次使用前核对所有依赖，缺失或更新时重新读取。
public actor SchemeDictionaryCache {
  private let reader: SchemeDictionaryReader
  private var snapshot: SchemeSnapshot?

  public init(rimeDirectoryURL: URL) {
    reader = SchemeDictionaryReader(rimeDirectoryURL: rimeDirectoryURL)
  }

  public func read() -> SchemeDictionaryStatus {
    guard !Task.isCancelled else { return .unavailable("比对已取消") }
    if let snapshot, snapshot.isCurrent { return snapshot.status }
    let loaded = reader.readSnapshot()
    if case .available = loaded.status { snapshot = loaded } else { snapshot = nil }
    return loaded.status
  }
}

fileprivate enum SchemeFileStamp: Equatable, Sendable {
  case absent
  case present(modified: Date, size: UInt64, inode: UInt64)

  init(_ url: URL) {
    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
      let modified = attributes[.modificationDate] as? Date
    else { self = .absent; return }
    self = .present(
      modified: modified, size: (attributes[.size] as? NSNumber)?.uint64Value ?? 0,
      inode: (attributes[.systemFileNumber] as? NSNumber)?.uint64Value ?? 0)
  }

  var modified: Date? {
    if case .present(let modified, _, _) = self { return modified }
    return nil
  }
}

fileprivate struct SchemeSnapshot: Sendable {
  let status: SchemeDictionaryStatus
  let dependencies: [URL: SchemeFileStamp]
  var isCurrent: Bool { dependencies.allSatisfy { SchemeFileStamp($0.key) == $0.value } }
}

/// 只读Rime最近选择的方案及其已部署主字典，不初始化另一个Rime会话。
public struct SchemeDictionaryReader: Sendable {
  public let rimeDirectoryURL: URL

  public init(rimeDirectoryURL: URL) { self.rimeDirectoryURL = rimeDirectoryURL }

  public func read() -> SchemeDictionaryStatus {
    readSnapshot().status
  }

  fileprivate func readSnapshot() -> SchemeSnapshot {
    var dependencies: [URL: SchemeFileStamp] = [:]
    do {
      let state = try contents("user.yaml", dependencies: &dependencies)
      guard let schemaID = scalar(state, path: ["var", "previously_selected_schema"]),
        ["moc_wubi86_simp", "moc_wubi86_simp_plus"].contains(schemaID)
      else { throw RimeCoreError.invalidText }
      let schema = try contents("build/\(schemaID).schema.yaml", dependencies: &dependencies)
      guard let dictionary = scalar(schema, path: ["translator", "dictionary"]),
        validName(dictionary)
      else { throw RimeCoreError.invalidText }
      let name = scalar(schema, path: ["schema", "name"]) ?? schemaID
      let tableURL = rimeDirectoryURL.appendingPathComponent("build/\(dictionary).table.bin")
      let tableStamp = SchemeFileStamp(tableURL)
      dependencies[tableURL] = tableStamp
      guard let compiledDate = tableStamp.modified else { throw RimeCoreError.invalidText }
      var visited: Set<String> = []
      var stack: Set<String> = []
      var entries: [DictionaryEntry] = []
      try load(
        dictionary, compiledDate: compiledDate, visited: &visited, stack: &stack,
        entries: &entries, dependencies: &dependencies)
      let snapshot = SchemeSnapshot(
        status: .available(schemaID: schemaID, name: name, entries: entries),
        dependencies: dependencies)
      guard snapshot.isCurrent else { throw RimeCoreError.invalidText }
      return snapshot
    } catch {
      return SchemeSnapshot(
        status: .unavailable("方案数据缺失、尚未重新部署或格式无法识别"),
        dependencies: dependencies)
    }
  }

  private func load(
    _ name: String, compiledDate: Date, visited: inout Set<String>,
    stack: inout Set<String>, entries: inout [DictionaryEntry],
    dependencies: inout [URL: SchemeFileStamp]
  ) throws {
    guard validName(name), !stack.contains(name), visited.count < 128 else {
      throw RimeCoreError.invalidText
    }
    if visited.contains(name) { return }
    stack.insert(name)
    defer { stack.remove(name) }
    let url = rimeDirectoryURL.appendingPathComponent("\(name).dict.yaml")
    let stamp = SchemeFileStamp(url)
    dependencies[url] = stamp
    guard
      let modified = stamp.modified,
      modified <= compiledDate
    else { throw RimeCoreError.invalidText }
    let custom = rimeDirectoryURL.appendingPathComponent("\(name).dict.custom.yaml")
    dependencies[custom] = SchemeFileStamp(custom)
    guard !FileManager.default.fileExists(atPath: custom.path)
    else {
      throw RimeCoreError.invalidText
    }
    let source = try String(contentsOf: url, encoding: .utf8)
    guard let marker = source.range(of: "\n...\n") else { throw RimeCoreError.missingDataMarker }
    let header = String(source[..<marker.lowerBound])
    guard !header.contains("__include:"), !header.contains("__patch:") else {
      throw RimeCoreError.invalidText
    }
    let rows = source[marker.upperBound...].split(separator: "\n").filter {
      let trimmed = $0.trimmingCharacters(in: .whitespaces)
      return !trimmed.isEmpty && !trimmed.hasPrefix("#")
    }
    // 空聚合字典无需列声明；有正文时只支持本项目列顺序，不静默漏词。
    let supportedColumns = [["text", "code", "weight"], ["text", "code", "weight", "stem"]]
    guard
      rows.isEmpty || supportedColumns.contains(where: {
        scalar(header, path: ["columns"]) == "[" + $0.joined(separator: ", ") + "]"
          || blockList(header, key: "columns") == $0
      })
    else { throw RimeCoreError.invalidText }
    for line in rows {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
      let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
      guard fields.count >= 3, !fields[0].isEmpty, !fields[1].isEmpty, Int(fields[2]) != nil else {
        throw RimeCoreError.invalidText
      }
    }
    // 手填个人表单独严格核对；它不能用来声称“内置词库已有”。
    if name != "moc_wubi86_user" {
      entries.append(contentsOf: try RimeDictionaryParser.parse(source, source: .core))
    }
    if scalar(header, path: ["import_tables"]) != nil {
      throw RimeCoreError.invalidText  // 不猜测未支持的行内列表或自定义表达式。
    }
    for child in blockList(header, key: "import_tables") {
      try load(
        child, compiledDate: compiledDate, visited: &visited, stack: &stack,
        entries: &entries, dependencies: &dependencies)
    }
    visited.insert(name)
  }

  private func contents(_ path: String, dependencies: inout [URL: SchemeFileStamp]) throws -> String {
    let url = rimeDirectoryURL.appendingPathComponent(path)
    dependencies[url] = SchemeFileStamp(url)
    return try String(contentsOf: url, encoding: .utf8)
  }

  private func validName(_ name: String) -> Bool {
    !name.isEmpty
      && name.unicodeScalars.allSatisfy {
        (48...57).contains($0.value) || (65...90).contains($0.value)
          || (97...122).contains($0.value) || $0 == "_" || $0 == "-"
      }
  }

  private func scalar(_ text: String, path: [String]) -> String? {
    var parents: [(indent: Int, key: String)] = []
    for raw in text.split(separator: "\n") {
      let line = String(raw)
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.hasPrefix("#") || trimmed.hasPrefix("-") { continue }
      guard let colon = trimmed.firstIndex(of: ":") else { continue }
      let indent = line.prefix { $0 == " " }.count
      while parents.last.map({ $0.indent >= indent }) ?? false { parents.removeLast() }
      let key = unquote(String(trimmed[..<colon]))
      let value = String(trimmed[trimmed.index(after: colon)...]).trimmingCharacters(
        in: .whitespaces)
      let current = parents.map(\.key) + [key]
      if current == path, !value.isEmpty { return unquote(value) }
      if value.isEmpty { parents.append((indent, key)) }
    }
    return nil
  }

  private func blockList(_ text: String, key: String) -> [String] {
    var inList = false
    var listIndent = 0
    var values: [String] = []
    for raw in text.split(separator: "\n") {
      let line = String(raw)
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
      let indent = line.prefix { $0 == " " }.count
      if trimmed == "\(key):" {
        inList = true
        listIndent = indent
        continue
      }
      if inList {
        if indent <= listIndent {
          if trimmed.hasPrefix("- ") { return ["UNSUPPORTED/LIST"] }
          break
        }
        guard trimmed.hasPrefix("- ") else { return ["UNSUPPORTED/LIST"] }
        values.append(unquote(String(trimmed.dropFirst(2))))
      }
    }
    return values
  }

  private func unquote(_ text: String) -> String {
    if (text.hasPrefix("\"") && text.hasSuffix("\""))
      || (text.hasPrefix("'") && text.hasSuffix("'"))
    {
      return String(text.dropFirst().dropLast())
    }
    return text
  }
}
