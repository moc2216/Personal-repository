import AppKit
import RimeWubiCore
import SwiftUI

struct ContentView: View {
  @ObservedObject var model: AppViewModel

  var body: some View {
    VStack(spacing: 0) {
      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: 16) {
          header
          wordInput
          suggestion
          decomposition
          weight
        }
        .padding(EdgeInsets(top: 20, leading: 24, bottom: 20, trailing: 24))
        .frame(maxWidth: .infinity)
      }
      Divider()
      VStack(alignment: .leading, spacing: 12) {
        status
        addButton
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 16)
    }
    .toolbar { lowFrequencyMenu }
    .alert(
      model.hasBuiltinExactMatch ? "词库已有此词，仍添加个人词条？" : "确认添加", isPresented: $model.showConfirmation
    ) {
      Button("取消", role: .cancel) {}
      if model.canReplaceExistingText {
        Button("替换旧编码", role: .destructive) {
          model.confirmAdd(mode: .replaceSameText)
        }
        Button("保留并新增") {
          model.confirmAdd(mode: .addVariant)
        }
      } else {
        Button(model.hasBuiltinExactMatch ? "仍添加个人词条" : "确认添加") {
          model.confirmAdd(mode: .addVariant)
        }
      }
    } message: {
      Text(model.confirmationMessage)
    }
  }

  private var header: some View {
    HStack {
      Spacer()
      Text("五笔编码助手")
        .font(.system(size: 25, weight: .bold))
      Spacer()
    }
  }

  private var wordInput: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("输入词语")
        .font(.headline)
      IMEAwareTextField(
        text: $model.word,
        placeholder: "请输入常用简体词语",
        focusesInitially: true
      ) { value, isComposing in
        model.wordDidChange(value, isComposing: isComposing)
      }
    }
  }

  private var suggestion: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("建议编码")
        .font(.headline)
      IMEAwareTextField(
        text: $model.code,
        placeholder: "自动生成，也可手动修改",
        font: .monospacedSystemFont(ofSize: 18, weight: .semibold)
      ) { _, _ in model.refreshDuplicateStatus() }
      Text(model.explanation)
        .font(.callout)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 18, alignment: .leading)
    }
  }

  private var decomposition: some View {
    VStack(alignment: .leading, spacing: 9) {
      Label("拆字取码", systemImage: "square.grid.2x2")
        .font(.headline)

      Group {
        if model.characterBreakdowns.isEmpty {
          HStack {
            Spacer()
            Text("输入完成后，这里会逐字显示拆字图和实际取码。")
              .font(.callout)
              .foregroundStyle(.tertiary)
            Spacer()
          }
          .frame(height: 96)
        } else {
          VStack(spacing: 0) {
            breakdownRows

            Divider()
            ResultCodeRow(breakdowns: model.characterBreakdowns, resultCode: model.code)
              .padding(.vertical, 12)
          }
        }
      }
      .background(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(Color(nsColor: .controlBackgroundColor))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 1)
      )
    }
  }

  private var breakdownRows: some View {
    LazyVStack(spacing: 0) {
      ForEach(Array(model.characterBreakdowns.enumerated()), id: \.offset) { index, item in
        CharacterBreakdownRow(item: item)
        if index != model.characterBreakdowns.indices.last {
          Divider().padding(.leading, 104)
        }
      }
    }
  }

  private var weight: some View {
    HStack(spacing: 10) {
      Text("权重")
        .font(.headline)
      TextField("50000", text: $model.weightText)
        .textFieldStyle(.roundedBorder)
        .frame(width: 112)
      Text("默认 50000；需要时可直接修改。")
        .font(.callout)
        .foregroundStyle(.secondary)
      Spacer()
    }
  }

  @ViewBuilder
  private var status: some View {
    if !model.statusMessage.isEmpty {
      Label(model.statusMessage, systemImage: statusIcon)
        .font(.callout)
        .foregroundStyle(statusColor)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var addButton: some View {
    HStack {
      Spacer()
      Button {
        model.requestAdd()
      } label: {
        if model.isBusy {
          ProgressView()
            .controlSize(.small)
            .frame(width: 152)
        } else {
          Text("添加并重新部署")
            .frame(width: 152)
        }
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(!model.canRequestAdd)
    }
  }

  @ToolbarContentBuilder
  private var lowFrequencyMenu: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Menu {
        Button("在访达中显示词典文件", systemImage: "folder") {
          model.revealDictionary()
        }
        Button("用默认编辑器打开词典", systemImage: "square.and.pencil") {
          model.openDictionary()
        }
      } label: {
        Image(systemName: "ellipsis.circle")
      }
      .help("更多")
    }
  }

  private var statusIcon: String {
    switch model.statusKind {
    case .neutral: "info.circle"
    case .success: "checkmark.circle.fill"
    case .warning: "exclamationmark.triangle.fill"
    case .error: "xmark.circle.fill"
    }
  }

  private var statusColor: Color {
    switch model.statusKind {
    case .neutral: .secondary
    case .success: .green
    case .warning: .orange
    case .error: .red
    }
  }
}

private struct CharacterBreakdownRow: View {
  let item: CharacterBreakdown

  var body: some View {
    HStack(spacing: 16) {
      VStack(spacing: 5) {
        Text(item.character)
          .font(.system(size: 30, weight: .medium))
        HighlightedCode(code: item.fullCode, selectedCount: item.selectedCount)
      }
      .frame(width: 88)

      Divider()
        .padding(.vertical, 12)

      DecompositionImage(character: item.character, fullCode: item.fullCode)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 7)
    .fixedSize(horizontal: false, vertical: true)
    .opacity(item.selectedCount == 0 ? 0.48 : 1)
  }
}

private struct HighlightedCode: View {
  let code: String
  let selectedCount: Int

  var body: some View {
    HStack(spacing: 1) {
      ForEach(Array(code.enumerated()), id: \.offset) { index, character in
        Text(String(character))
          .foregroundStyle(
            index < selectedCount ? Color.accentColor : Color.secondary.opacity(0.55))
      }
    }
    .font(.system(size: 16, weight: .semibold, design: .monospaced))
    .accessibilityLabel("完整编码 \(code)，取前 \(selectedCount) 码")
  }
}

private struct DecompositionImage: View {
  let character: String
  let fullCode: String

  var body: some View {
    if let imageURL = Bundle.main.url(
      forResource: character,
      withExtension: "gif",
      subdirectory: "Decomposition"
    ), let image = NSImage(contentsOf: imageURL) {
      Image(nsImage: image)
        .resizable()
        .interpolation(.high)
        .scaledToFit()
        .accessibilityLabel("\(character) 的五笔拆字图，完整编码 \(fullCode)")
    } else {
      HStack(spacing: 12) {
        Image(systemName: "character.book.closed")
          .font(.title2)
        Text("暂无这个字的拆字图；完整码为 \(fullCode)。")
          .font(.callout)
      }
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity)
    }
  }
}

private struct ResultCodeRow: View {
  let breakdowns: [CharacterBreakdown]
  let resultCode: String

  private var selectedLetters: [Character] {
    breakdowns.flatMap { Array($0.selectedCode) }
  }

  var body: some View {
    HStack(spacing: 8) {
      Spacer()
      ForEach(Array(selectedLetters.enumerated()), id: \.offset) { _, letter in
        Text(String(letter))
          .font(.system(size: 15, weight: .bold, design: .monospaced))
          .foregroundStyle(.white)
          .frame(width: 30, height: 28)
          .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6))
      }
      Image(systemName: "arrow.right")
        .foregroundStyle(.secondary)
      Text(resultCode)
        .font(.system(size: 22, weight: .bold, design: .monospaced))
        .foregroundStyle(Color.accentColor)
      Spacer()
    }
  }
}
