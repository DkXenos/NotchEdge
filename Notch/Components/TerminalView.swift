//
//  TerminalView.swift
//  Notch
//
//  Embedded terminal. Spawns /bin/zsh, pipes stdin ↔ stdout/stderr.
//  Architecture: TerminalSession is a plain NSObject — no Combine, no
//  ObservableObject, no @Published. State flows into SwiftUI via plain
//  callbacks, keeping the two worlds fully decoupled.

import SwiftUI
import AppKit

// MARK: - TerminalSession

/// Owns the running shell Process and its I/O pipes.
/// Completely framework-free — no Combine, no ObservableObject.
/// Communicates back to the view via plain callback closures.
final class TerminalSession: NSObject {

    /// Called on main thread whenever new text arrives.
    var onOutput: ((String) -> Void)?

    private var process:    Process?
    private var stdinPipe:  Pipe?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?

    private let homeDir = FileManager.default.homeDirectoryForCurrentUser.path

    override init() { super.init(); start() }
    deinit { stop() }

    // MARK: Lifecycle

    func start() {
        stop()

        let p   = Process()
        let sin = Pipe()
        let sou = Pipe()
        let ser = Pipe()

        p.executableURL       = URL(fileURLWithPath: "/bin/zsh")
        p.arguments           = ["-i"]
        p.currentDirectoryURL = URL(fileURLWithPath: homeDir)
        p.standardInput       = sin
        p.standardOutput      = sou
        p.standardError       = ser
        p.environment         = ProcessInfo.processInfo.environment.merging(
            ["TERM": "xterm-256color", "COLUMNS": "60", "LINES": "20"],
            uniquingKeysWith: { _, new in new }
        )

        sou.fileHandleForReading.readabilityHandler = { [weak self] fh in
            let data = fh.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async { self?.onOutput?(stripANSI(text)) }
        }
        ser.fileHandleForReading.readabilityHandler = { [weak self] fh in
            let data = fh.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async { self?.onOutput?(stripANSI(text)) }
        }

        do    { try p.run() }
        catch { DispatchQueue.main.async { self.onOutput?("Error: \(error.localizedDescription)\n") }; return }

        process    = p
        stdinPipe  = sin
        stdoutPipe = sou
        stderrPipe = ser
    }

    func stop() {
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe?.fileHandleForReading.readabilityHandler = nil
        process?.terminate()
        process = nil; stdinPipe = nil; stdoutPipe = nil; stderrPipe = nil
    }

    func reset() { stop(); start() }

    // MARK: I/O

    func send(_ command: String) {
        guard let pipe = stdinPipe else { return }
        let line = command.hasSuffix("\n") ? command : command + "\n"
        if let data = line.data(using: .utf8) { pipe.fileHandleForWriting.write(data) }
    }
}

// MARK: - ANSI stripper (free function, zero dependencies)

private func stripANSI(_ s: String) -> String {
    var result = ""
    var i = s.startIndex
    while i < s.endIndex {
        if s[i] == "\u{1B}", s.index(after: i) < s.endIndex {
            let next = s.index(after: i)
            if s[next] == "[" {
                var j = s.index(after: next)
                while j < s.endIndex && !s[j].isLetter { j = s.index(after: j) }
                if j < s.endIndex { j = s.index(after: j) }
                i = j; continue
            } else if s[next] == "]" {
                var j = s.index(after: next)
                while j < s.endIndex && s[j] != "\u{07}" && s[j] != "\u{1B}" { j = s.index(after: j) }
                if j < s.endIndex { j = s.index(after: j) }
                i = j; continue
            }
        }
        result.append(s[i])
        i = s.index(after: i)
    }
    return result
}

// MARK: - TerminalView

struct TerminalView: View {

    var onBack: (() -> Void)? = nil

    // Plain @State — no ObservableObject, no Combine, no @StateObject
    @State private var session     = TerminalSession()
    @State private var output      = ""
    @State private var inputText   = ""
    @State private var history:    [String] = []
    @State private var historyIdx: Int      = -1

    var body: some View {
        VStack(spacing: 0) {

            // ── Top bar ───────────────────────────────────────────────────
            HStack(spacing: 8) {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(.white.opacity(0.10)))
                }
                .buttonStyle(.plain)

                HStack(spacing: 5) {
                    Image("terminal")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .foregroundStyle(.white.opacity(0.75))
                    Text("Terminal")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button(action: resetSession) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 9, weight: .bold))
                        Text("Reset")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.white.opacity(0.10)))
                    .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(.white.opacity(0.15), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Rectangle().fill(.white.opacity(0.08)).frame(height: 0.5).padding(.horizontal, 12)

            // ── Output ────────────────────────────────────────────────────
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    Text(output.isEmpty ? " " : output)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.green.opacity(0.90))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .id("bottom")
                }
                .onChange(of: output) { _, _ in
                    withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }
            .frame(maxHeight: .infinity)
            .background(Color.black.opacity(0.30))

            Rectangle().fill(.white.opacity(0.08)).frame(height: 0.5).padding(.horizontal, 12)

            // ── Input ─────────────────────────────────────────────────────
            HStack(spacing: 8) {
                Text("❯")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green.opacity(0.80))

                TerminalInputField(
                    text:          $inputText,
                    onSubmit:      submitCommand,
                    onHistoryUp:   historyUp,
                    onHistoryDown: historyDown
                )
                .frame(height: 20)

                if !inputText.isEmpty {
                    Button(action: submitCommand) {
                        Image(systemName: "return")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.green.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .onAppear {
            session.onOutput = { text in
                output += text
                if output.count > 4000 { output = String(output.suffix(3500)) }
            }
        }
    }

    // MARK: - Actions

    private func resetSession() {
        output = ""
        session.reset()
    }

    private func submitCommand() {
        let cmd = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }
        history.append(cmd)
        historyIdx = -1
        session.send(cmd)
        inputText = ""
    }

    private func historyUp() {
        guard !history.isEmpty else { return }
        historyIdx = min(historyIdx + 1, history.count - 1)
        inputText  = history[history.count - 1 - historyIdx]
    }

    private func historyDown() {
        guard historyIdx > 0 else { historyIdx = -1; inputText = ""; return }
        historyIdx -= 1
        inputText   = history[history.count - 1 - historyIdx]
    }
}

// MARK: - TerminalInputField

private struct TerminalInputField: NSViewRepresentable {
    @Binding var text: String
    var onSubmit:      () -> Void
    var onHistoryUp:   () -> Void
    var onHistoryDown: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let f = NSTextField()
        f.delegate          = context.coordinator
        f.isBordered        = false
        f.isBezeled         = false
        f.drawsBackground   = false
        f.focusRingType     = .none
        f.font              = .monospacedSystemFont(ofSize: 11, weight: .regular)
        f.textColor         = .white
        f.placeholderString = "type a command…"
        f.cell?.isScrollable             = true
        f.cell?.wraps                    = false
        f.cell?.truncatesLastVisibleLine = false
        return f
    }

    func updateNSView(_ v: NSTextField, context: Context) {
        if v.stringValue != text { v.stringValue = text }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: TerminalInputField
        init(_ p: TerminalInputField) { parent = p }

        func controlTextDidChange(_ obj: Notification) {
            guard let f = obj.object as? NSTextField else { return }
            parent.text = f.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView,
                     doCommandBy sel: Selector) -> Bool {
            switch sel {
            case #selector(NSResponder.insertNewline(_:)):  parent.onSubmit();      return true
            case #selector(NSResponder.moveUp(_:)):         parent.onHistoryUp();   return true
            case #selector(NSResponder.moveDown(_:)):       parent.onHistoryDown(); return true
            default: return false
            }
        }
    }
}

#Preview {
    TerminalView()
        .frame(width: DrawerWindow.drawerWidth, height: DrawerWindow.drawerHeight)
        .background(Color(white: 0.07))
}
