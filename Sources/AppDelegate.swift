import Cocoa
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate, HotKeyDelegate, NSMenuDelegate {
    var statusBarItem: NSStatusItem!
    var speechManager: SpeechManager!
    var hotKeyManager: HotKeyManager!
    var settingsWindow: NSWindow?
    
    var lastLanguage: LanguageHotkey = .portuguese
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Logger.shared.log("🚀 NicVox Started")
        
        // Ensure defaults
        if UserDefaults.standard.string(forKey: "insertionMethod") == nil {
            UserDefaults.standard.set("clipboard", forKey: "insertionMethod")
        }
        
        speechManager = SpeechManager()
        hotKeyManager = HotKeyManager(delegate: self)
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()
        
        let menu = NSMenu()
        menu.delegate = self
        statusBarItem.menu = menu
        
        speechManager.onTextRecognized = { [weak self] text in
            self?.processRecognizedText(text)
        }
        
        speechManager.onError = { [weak self] error in
            Logger.shared.log("❌ Speech Manager reported error: \(error)")
            self?.updateIcon()
        }
    }
    
    func processRecognizedText(_ text: String) {
        let method = UserDefaults.standard.string(forKey: "insertionMethod") ?? "clipboard"
        
        // Log info
        let frontApp = NSWorkspace.shared.frontmostApplication
        let appName = frontApp?.localizedName ?? "Unknown"
        let bundleId = frontApp?.bundleIdentifier ?? "Unknown"
        Logger.shared.log("🗣️ Recognized: '\(text)'")
        Logger.shared.log("🎯 Target App: \(appName) (\(bundleId))")
        
        // START SAFETY CHECK: Wait for keys to be released
        waitForModifiersRelease { [weak self] in
            guard let self = self else { return }
            
            if method == "typing" {
                self.simulateTyping(text)
            } else {
                // Clipboard + AutoPaste Mode
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(text, forType: .string)
                Logger.shared.log("📋 Copied to Clipboard")
                
                if UserDefaults.standard.bool(forKey: "autoPaste") {
                    Logger.shared.log("⌨️ Attempting Auto-Paste...")
                    self.simulatePasteCommand()
                }
            }
        }
    }
    
    func waitForModifiersRelease(completion: @escaping () -> Void) {
        let flags = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // Check specifically for Cmd, Opt, Ctrl, Shift
        if flags.contains(.command) || flags.contains(.option) || flags.contains(.control) || flags.contains(.shift) {
            Logger.shared.log("⚠️ Modifiers held down. Waiting...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.waitForModifiersRelease(completion: completion)
            }
        } else {
            // All clear!
            completion()
        }
    }
    
    func simulateTyping(_ text: String) {
        if !AXIsProcessTrusted() {
            self.promptForAccessibility()
            return
        }

        let backslash = String(UnicodeScalar(92))
        let escapedBackslash = backslash + backslash
        
        let escapedText = text
            .replacingOccurrences(of: backslash, with: escapedBackslash)
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let scriptSource = """
        tell application "System Events"
            keystroke "\(escapedText)"
        end tell
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: scriptSource) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                Logger.shared.log("❌ AppleScript Error: \(error)")
            } else {
                Logger.shared.log("✅ Typing executed successfully")
            }
        }
    }
    
    func simulatePasteCommand() {
        if !AXIsProcessTrusted() {
            self.promptForAccessibility()
            return
        }
        
        // Debug: Log modifier state
        // If user is still holding Cmd+Option, this might interfere.
        // We can't easily clear hardware state, but we can log it.
        
        let vKeyCode = CGKeyCode(kVK_ANSI_V)
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        // Simulate clean Cmd+V
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        vDown?.flags = .maskCommand
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        vUp?.flags = .maskCommand
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        Logger.shared.log("✅ Simulated Cmd+V")
    }
    
    func promptForAccessibility() {
        Logger.shared.log("❌ Permission Missing: Prompting user")
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Needed"
            alert.informativeText = "NicVox needs Accessibility permission to type/paste text.\n\nPlease enable it in System Settings."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() == .alertFirstButtonReturn {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
        }
    }

    // --- Standard Delegate Methods ---

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        
        if speechManager.isRecording {
            let stopItem = NSMenuItem(title: "🛑 Stop Recording", action: #selector(stopRecording), keyEquivalent: ".")
            menu.addItem(stopItem)
        } else {
            let kPT = UserDefaults.standard.string(forKey: "keyPT") ?? "P"
            let kEN = UserDefaults.standard.string(forKey: "keyEN") ?? "E"
            
            let itemPT = NSMenuItem(title: "🇧🇷 Start Portuguese (...+\(kPT))", action: #selector(togglePT), keyEquivalent: kPT.lowercased())
            let itemEN = NSMenuItem(title: "🇺🇸 Start English (...+\(kEN))", action: #selector(toggleEN), keyEquivalent: kEN.lowercased())
            
            menu.addItem(itemPT)
            menu.addItem(itemEN)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit NicVox", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
    
    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(onSave: { [weak self] in
                self?.hotKeyManager.registerHotKeys()
                self?.settingsWindow?.close()
                self?.settingsWindow = nil
                Logger.shared.log("⚙️ Preferences Saved")
            })
            
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 600),
                styleMask: [.titled, .closable],
                backing: .buffered, defer: false)
            settingsWindow?.center()
            settingsWindow?.title = "NicVox Preferences"
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            settingsWindow?.isReleasedWhenClosed = false
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func stopRecording() {
        if speechManager.isRecording {
            speechManager.stopRecording()
            updateIcon()
        }
    }
    
    @objc func togglePT() {
        handleAction(language: .portuguese)
    }
    
    @objc func toggleEN() {
        handleAction(language: .english)
    }
    
    func hotKeyPressed(language: LanguageHotkey) {
        handleAction(language: language)
    }
    
    func handleAction(language: LanguageHotkey) {
        lastLanguage = language
        
        if speechManager.isRecording {
            let wasUsingPT = (speechManager.currentLocaleId == "pt-BR")
            let pressedPT = (language == .portuguese)
            
            speechManager.stopRecording()
            updateIcon()
            
            if wasUsingPT != pressedPT {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.start(language: language)
                }
            }
        } else {
            start(language: language)
        }
    }
    
    func start(language: LanguageHotkey) {
        let localeId = (language == .portuguese) ? "pt-BR" : "en-US"
        do {
            try speechManager.startRecording(localeId: localeId)
            updateIcon(activeLanguage: language)
        } catch {
            Logger.shared.log("❌ Error starting recording: \(error)")
        }
    }
    
    func updateIcon(activeLanguage: LanguageHotkey? = nil) {
        DispatchQueue.main.async {
            guard let button = self.statusBarItem.button else { return }
            
            let nvxIcon = self.createNVXIcon()
            button.image = nvxIcon
            button.contentTintColor = nil 
            
            if self.speechManager.isRecording {
                let text = (self.speechManager.currentLocaleId == "pt-BR") ? " PT" : " EN"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 13, weight: .bold),
                    .foregroundColor: NSColor.systemRed
                ]
                let attrTitle = NSAttributedString(string: " ●" + text, attributes: attributes)
                button.attributedTitle = attrTitle
            } else {
                button.title = ""
            }
        }
    }
    
    func createNVXIcon() -> NSImage {
        let text = "NVX"
        let font = NSFont.systemFont(ofSize: 11, weight: .black)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = text.size(withAttributes: attributes)
        
        let width = size.width + 2
        let height: CGFloat = 22
        
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        let yPos = (height - size.height) / 2 - 1
        text.draw(at: NSPoint(x: 1, y: yPos), withAttributes: attributes)
        image.unlockFocus()
        
        image.isTemplate = true
        return image
    }
}
