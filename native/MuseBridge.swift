import AppKit
import ApplicationServices
import Foundation

private let museBundleID = "com.meta.endo"

private func read(_ element: AXUIElement, _ name: CFString) -> CFTypeRef? {
    var value: CFTypeRef?
    return AXUIElementCopyAttributeValue(element, name, &value) == .success ? value : nil
}

private func string(_ element: AXUIElement, _ name: CFString) -> String? {
    read(element, name) as? String
}

private func children(_ element: AXUIElement) -> [AXUIElement] {
    read(element, kAXChildrenAttribute as CFString) as? [AXUIElement] ?? []
}

private func windows(_ application: AXUIElement) -> [AXUIElement] {
    read(application, kAXWindowsAttribute as CFString) as? [AXUIElement] ?? []
}

private func label(_ element: AXUIElement) -> String {
    [kAXTitleAttribute, kAXDescriptionAttribute, kAXHelpAttribute, kAXPlaceholderValueAttribute]
        .compactMap { string(element, $0 as CFString) }
        .filter { !$0.isEmpty }
        .joined(separator: " | ")
}

private func relevant(_ text: String) -> Bool {
    text == "Main chat" || text == "New side chat" || text.contains("Dictate a message")
}

private func candidates(in roots: [AXUIElement]) -> [[String: String]] {
    var pending = roots.map { ($0, 0) }
    var found: [[String: String]] = []
    var visited = 0
    while !pending.isEmpty && visited < 4000 {
        let (element, depth) = pending.removeFirst()
        visited += 1
        let title = label(element)
        if string(element, kAXRoleAttribute as CFString) == (kAXButtonRole as String) && relevant(title) {
            found.append([
                "role": string(element, kAXRoleAttribute as CFString) ?? "",
                "label": String(title.prefix(180))
            ])
        }
        if depth < 24 {
            pending.append(contentsOf: children(element).map { ($0, depth + 1) })
        }
    }
    return Array(found.prefix(30))
}

private func frame(_ element: AXUIElement) -> [String: Double]? {
    guard let rawPosition = read(element, kAXPositionAttribute as CFString),
          let rawSize = read(element, kAXSizeAttribute as CFString),
          CFGetTypeID(rawPosition) == AXValueGetTypeID(),
          CFGetTypeID(rawSize) == AXValueGetTypeID() else { return nil }
    let position = unsafeBitCast(rawPosition, to: AXValue.self)
    let size = unsafeBitCast(rawSize, to: AXValue.self)
    var origin = CGPoint.zero
    var dimensions = CGSize.zero
    guard AXValueGetValue(position, .cgPoint, &origin), AXValueGetValue(size, .cgSize, &dimensions) else { return nil }
    return ["x": origin.x, "y": origin.y, "width": dimensions.width, "height": dimensions.height]
}

private func composerDiagnostics(in roots: [AXUIElement]) -> [String: Any] {
    var pending = roots.map { ($0, 0) }
    var visited = 0
    while !pending.isEmpty && visited < 4000 {
        let (element, depth) = pending.removeFirst()
        visited += 1
        let title = label(element)
        if title.contains("Dictate a message") {
            var names: CFArray?
            AXUIElementCopyActionNames(element, &names)
            return ["role": string(element, kAXRoleAttribute as CFString) ?? "",
                    "label": String(title.prefix(180)),
                    "frame": frame(element) as Any? ?? NSNull(),
                    "children": children(element).count,
                    "actions": names as Any? ?? []]
        }
        if depth < 24 { pending.append(contentsOf: children(element).map { ($0, depth + 1) }) }
    }
    return [:]
}

private func emit(_ value: [String: Any], status: Int32 = 0) -> Never {
    let data = (try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])) ?? Data("{}".utf8)
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
    exit(status)
}

private func museApplication() -> NSRunningApplication? {
    NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == museBundleID }
}

private func focusMuse() -> NSRunningApplication? {
    if museApplication() == nil {
        let open = Process()
        open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        open.arguments = ["-b", museBundleID]
        do { try open.run(); open.waitUntilExit() } catch { return nil }
        if open.terminationStatus != 0 { return nil }
    }
    guard let muse = museApplication() else { return nil }
    _ = muse.activate()
    for _ in 0..<40 {
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == museBundleID { return muse }
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        _ = muse.activate()
    }
    return nil
}

private func mainWindow(of muse: NSRunningApplication) -> AXUIElement? {
    let app = AXUIElementCreateApplication(muse.processIdentifier)
    for _ in 0..<40 {
        for window in windows(app) where findButton(in: window, containing: "Main chat") != nil {
            return window
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }
    return nil
}

private func findButton(in root: AXUIElement, containing needle: String) -> AXUIElement? {
    var pending = [(root, 0)]
    var visited = 0
    while !pending.isEmpty && visited < 4000 {
        let (element, depth) = pending.removeFirst()
        visited += 1
        if string(element, kAXRoleAttribute as CFString) == (kAXButtonRole as String) &&
            label(element).localizedCaseInsensitiveContains(needle) {
            return element
        }
        if depth < 24 { pending.append(contentsOf: children(element).map { ($0, depth + 1) }) }
    }
    return nil
}

private func press(_ element: AXUIElement) -> Bool {
    AXUIElementPerformAction(element, kAXPressAction as CFString) == .success
}

private func click(x: CGFloat, y: CGFloat) -> Bool {
    guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == museBundleID else { return false }
    let point = CGPoint(x: x, y: y)
    guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
          let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else { return false }
    down.post(tap: .cghidEventTap)
    up.post(tap: .cghidEventTap)
    return true
}

private func composer(in window: AXUIElement) -> [String: Double]? {
    guard let button = findButton(in: window, containing: "Dictate a message"),
          let dimensions = frame(button),
          let width = dimensions["width"], let height = dimensions["height"],
          width >= 300 && width <= 2000 && height >= 40 && height <= 120 else { return nil }
    return dimensions
}

private func clickComposerControl(in window: AXUIElement, kind: String) -> Bool {
    guard let dimensions = composer(in: window),
          let x = dimensions["x"], let y = dimensions["y"],
          let width = dimensions["width"], let height = dimensions["height"] else { return false }
    let rightOffset: Double = kind == "dictate" ? 64 : 28
    return click(x: x + width - rightOffset, y: y + height / 2)
}

private func recordingButton(in window: AXUIElement) -> AXUIElement? {
    findButton(in: window, containing: "Stop recording") ??
        findButton(in: window, containing: "Stop dictation")
}

private func waitForDictation(in window: AXUIElement, active: Bool) -> Bool {
    for _ in 0..<10 {
        if (recordingButton(in: window) != nil) == active { return true }
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }
    return false
}

private func stopDictation(in window: AXUIElement) -> Bool {
    guard let button = recordingButton(in: window),
          let dimensions = frame(button),
          let x = dimensions["x"], let y = dimensions["y"],
          let width = dimensions["width"], let height = dimensions["height"],
          width >= 300 && width <= 2000 && height >= 40 && height <= 120,
          click(x: x + width - 64, y: y + height / 2) else { return false }
    return waitForDictation(in: window, active: false)
}

private func key(_ code: CGKeyCode, command: Bool = false) -> Bool {
    guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == museBundleID,
          let down = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true),
          let up = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false) else { return false }
    if command { down.flags = .maskCommand }
    down.post(tap: .cghidEventTap)
    up.post(tap: .cghidEventTap)
    return true
}

private func clipboardSnapshot(_ board: NSPasteboard) -> [NSPasteboardItem] {
    (board.pasteboardItems ?? []).map { original in
        let item = NSPasteboardItem()
        for type in original.types {
            if let data = original.data(forType: type) { item.setData(data, forType: type) }
        }
        return item
    }
}

private func pasteUsingEditMenu() -> Bool {
    guard let muse = museApplication(),
          let menuBar = read(AXUIElementCreateApplication(muse.processIdentifier), kAXMenuBarAttribute as CFString),
          CFGetTypeID(menuBar) == AXUIElementGetTypeID() else { return false }
    let bar = unsafeBitCast(menuBar, to: AXUIElement.self)
    guard let edit = children(bar).first(where: { label($0) == "Edit" }), press(edit) else { return false }
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    var pending = [edit]
    while !pending.isEmpty {
        let element = pending.removeFirst()
        if label(element) == "Paste" { return press(element) }
        pending.append(contentsOf: children(element))
    }
    return false
}

private func draftIsEmpty() -> Bool? {
    let board = NSPasteboard.general
    let previous = clipboardSnapshot(board)
    let marker = UUID().uuidString
    board.clearContents()
    board.setString(marker, forType: .string)
    let selectedAll = key(0, command: true)
    RunLoop.current.run(until: Date().addingTimeInterval(0.15))
    let copied = selectedAll && key(8, command: true) // Command-A, Command-C
    RunLoop.current.run(until: Date().addingTimeInterval(0.15))
    let selected = board.string(forType: .string)
    board.clearContents()
    if !previous.isEmpty { board.writeObjects(previous) }
    guard copied, let selected else { return nil }
    return selected == marker
}

private func pasteAndVerify(_ prompt: String) -> Bool {
    let board = NSPasteboard.general
    let previous = clipboardSnapshot(board)
    board.clearContents()
    board.setString(prompt, forType: .string)
    let pasted = pasteUsingEditMenu()
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    board.clearContents()
    board.setString(UUID().uuidString, forType: .string)
    let selectedAll = pasted && key(0, command: true)
    RunLoop.current.run(until: Date().addingTimeInterval(0.15))
    let copied = selectedAll && key(8, command: true)
    RunLoop.current.run(until: Date().addingTimeInterval(0.15))
    let matches = copied && board.string(forType: .string) == prompt
    board.clearContents()
    if !previous.isEmpty { board.writeObjects(previous) }
    return matches
}

private func sendPrompt(_ prompt: String, in window: AXUIElement) -> String {
    guard let dimensions = composer(in: window),
          let x = dimensions["x"], let y = dimensions["y"],
          let height = dimensions["height"] else { return "composer-missing" }
    guard click(x: x + 90, y: y + height / 2) else { return "composer-not-focused" }
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    guard let empty = draftIsEmpty() else { return "draft-check-failed" }
    guard empty else { return "draft-not-empty" }
    guard pasteAndVerify(prompt) else { return "paste-verification-failed" }
    guard clickComposerControl(in: window, kind: "send") else { return "send-control-missing" }
    return "sent"
}

private func finishAndSend(in window: AXUIElement) -> String {
    if let recording = recordingButton(in: window) {
        guard let dimensions = frame(recording),
              let x = dimensions["x"], let y = dimensions["y"],
              let width = dimensions["width"], let height = dimensions["height"],
              width >= 300 && width <= 2000 && height >= 40 && height <= 120,
              click(x: x + width - 28, y: y + height / 2) else { return "recording-send-control-missing" }
        return waitForDictation(in: window, active: false) ? "recording-submitted" : "recording-send-failed"
    }
    guard let dimensions = composer(in: window),
          let x = dimensions["x"], let y = dimensions["y"],
          let height = dimensions["height"],
          click(x: x + 90, y: y + height / 2) else { return "composer-not-focused" }
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    guard let empty = draftIsEmpty() else { return "draft-check-failed" }
    guard !empty else { return "empty-draft" }
    guard clickComposerControl(in: window, kind: "send") else { return "send-control-missing" }
    return "draft-submitted"
}

let command = CommandLine.arguments.dropFirst().first ?? ""
if command == "probe" {
    let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    let muse = NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == museBundleID }
    let trusted = AXIsProcessTrusted()
    let roots = (trusted && muse != nil) ? windows(AXUIElementCreateApplication(muse!.processIdentifier)) : []
    let controls = candidates(in: roots)
    let application = muse.map { AXUIElementCreateApplication($0.processIdentifier) }
    let focused = application.flatMap { app -> AXUIElement? in
        guard let raw = read(app, kAXFocusedUIElementAttribute as CFString),
              CFGetTypeID(raw) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(raw, to: AXUIElement.self)
    }
    emit([
        "frontmostBundleId": frontmost as Any? ?? NSNull(),
        "museRunning": muse != nil,
        "accessibilityTrusted": trusted,
        "controls": controls,
        "composer": composerDiagnostics(in: roots),
        "focused": focused.map { ["role": string($0, kAXRoleAttribute as CFString) ?? "", "isComposer": label($0).contains("Dictate a message") ] as [String: Any] } as Any? ?? NSNull()
    ])
}

if ["open-main", "new-side-chat", "dictate", "dictation-state", "send-prompt", "finish-send"].contains(command) {
    let prompt = command == "send-prompt" ? String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) : nil
    if command == "send-prompt" && (prompt?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
        emit(["ok": false, "code": "empty-prompt"], status: 1)
    }
    if let prompt, prompt.count > 4000 { emit(["ok": false, "code": "prompt-too-long"], status: 1) }
    if command == "dictation-state" {
        guard let muse = museApplication(), let window = mainWindow(of: muse) else {
            emit(["ok": true, "code": "idle"])
        }
        emit(["ok": true, "code": recordingButton(in: window) == nil ? "idle" : "dictating"])
    }
    let wasFrontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == museBundleID
    guard let muse = focusMuse(), let window = mainWindow(of: muse) else {
        emit(["ok": false, "code": "muse-unavailable"], status: 1)
    }
    if command == "dictate", recordingButton(in: window) != nil {
        guard stopDictation(in: window) else {
            emit(["ok": false, "code": "dictation-stop-failed"], status: 1)
        }
        emit(["ok": true, "code": "dictation-stopped"])
    }
    if command == "open-main" || (command == "dictate" && !wasFrontmost) {
        guard let main = findButton(in: window, containing: "Main chat"), press(main) else {
            emit(["ok": false, "code": "main-chat-control-missing"], status: 1)
        }
        Thread.sleep(forTimeInterval: 0.25)
    }
    if command == "new-side-chat" {
        guard let side = findButton(in: window, containing: "New side chat"), press(side) else {
            emit(["ok": false, "code": "side-chat-control-missing"], status: 1)
        }
    }
    if command == "dictate" {
        guard clickComposerControl(in: window, kind: "dictate"),
              waitForDictation(in: window, active: true) else {
            emit(["ok": false, "code": "dictation-start-failed"], status: 1)
        }
    }
    if command == "send-prompt" {
        let code = sendPrompt(prompt!, in: window)
        emit(["ok": code == "sent", "code": code], status: code == "sent" ? 0 : 1)
    }
    if command == "finish-send" {
        let code = finishAndSend(in: window)
        let ok = code == "recording-submitted" || code == "draft-submitted"
        emit(["ok": ok, "code": code], status: ok ? 0 : 1)
    }
    emit(["ok": true, "code": command == "dictate" ? (wasFrontmost ? "dictating-current" : "dictating-main") : "done"])
}

emit(["ok": false, "code": "unsupported-command"], status: 2)
