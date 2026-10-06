import Foundation

guard CommandLine.arguments.count == 3 else {
  FileHandle.standardError.write(Data("usage: make-icns.swift ICONSET OUTPUT\n".utf8))
  exit(2)
}

let iconsetURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let iconChunks = [
  ("icp4", "icon_16x16.png"),
  ("icp5", "icon_32x32.png"),
  ("icp6", "icon_32x32@2x.png"),
  ("ic07", "icon_128x128.png"),
  ("ic08", "icon_256x256.png"),
  ("ic09", "icon_512x512.png"),
  ("ic10", "icon_512x512@2x.png"),
]

func bigEndianBytes(_ value: UInt32) -> Data {
  var encoded = value.bigEndian
  return Data(bytes: &encoded, count: MemoryLayout<UInt32>.size)
}

var body = Data()
for (type, filename) in iconChunks {
  let png = try Data(contentsOf: iconsetURL.appendingPathComponent(filename))
  body.append(Data(type.utf8))
  body.append(bigEndianBytes(UInt32(png.count + 8)))
  body.append(png)
}

var icns = Data("icns".utf8)
icns.append(bigEndianBytes(UInt32(body.count + 8)))
icns.append(body)
try icns.write(to: outputURL, options: .atomic)
