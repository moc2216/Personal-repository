import Foundation

public struct RimeEnvironment: Sendable {
  public let rimeDirectoryURL: URL
  public let userDictionaryURL: URL
  public let backupDirectoryURL: URL
  public let squirrelExecutableURL: URL?

  public init(
    rimeDirectoryURL: URL,
    userDictionaryURL: URL,
    backupDirectoryURL: URL,
    squirrelExecutableURL: URL?
  ) {
    self.rimeDirectoryURL = rimeDirectoryURL
    self.userDictionaryURL = userDictionaryURL
    self.backupDirectoryURL = backupDirectoryURL
    self.squirrelExecutableURL = squirrelExecutableURL
  }

  public static func current(fileManager: FileManager = .default) -> RimeEnvironment {
    let rimeDirectory = fileManager.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Rime", isDirectory: true)
    let systemSquirrel = URL(
      fileURLWithPath: "/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel")
    let userSquirrel = fileManager.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel")
    let executable = [systemSquirrel, userSquirrel].first {
      fileManager.isExecutableFile(atPath: $0.path)
    }
    return RimeEnvironment(
      rimeDirectoryURL: rimeDirectory,
      userDictionaryURL: rimeDirectory.appendingPathComponent("moc_wubi86_user.dict.yaml"),
      backupDirectoryURL: rimeDirectory.appendingPathComponent(
        ".moc_wubi86_backups", isDirectory: true),
      squirrelExecutableURL: executable
    )
  }
}

public struct SquirrelReloader: Sendable {
  public let executableURL: URL?

  public init(executableURL: URL?) {
    self.executableURL = executableURL
  }

  public func requestReload() throws {
    guard let executableURL else { throw RimeCoreError.deploymentUnavailable }
    let process = Process()
    let output = Pipe()
    process.executableURL = executableURL
    process.arguments = ["--reload"]
    process.standardOutput = output
    process.standardError = output
    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      throw RimeCoreError.deploymentFailed(error.localizedDescription)
    }
    guard process.terminationStatus == 0 else {
      let data = output.fileHandleForReading.readDataToEndOfFile()
      let message = String(data: data, encoding: .utf8)?.trimmingCharacters(
        in: .whitespacesAndNewlines)
      throw RimeCoreError.deploymentFailed(
        message?.isEmpty == false ? message! : "退出码 \(process.terminationStatus)")
    }
  }
}
