import Foundation

public enum RimeDictionaryParser {
  public static func parse(
    _ contents: String,
    source: DictionarySource,
    strict: Bool = false
  ) throws -> [DictionaryEntry] {
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
    guard
      let markerIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "..." }
      )
    else {
      throw RimeCoreError.missingDataMarker
    }

    guard markerIndex + 1 < lines.count else { return [] }

    var entries: [DictionaryEntry] = []
    for (offset, rawLine) in lines[(markerIndex + 1)...].enumerated() {
      let lineNumber = markerIndex + offset + 2
      let line = String(rawLine)
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.isEmpty || trimmed.hasPrefix("#") {
        continue
      }

      let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
      guard fields.count >= 3, !fields[0].isEmpty, !fields[1].isEmpty else {
        if strict { throw RimeCoreError.malformedRow(lineNumber) }
        continue
      }
      guard let weight = Int(fields[2]) else {
        if strict { throw RimeCoreError.malformedRow(lineNumber) }
        continue
      }
      entries.append(
        DictionaryEntry(
          text: fields[0],
          code: fields[1],
          weight: weight,
          stem: fields.count > 3 ? fields[3] : "",
          source: source
        )
      )
    }
    return entries
  }

  public static func parseFile(
    at url: URL,
    source: DictionarySource,
    strict: Bool = false
  ) throws -> [DictionaryEntry] {
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw RimeCoreError.missingFile(url.path)
    }
    let contents = try String(contentsOf: url, encoding: .utf8)
    return try parse(contents, source: source, strict: strict)
  }
}
