//
//  TerminalView.swift
//  Notch
//
//  Embedded PTY terminal — uses forkpty() so the child shell gets a real
//  pseudo-terminal. curses, vim, interactive Python scripts all work.
//
//  Architecture:
//    • TerminalSession   — plain NSObject, no Combine. forkpty() + read loop.
//    • RawKeyCapture     — invisible NSView that becomes first responder and
//                          translates every keyDown into the correct PTY byte
//                          sequence, writing it straight to the master fd.
//                          This is why arrow keys reach curses programs.
//    • TerminalView      — SwiftUI coordinator. Plain @State, callback-wired.

import SwiftUI
import AppKit

// MARK: - TerminalSession

final class TerminalSession: NSObject {

    /// Called on main thread with each new output chunk.
    var onOutput: ((String) -> Void)?

    private(set) var masterFD: Int32 = -1
    private var childPID:  pid_t  = -1
    private var isReading  = false

    private let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    private let cols: UInt16 = 80
    private let rows: UInt16 = 24

    override init() { super.init(); start() }
    deinit { stop() }

    // MARK: Lifecycle

    func start() {
        stop()

        var ws = winsize()
        ws.ws_col = cols; ws.ws_row = rows
        ws.ws_xpixel = 0; ws.ws_ypixel = 0

        var env = ProcessInfo.processInfo.environment
        env["TERM"]     = "xterm-256color"
        env["COLUMNS"]  = "\(cols)"
        env["LINES"]    = "\(rows)"
        env["HOME"]     = homeDir
        var envC = env.map { "\($0.key)=\($0.value)".withCString(strdup) }
        envC.append(nil)
        defer { envC.forEach { free($0) } }

        var master: Int32 = -1
        let pid = withUnsafeMutablePointer(to: &ws) { wsPtr -> pid_t in
            forkpty(&master, nil, nil, wsPtr)
        }

        guard pid >= 0 else {
            onOutput?("forkpty failed: \(String(cString: strerror(errno)))\n")
            return
        }

        if pid == 0 {
            // Child — become zsh
            let shell = "/bin/zsh"
            let args: [UnsafeMutablePointer<CChar>?] = [strdup("zsh"), strdup("-i"), strdup("-l"), nil]
            chdir(homeDir)
            execve(shell, args, envC)
            _exit(1)
        }

        masterFD  = master
        childPID  = pid
        isReading = true

        let t = Thread { [weak self] in self?.readLoop() }
        t.name = "notch.pty.read"
        t.qualityOfService = .userInteractive
        t.start()
    }

    func stop() {
        isReading = false
        if childPID > 0 { kill(childPID, SIGTERM); waitpid(childPID, nil, WNOHANG); childPID = -1 }
        if masterFD >= 0 { Darwin.close(masterFD); masterFD = -1 }
    }

    func reset() { stop(); start() }

    // MARK: Write — raw bytes straight to the PTY master fd

    /// Send a UTF-8 string verbatim — no newline appended.
    /// The caller (RawKeyCapture) is responsible for sending "\r" for Enter.
    func sendRaw(_ text: String) {
        guard masterFD >= 0 else { return }
        text.withCString { ptr in
            _ = write(masterFD, ptr, strlen(ptr))
        }
    }

    func sendRawData(_ data: Data) {
        guard masterFD >= 0, !data.isEmpty else { return }
        data.withUnsafeBytes { ptr in
            _ = write(masterFD, ptr.baseAddress, ptr.count)
        }
    }

    // MARK: Read loop

    private func readLoop() {
        let bufSize = 4096
        var buf = [UInt8](repeating: 0, count: bufSize)
        while isReading && masterFD >= 0 {
            let n = read(masterFD, &buf, bufSize)
            if n <= 0 { break }
            let data = Data(buf[0..<n])
            let text = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .isoLatin1)
                    ?? ""
            let stripped = stripANSI(text)
            DispatchQueue.main.async { [weak self] in self?.onOutput?(stripped) }
        }
        DispatchQueue.main.async { [weak self] in self?.onOutput?("\n[session ended]\n") }
    }
}

// MARK: - ANSI stripper

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
            } else {
                i = s.index(after: next); continue
            }
        }
        result.append(s[i])
        i = s.index(after: i)
    }
    return result
}

// MARK: - RawKeyCapture
//
//  An invisible NSView that sits as first responder over the terminal.
//  Every keyDown is translated into the correct PTY escape sequence and
//  written directly to the session's master fd — no SwiftUI text field in
//  between. This is the only way curses / arrow-key programs receive input.

private final class RawKeyView: NSView {

    var session: TerminalSession?
    /// Mirrors keystrokes so SwiftUI can show a "what you're typing" indicator.
    var onLocalEcho: ((String) -> Void)?
    var onSubmit:    (() -> Void)?      // fired on Return so we can clear echo

    override var acceptsFirstResponder: Bool { true }
    override var isOpaque: Bool { false }

    override func keyDown(with event: NSEvent) {
        guard let session else { return }

        let flags     = event.modifierFlags
        let keyCode   = event.keyCode
        let chars     = event.characters ?? ""
        let charsIgn  = event.charactersIgnoringModifiers ?? ""

        // ── Special keys → PTY escape sequences ──────────────────────────
        // xterm-256color sequences (same as what Terminal.app sends)
        switch keyCode {
        case 125: session.sendRaw("\u{1B}[B");  return   // ↓
        case 126: session.sendRaw("\u{1B}[A");  return   // ↑
        case 123: session.sendRaw("\u{1B}[D");  return   // ←
        case 124: session.sendRaw("\u{1B}[C");  return   // →
        case 36:  // Return / Enter
            session.sendRaw("\r")
            onSubmit?()
            return
        case 48:  // Tab → completion
            session.sendRaw("\t")
            return
        case 51:  // Delete / Backspace
            session.sendRaw("\u{7F}")
            return
        case 116: session.sendRaw("\u{1B}[5~"); return   // Page Up
        case 121: session.sendRaw("\u{1B}[6~"); return   // Page Down
        case 115: session.sendRaw("\u{1B}[H");  return   // Home
        case 119: session.sendRaw("\u{1B}[F");  return   // End
        case 117: session.sendRaw("\u{1B}[3~"); return   // Fwd Delete
        case 53:  session.sendRaw("\u{1B}");    return   // Escape
        default: break
        }

        // ── Ctrl + key ────────────────────────────────────────────────────
        if flags.contains(.control) {
            if let c = charsIgn.unicodeScalars.first {
                let byte = c.value
                if byte >= 64 && byte <= 95 {
                    // Ctrl-A → 0x01, Ctrl-C → 0x03, Ctrl-D → 0x04 …
                    let ctrl = UInt8(byte - 64)
                    session.sendRawData(Data([ctrl]))
                    return
                } else if byte >= 96 && byte <= 122 {
                    let ctrl = UInt8(byte - 96)
                    session.sendRawData(Data([ctrl]))
                    return
                }
            }
        }

        // ── Normal printable characters ───────────────────────────────────
        guard !chars.isEmpty else { return }
        session.sendRaw(chars)
        // Mirror to the echo label so the user can see what they typed
        onLocalEcho?(chars)
    }

    // Accept first-responder automatically when clicked.
    override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }
}

// MARK: - RawKeyCaptureView  (NSViewRepresentable wrapper)

private struct RawKeyCaptureView: NSViewRepresentable {
    var session:     TerminalSession
    var onLocalEcho: (String) -> Void
    var onSubmit:    () -> Void

    func makeNSView(context: Context) -> RawKeyView {
        let v = RawKeyView()
        v.session     = session
        v.onLocalEcho = onLocalEcho
        v.onSubmit    = onSubmit
        return v
    }

    func updateNSView(_ v: RawKeyView, context: Context) {
        v.session     = session
        v.onLocalEcho = onLocalEcho
        v.onSubmit    = onSubmit
    }
}

// MARK: - TerminalView

struct TerminalView: View {

    var onBack: (() -> Void)? = nil

    @State private var session    = TerminalSession()
    @State private var output     = ""
    @State private var echoBuffer = ""      // local echo of in-flight input
    @State private var isFocused  = false

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

            // ── Output + raw key capture ──────────────────────────────────
            // ZStack: ScrollView on bottom, invisible RawKeyCaptureView on top.
            // The capture view is transparent but eats key events — that's the
            // entire point. Clicks on it make it first responder automatically.
            ZStack {
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
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }

                // Invisible key capture layer — covers the full output area.
                RawKeyCaptureView(
                    session:     session,
                    onLocalEcho: { echoBuffer += $0 },
                    onSubmit:    { echoBuffer = ""   }
                )
                .allowsHitTesting(true)
            }
            .frame(maxHeight: .infinity)
            .background(Color.black.opacity(0.30))

            Rectangle().fill(.white.opacity(0.08)).frame(height: 0.5).padding(.horizontal, 12)

            // ── Input echo bar ────────────────────────────────────────────
            // Shows what the user is typing. Not a text field — just a label.
            // All actual input is handled by RawKeyCaptureView above.
            HStack(spacing: 8) {
                Text("❯")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green.opacity(0.80))

                Text(echoBuffer.isEmpty ? " " : echoBuffer)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                // Blinking cursor dot
                Circle()
                    .fill(.green.opacity(0.80))
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .onAppear {
            session.onOutput = { [self] text in
                output += text
                // Trim to last 6 000 chars to avoid unbounded memory growth
                if output.count > 8000 { output = String(output.suffix(6000)) }
            }
        }
    }

    // MARK: - Actions

    private func resetSession() {
        output      = ""
        echoBuffer  = ""
        session.reset()
    }
}

#Preview {
    TerminalView()
        .frame(width: DrawerWindow.drawerWidth, height: DrawerWindow.drawerHeight)
        .background(Color(white: 0.07))
}
