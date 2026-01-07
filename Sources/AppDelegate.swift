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
            print("Speech Error: \(error)")
            self?.updateIcon()
        }
    }
    
    func processRecognizedText(_ text: String) {
        let method = UserDefaults.standard.string(forKey: "insertionMethod") ?? "clipboard"
        
        // Context Logging
        let frontApp = NSWorkspace.shared.frontmostApplication
        let appName = frontApp?.localizedName ?? "Unknown"
        let bundleId = frontApp?.bundleIdentifier ?? "Unknown"
        
        self.log("🗣️ Recognized: '\(text)'")
        self.log("⚙️ Method: \(method)")
        self.log("🖥️ Active App: \(appName) (\(bundleId))")
        
        if method == "typing" {
            // DIRECT TYPING MODE
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.log("⌨️ Executing Typing...")
                self.simulateTyping(text)
            }
        } else {
            // CLIPBOARD MODE
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            self.log("📋 Copied to Clipboard")
            
            if UserDefaults.standard.bool(forKey: "autoPaste") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.log("⌨️ Executing Paste Command...")
                    self.simulatePasteCommand()
                }
            }
        }
    }
    
    func simulateTyping(_ text: String) {
        let trusted = AXIsProcessTrusted()
        self.log("Accessibility Trusted: \(trusted)")
        
        if !trusted {
            self.log("❌ Error: Accessibility permission missing for Typing.")
        }

        let escapedText = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        // Correctly indented multiline string
        let scriptSource = """
        tell application "System Events"
            keystroke "\(escapedText)"
        end tell
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: scriptSource) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                self.log("❌ AppleScript Error: \(error)")
            } else {
                self.log("✅ Typing executed successfully via AppleScript")
            }
        } else {
            self.log("❌ Failed to initialize NSAppleScript")
        }
    }
    
    func log(_ message: String) {
        let logFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents")
            .appendingPathComponent("NicVox_Log.txt")
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let text = "\(timestamp): \(message)\n"
        
        if let data = text.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }
    }    
    func simulatePasteCommand() {
        // Use AppleScript which is safer and handles modifier isolation better
        let source = """
        tell application "System Events"
            keystroke "v" using {command down}
        end tell
        """
        
        if let script = NSAppleScript(source: source) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error = error {
                print("Paste Error: \(error)")
            }
        }
    }
    
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
            print("Failed to start: \(error)")
        }
    }
    
    func updateIcon(activeLanguage: LanguageHotkey? = nil) {
        DispatchQueue.main.async {
            guard let button = self.statusBarItem.button else { return }
            
            // Create the NVX icon
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