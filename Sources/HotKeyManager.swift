import Carbon
import AppKit

enum LanguageHotkey {
    case portuguese
    case english
}

protocol HotKeyDelegate: AnyObject {
    func hotKeyPressed(language: LanguageHotkey)
}

class HotKeyManager {
    weak var delegate: HotKeyDelegate?
    var hotKeys: [EventHotKeyRef] = []
    var eventHandler: EventHandlerRef?
    
    // IDs to distinguish events
    let idPortuguese: UInt32 = 101
    let idEnglish: UInt32 = 102
    
    init(delegate: HotKeyDelegate) {
        self.delegate = delegate
        registerHotKeys()
    }
    
    func unregisterAll() {
        for ref in hotKeys {
            UnregisterEventHotKey(ref)
        }
        hotKeys.removeAll()
    }
    
    func registerHotKeys() {
        unregisterAll()
        
        let defaults = UserDefaults.standard
        
        // Defaults
        if defaults.string(forKey: "keyPT") == nil { defaults.set("P", forKey: "keyPT") }
        if defaults.string(forKey: "keyEN") == nil { defaults.set("E", forKey: "keyEN") }
        if defaults.integer(forKey: "modPT") == 0 { defaults.set(cmdKey | optionKey, forKey: "modPT") }
        if defaults.integer(forKey: "modEN") == 0 { defaults.set(cmdKey | optionKey, forKey: "modEN") }
        
        // Load Config
        let keyCharPT = defaults.string(forKey: "keyPT") ?? "P"
        let modPT = UInt32(defaults.integer(forKey: "modPT"))
        let codePT = KeyCodeMap.getCode(for: keyCharPT)
        
        let keyCharEN = defaults.string(forKey: "keyEN") ?? "E"
        let modEN = UInt32(defaults.integer(forKey: "modEN"))
        let codeEN = KeyCodeMap.getCode(for: keyCharEN)
        
        // Register
        register(keyCode: codePT, modifiers: modPT, id: idPortuguese)
        register(keyCode: codeEN, modifiers: modEN, id: idEnglish)
        
        // Install Event Handler (Only once)
        if eventHandler == nil {
            let eventSpec = [
                EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            ]
            
            let selfPointer = Unmanaged.passUnretained(self).toOpaque()
            
            InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                
                var hotKeyID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                
                            switch hotKeyID.id {
                            case manager.idPortuguese:
                                Logger.shared.log("🎹 Hotkey Pressed: Portuguese")
                                manager.delegate?.hotKeyPressed(language: .portuguese)
                            case manager.idEnglish:
                                Logger.shared.log("🎹 Hotkey Pressed: English")
                                manager.delegate?.hotKeyPressed(language: .english)
                            default:
                                break
                            }                
                return noErr
            }, 1, eventSpec, selfPointer, &eventHandler)
        }
        
        print("Hotkeys Registered Updated.")
    }
    
    private func register(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x564F4943) // 'VOIC'
        hotKeyID.id = id
        
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        
        if status == noErr, let r = ref {
            hotKeys.append(r)
        } else {
            print("Failed to register hotkey ID: \(id)")
        }
    }
    
    deinit {
        unregisterAll()
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
