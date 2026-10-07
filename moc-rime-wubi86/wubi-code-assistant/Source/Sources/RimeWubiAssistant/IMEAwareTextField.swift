import AppKit
import SwiftUI

struct IMEAwareTextField: NSViewRepresentable {
  @Binding var text: String
  let placeholder: String
  let onChange: (String, Bool) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  func makeNSView(context: Context) -> NSTextField {
    let field = NSTextField(string: text)
    field.delegate = context.coordinator
    field.placeholderString = placeholder
    field.font = .systemFont(ofSize: 18)
    field.controlSize = .large
    field.isBezeled = true
    field.bezelStyle = .roundedBezel
    field.focusRingType = .default
    field.lineBreakMode = .byTruncatingTail

    DispatchQueue.main.async {
      field.window?.makeFirstResponder(field)
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
    var parent: IMEAwareTextField

    init(parent: IMEAwareTextField) {
      self.parent = parent
    }

    func controlTextDidChange(_ notification: Notification) {
      guard let field = notification.object as? NSTextField else { return }
      let value = field.stringValue
      let isComposing = (field.currentEditor() as? NSTextView)?.hasMarkedText() ?? false
      parent.text = value
      parent.onChange(value, isComposing)
    }

    func controlTextDidEndEditing(_ notification: Notification) {
      guard let field = notification.object as? NSTextField else { return }
      let value = field.stringValue
      parent.text = value
      parent.onChange(value, false)
    }
  }
}
