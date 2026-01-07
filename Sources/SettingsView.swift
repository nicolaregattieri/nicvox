import SwiftUI
import Carbon
import AppKit

struct SettingsView: View {
    @AppStorage("playSounds") private var playSounds = true
    @AppStorage("insertionMethod") private var insertionMethod = "clipboard" // "clipboard" or "typing"
    
    @AppStorage("startSound") private var startSound = "Tink"
    @AppStorage("stopSound") private var stopSound = "Pop"
    
    // Portuguese Config
    @AppStorage("keyPT") private var keyPT = "P"
    @AppStorage("modPT") private var modPT = Int(cmdKey | optionKey)
    
    // English Config
    @AppStorage("keyEN") private var keyEN = "E"
    @AppStorage("modEN") private var modEN = Int(cmdKey | optionKey)
    
    var onSave: () -> Void
    
    let modifiers = [
        ("Cmd + Option", Int(cmdKey | optionKey)),
        ("Ctrl + Option", Int(controlKey | optionKey)),
        ("Cmd + Shift", Int(cmdKey | shiftKey)),
        ("Option + Shift", Int(optionKey | shiftKey))
    ]
    
    let systemSounds = ["Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]
    
    var body: some View {
        VStack(spacing: 20) {
            // General Section
            GroupBox(label: Text("Behavior")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Play Sounds", isOn: $playSounds)
                    
                    Divider()
                    
                    Text("Text Insertion Method:")
                        .font(.headline)
                        .padding(.top, 4)
                    
                    Picker("", selection: $insertionMethod) {
                        Text("📋 Clipboard & Paste (Faster for long text)").tag("clipboard")
                        Text("⌨️ Direct Typing (Stealth - No Clipboard)").tag("typing")
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    
                    if insertionMethod == "clipboard" {
                         Text("Automatically tries to press Cmd+V.")
                             .font(.caption).foregroundColor(.secondary)
                    } else {
                         Text("Types characters directly. Keeps clipboard clean.")
                             .font(.caption).foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }
            
            // Audio Section
            GroupBox(label: Text("Audio Feedback")) {
                if playSounds {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Start:")
                                .frame(width: 50, alignment: .trailing)
                            Picker("", selection: $startSound) {
                                ForEach(systemSounds, id: \.self) { sound in Text(sound) }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                            
                            Button("▶") { NSSound(named: startSound)?.play() }
                        }
                        
                        HStack {
                            Text("Stop:")
                                .frame(width: 50, alignment: .trailing)
                            Picker("", selection: $stopSound) {
                                ForEach(systemSounds, id: \.self) { sound in Text(sound) }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                            
                            Button("▶") { NSSound(named: stopSound)?.play() }
                        }
                    }
                    .padding(8)
                } else {
                    Text("Sounds disabled").foregroundColor(.secondary).padding(8)
                }
            }
            
            // Shortcuts Section
            GroupBox(label: Text("Shortcuts")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("🇧🇷 PT:")
                            .frame(width: 50, alignment: .trailing)
                        Picker("", selection: $modPT) {
                            ForEach(modifiers, id: \.1) { name, value in Text(name).tag(value) }
                        }
                        .labelsHidden().frame(width: 130)
                        Text("+")
                        TextField("Key", text: $keyPT)
                            .frame(width: 30).multilineTextAlignment(.center)
                    }
                    HStack {
                        Text("🇺🇸 EN:")
                            .frame(width: 50, alignment: .trailing)
                        Picker("", selection: $modEN) {
                            ForEach(modifiers, id: \.1) { name, value in Text(name).tag(value) }
                        }
                        .labelsHidden().frame(width: 130)
                        Text("+")
                        TextField("Key", text: $keyEN)
                            .frame(width: 30).multilineTextAlignment(.center)
                    }
                }
                .padding(8)
            }
            
            Spacer()
            
            Button("Apply Changes") { onSave() }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(width: 450, height: 600) // Taller window
    }
}
