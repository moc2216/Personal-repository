import AppKit
import SwiftUI

struct IMEAwareTextField: View {
  @Binding var text: String
  let placeholder: String
  var font: NSFont = .systemFont(ofSize: 18)
  var focusesInitially = false
  let onChange: (String, Bool) -> Void
  @State private var isFocused = false

  var body: some View {
    NativeTextField(
      text: $text, isFocused: $isFocused, placeholder: placeholder,
      font: font, focusesInitially: focusesInitially, onChange: onChange
    )
    .frame(height: 24)
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
    .overlay {
      RoundedRectangle(cornerRadius: 7)
        .strokeBorder(
          isFocused ? Color.accentColor : Color(nsColor: .separatorColor),
          lineWidth: isFocused ? 2 : 1
        )
    }
  }
}

private struct NativeTextField: NSViewRepresentable {
  @Binding var text: String
  @Binding var isFocused: Bool
  let placeholder: String
  let font: NSFont
  let focusesInitially: Bool
  let onChange: (String, Bool) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  func makeNSView(context: Context) -> NSTextField {
    let field = NSTextField(string: text)
    field.delegate = context.coordinator
    field.placeholderString = placeholder
    field.font = font
    field.isBezeled = false
    field.isBordered = false
    field.drawsBackground = false
    field.focusRingType = .none
    field.usesSingleLineMode = true
    field.lineBreakMode = .byTruncatingTail
    field.setContentHuggingPriority(.defaultLow, for: .horizontal)
    field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    field.setContentCompressionResistancePriority(.required, for: .vertical)

    if focusesInitially {
      DispatchQueue.main.async {
        field.window?.makeFirstResponder(field)
      }
    }
    return field
  }

  func updateNSView(_ field: NSTextField, context: Context) {
    context.coordinator.parent = self
    if field.stringValue != text {
      field.stringValue = text
    }
  }

  final class Coordinator: NSObject, NSTextFieldDelegate {
    var parent: NativeTextField

    init(parent: NativeTextField) {
      self.parent = parent
    }

    func controlTextDidBeginEditing(_ notification: Notification) {
      parent.isFocused = true
    }

    func controlTextDidChange(_ notification: Notification) {
      guard let field = notification.object as? NSTextField else { return }
      let value = field.stringValue
      let isComposing = (field.currentEditor() as? NSTextView)?.hasMarkedText() ?? false
      parent.text = value
      parent.onChange(value, isComposing)
    }

    func controlTextDidEndEditing(_ notification: Notification) {
      parent.isFocused = false
      guard let field = notification.object as? NSTextField else { return }
      let value = field.stringValue
      parent.text = value
      parent.onChange(value, false)
    }
  }
}
