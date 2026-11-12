import AppKit
import AVFoundation
import CoreMIDI

struct Note { let pitch: Int; let beat: Double; let length: Double }
struct Lesson {
    let name: String
    let notes: [Note]
    func shifted(_ semitones: Int) -> Lesson {
        Lesson(name: name, notes: notes.map { Note(pitch: $0.pitch + semitones, beat: $0.beat, length: $0.length) })
    }
    static func melody(_ name: String, _ pitches: [Int], step: Double = 1, durations: [Double]? = nil) -> Lesson {
        precondition(durations == nil || durations!.count == pitches.count)
        var beat = 3.0
        let notes = pitches.enumerated().map { i,pitch -> Note in
            let length = durations?[i] ?? step
            precondition(length > 0)
            defer { beat += length }
            return Note(pitch:pitch,beat:beat,length:length)
        }
        return Lesson(name:name,notes:notes)
    }
}
let lessons = [
    Lesson.melody("01 · Первые пять нот", [60,62,64,65,67,65,64,62,60], durations:[1,1,1,1,2,1,1,1,2]),
    Lesson.melody("02 · Ода к радости", [64,64,65,67,67,65,64,62,60,60,62,64,64,62,62,64,64,65,67,67,65,64,62,60,60,62,64,62,60,60], durations:Array(repeating:1.0,count:12) + [1.5,0.5,2] + Array(repeating:1.0,count:12) + [1.5,0.5,2]),
    Lesson.melody("03 · Мерцай, звёздочка", [60,60,67,67,69,69,67,65,65,64,64,62,62,60,67,67,65,65,64,64,62,67,67,65,65,64,64,62,60,60,67,67,69,69,67,65,65,64,64,62,62,60], durations:(0..<42).map { $0 % 7 == 6 ? 2.0 : 1.0 }),
    Lesson.melody("04 · Гамма До мажор", [60,62,64,65,67,69,71,72,71,69,67,65,64,62,60], durations:Array(repeating:0.5,count:7) + [1] + Array(repeating:0.5,count:6) + [2]),
    Lesson.melody("05 · У Мэри был барашек", [64,62,60,62,64,64,64,62,62,62,64,67,67,64,62,60,62,64,64,64,64,62,62,64,62,60], durations:[1,1,1,1,1,1,2,1,1,2,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,2]),
    Lesson.melody("06 · Братец Яков", [60,62,64,60,60,62,64,60,64,65,67,64,65,67,67,69,67,65,64,60,67,69,67,65,64,60,60,67,60,60,67,60], durations:[1,1,1,1,1,1,1,1,1,1,2,1,1,2,0.5,0.5,0.5,0.5,1,1,0.5,0.5,0.5,0.5,1,1,1,1,2,1,1,2]),
    Lesson.melody("07 · Лондонский мост", [67,69,67,65,64,65,67,62,64,65,64,65,67,67,69,67,65,64,65,67,62,67,64,60], durations:[1.5,0.5,1,1,1,1,2,1,1,2,1,1,2,1.5,0.5,1,1,1,1,2,2,2,1,3]),
    Lesson.melody("08 · Горячие булочки", [64,62,60,64,62,60,60,60,60,60,62,62,62,62,64,62,60], durations:[1,1,2,1,1,2,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,1,1,2]),
    Lesson.melody("09 · Колокольчики", [64,64,64,64,64,64,64,67,60,62,64,65,65,65,65,65,64,64,64,64,62,62,64,62,67], durations:[1,1,2,1,1,2,1,1,1.5,0.5,4,1,1,1.5,0.5,1,1,1,0.5,0.5,1,1,1,2,2]),
    Lesson.melody("10 · Лесенка · упражнение", [60,62,64,60,62,64,65,62,64,65,67,64,65,64,62,60], durations:[0.5,0.5,1,2,0.5,0.5,1,2,0.5,0.5,1,2,1,1,1,2]),
    Lesson.melody("11 · Музыкальное эхо · упражнение", [60,64,67,60,64,67,62,65,69,62,65,69,67,64,60], durations:[1,1,2,0.5,0.5,1,1,1,2,0.5,0.5,1,1,1,2]),
    Lesson.melody("12 · Прыгающий мяч · упражнение", [60,67,60,67,62,69,62,69,64,67,64,67,65,64,62,60], durations:[0.5,1.5,0.5,1.5,0.5,1.5,0.5,1.5,0.5,1.5,0.5,1.5,1,1,1,2])
]
func noteName(_ p: Int) -> String { ["До","До♯","Ре","Ре♯","Ми","Фа","Фа♯","Соль","Соль♯","Ля","Ля♯","Си"][p % 12] }
func black(_ p: Int) -> Bool { [1,3,6,8,10].contains(p % 12) }

final class Piano {
    let engine = AVAudioEngine()
    let sampler = AVAudioUnitSampler()
    var error: String?
    init() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        do {
            try sampler.loadSoundBankInstrument(at: URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"), program: 0, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0)
            try engine.start()
        } catch { self.error = error.localizedDescription }
    }
    func on(_ p: Int, _ velocity: Int = 90) { sampler.startNote(UInt8(p), withVelocity: UInt8(velocity), onChannel: 0) }
    func off(_ p: Int) { sampler.stopNote(UInt8(p), onChannel: 0) }
    func silence() { for p in 0...127 { off(p) } }
}

final class MIDIInput {
    var client = MIDIClientRef(); var port = MIDIPortRef()
    var sources = Set<MIDIEndpointRef>()
    var running: UInt8 = 0; var bytes: [UInt8] = []
    var handler: ((Int, Int, Bool) -> Void)?
    var controlHandler: ((Int,Int) -> Void)?
    var status: ((String) -> Void)?
    var retry: Timer?
    var midiError: String?
    var parserStates: [UInt: (UInt8, [UInt8])] = [:]
    init() {
        retry = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.connect() }
    }
    func prepare() -> Bool {
        if client == 0 {
            let result = MIDIClientCreateWithBlock("MiniLab Tutor" as CFString, &client) { [weak self] _ in DispatchQueue.main.async { self?.connect() } }
            if result != noErr { client = 0; midiError = "CoreMIDI: ошибка открытия клиента (\(result)). Повторяем подключение…"; return false }
        }
        if port == 0 {
            let result = MIDIInputPortCreateWithBlock(client, "Keyboard" as CFString, &port) { [weak self] list, context in
                let source = UInt(bitPattern: context)
                var pointer = UnsafeRawPointer(list).advanced(by: MemoryLayout<MIDIPacketList>.offset(of: \.packet)!).assumingMemoryBound(to: MIDIPacket.self)
                for _ in 0..<list.pointee.numPackets {
                    let length = Int(pointer.pointee.length)
                    let offset = MemoryLayout<MIDIPacket>.offset(of: \.data)!
                    let data = Array(UnsafeBufferPointer(start: UnsafeRawPointer(pointer).advanced(by: offset).assumingMemoryBound(to: UInt8.self), count: length))
                    DispatchQueue.main.async { self?.consume(data, source: source) }
                    pointer = UnsafePointer(MIDIPacketNext(pointer))
                }
            }
            if result != noErr { port = 0; midiError = "CoreMIDI: ошибка входного порта (\(result)). Повторяем подключение…"; return false }
        }
        midiError = nil
        return true
    }
    func connect() {
        guard prepare() else { status?(midiError ?? "Ошибка MIDI"); return }
        var names: [String] = []; var current = Set<MIDIEndpointRef>()
        var failures: [String] = []
        for i in 0..<MIDIGetNumberOfSources() {
            let source = MIDIGetSource(i)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(source, kMIDIPropertyDisplayName, &name)
            let label = name?.takeRetainedValue() as String? ?? "MIDI-клавиатура"
            if label.lowercased().contains("minilab") && !label.lowercased().hasSuffix(" midi") { continue }
            if !sources.contains(source) {
                let result = MIDIPortConnectSource(port, source, UnsafeMutableRawPointer(bitPattern: UInt(source)))
                if result != noErr { failures.append("\(label): ошибка \(result)"); continue }
            }
            current.insert(source); names.append(label)
        }
        for old in sources.subtracting(current) { MIDIPortDisconnectSource(port, old); parserStates.removeValue(forKey: UInt(old)) }
        sources = current
        status?(!failures.isEmpty ? failures.joined(separator: ", ") : names.isEmpty ? "Нет MIDI-входа · подключи MiniLab 3 по USB · повторяем поиск" : "Подключено · " + names.joined(separator: ", "))
    }
    func consume(_ data: [UInt8], source: UInt) {
        let state = parserStates[source] ?? (0, [])
        running = state.0; bytes = state.1
        consume(data)
        parserStates[source] = (running, bytes)
    }
    func consume(_ data: [UInt8]) {
        for b in data {
            if b >= 0xF8 { continue }
            if b & 0x80 != 0 { running = b < 0xF0 ? b : 0; bytes.removeAll(); continue }
            guard running != 0 else { continue }
            bytes.append(b)
            let kind = running & 0xF0
            let count = (kind == 0xC0 || kind == 0xD0) ? 1 : 2
            if bytes.count == count {
                if kind == 0x90 || kind == 0x80 { handler?(Int(bytes[0]), Int(bytes[1]), kind == 0x90 && bytes[1] > 0) }
                if kind == 0xB0 { controlHandler?(Int(bytes[0]),Int(bytes[1])) }
                bytes.removeAll()
            }
        }
    }
    deinit { retry?.invalidate(); if port != 0 { MIDIPortDispose(port) }; if client != 0 { MIDIClientDispose(client) } }
}

func tempoForController(_ value: Int) -> Double {
    (30 + Double(max(0,min(127,value))) * 110 / 127).rounded()
}

func melodyForKnob(_ value: Int, count: Int) -> Int {
    guard count > 0 else { return 0 }
    return max(0,min(count-1,value))
}

struct Hold {
    let pitch: Int
    let start: Double
    let end: Double
    var tolerance: Double { min(0.20, (end-start)*0.2) }
    func releaseIsCorrect(at beat: Double, waiting: Bool) -> Bool {
        beat >= end-tolerance && (waiting || beat <= end+tolerance)
    }
}

struct Rewards {
    var points = 0
    var combo = 0
    var best = 0
    mutating func hit() { combo += 1; best = max(best, combo); points += 100 + min(combo, 10) * 10 }
    mutating func miss() { combo = 0 }
}
struct Spark {
    var x: CGFloat; var y: CGFloat
    var vx: CGFloat; var vy: CGFloat
    var life: Double; let duration: Double
    let color: NSColor; let size: CGFloat
}

final class GameView: NSView {
    let piano = Piano(); let midi = MIDIInput()
    var lesson = lessons[0].shifted(-12); var beat = 0.0; var bpm = 70.0
    var playing = false; var waitMode = true; var demo = false
    var rewards = Rewards()
    var sparks: [Spark] = []
    var effectsEnabled = true
    var animated: Bool { effectsEnabled && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    var birdHealth = BirdRecovery()
    var bird = NoteBird()
    var birdFacingRight = true
    var celebration = false
    var popTime = 0.0
    var popText = ""
    var glow: [Int: Double] = [:]
    var hold: Hold?
    var next = 0; var hits = 0; var mistakes = 0
    var pressed = Set<Int>(); var demoNotes = Set<Int>()
    var demoIndices: [Int:Int] = [:]
    var last = ProcessInfo.processInfo.systemUptime
    var timer: Timer?; var mousePitch: Int?
    var update: (() -> Void)?
    var incoming: ((String) -> Void)?
    var message = "Нажми «Начать» и сыграй первую подсвеченную ноту"
    var keyboardLow = 48
    var calibrating = false
    var visibleNotes: ClosedRange<Int> { keyboardLow...(keyboardLow + 24) }
    var whiteKeys: [Int] { visibleNotes.filter { !black($0) } }
    func calibrate(_ pitch: Int) {
        guard pitch % 12 == 0 && pitch <= 103 else {
            incoming?("Для настройки нажми самое левое До (C) на MiniLab")
            return
        }
        let offset = pitch - keyboardLow
        lesson = lesson.shifted(offset)
        keyboardLow = pitch
        calibrating = false
        reset()
        incoming?("Диапазон настроен: MIDI \(pitch)–\(pitch + 24) · 25 клавиш")
    }
    override var acceptsFirstResponder: Bool { true }
    override init(frame: NSRect) {
        super.init(frame: frame)
        midi.handler = { [weak self] p,v,on in
            guard let self else { return }
            if p == 41 || p == 40 || p == 42 {
                if on {
                    if p == 42 { self.startPreview() } else { self.setPlaying(p == 41) }
                    self.incoming?(p == 42 ? "MiniLab · слушаем образец" : p == 41 ? "MiniLab · Play" : "MiniLab · Пауза")
                }
                return
            }
            if on && self.calibrating { self.calibrate(p); return }
            if on { self.incoming?("Вход: " + noteName(p) + " · MIDI \(p)" + (self.visibleNotes.contains(p) ? "" : " · вне экрана: нажми «Настроить клавиатуру»")) }
            self.input(p, v, on)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60, repeats: true) { [weak self] _ in self?.tick() }
    }
    required init?(coder: NSCoder) { fatalError() }
    func setPlaying(_ active: Bool) {
        if active && beat > (lesson.notes.last.map { $0.beat + $0.length } ?? 0) { reset() }
        playing = active
        if !active {
            if let held = hold { beat = held.start; hold = nil }
            piano.silence(); demoNotes.removeAll(); demoIndices.removeAll(); pressed.removeAll()
        }
        message = active ? "Играй, когда блок касается голубой линии" : "Пауза · нажми Play на MiniLab, чтобы продолжить"
        needsDisplay = true
        update?()
    }
    func startPreview() {
        reset()
        demo = true
        setPlaying(true)
        message = "Слушай и смотри: так звучит мелодия. Потом сыграешь сам!"
        update?()
    }
    func reset() {
        demo = false
        bird = NoteBird(); birdHealth = BirdRecovery()
        piano.silence(); demoNotes.removeAll(); demoIndices.removeAll(); pressed.removeAll()
        rewards = Rewards(); sparks.removeAll(); glow.removeAll(); celebration = false; popTime = 0
        hold = nil; beat = 0; next = 0; hits = 0; mistakes = 0; playing = false
        message = "Нажми «Начать» · правая рука: большой палец на До"
        needsDisplay = true; update?()
    }
    func input(_ p: Int, _ v: Int, _ on: Bool) {
        if on { pressed.insert(p); piano.on(p,v) } else { pressed.remove(p); piano.off(p) }
        if playing && !demo && next < lesson.notes.count {
            if let held = hold {
                if !on && p == held.pitch {
                    if held.releaseIsCorrect(at:beat,waiting:waitMode) {
                        finishHold(p)
                    } else {
                        failHold("Нота пропущена без очков — играй следующую")
                    }
                } else if on && next+1 < lesson.notes.count && p == lesson.notes[next+1].pitch && (waitMode || abs(beat-lesson.notes[next+1].beat) < 0.45) {
                    // Legato: a new correct key can finish the previous note without its Note Off.
                    if held.releaseIsCorrect(at:beat,waiting:waitMode) { finishHold(held.pitch) }
                    else { failHold("Переходим к следующей ноте",releaseSound:false) }
                    beginHold(lesson.notes[next])
                } else if on && p != held.pitch {
                    recordMistake()
                    message = "Продолжай держать " + noteName(held.pitch)
                }
            } else if on {
                let target = lesson.notes[next]
                if p == target.pitch && abs(beat-target.beat) < 0.45 {
                    beginHold(target)
                } else { recordMistake(); message = "Попробуй " + noteName(target.pitch) }
            }
        }
        needsDisplay = true; update?()
    }
    func beginHold(_ target: Note) {
        if waitMode { beat = target.beat }
        hold = Hold(pitch:target.pitch,start:target.beat,end:target.beat+target.length)
        bird.origin = bird.position ?? birdTarget().0
        bird.elapsed = 0; bird.jumping = true
        message = "Держи " + noteName(target.pitch) + " до конца блока"
    }
    func recordMistake() {
        mistakes += 1; rewards.miss(); birdHealth.miss()
    }
    func finishHold(_ p: Int) {
        hold = nil; hits += 1; next += 1; rewards.hit()
        message = "Отличная длительность! " + noteName(p)
        glow[p] = 0.65; popTime = 1.15
        popText = rewards.combo >= 3 ? "СЕРИЯ ×\(rewards.combo)!" : "Отлично удержал!"
        burst(p)
        if birdHealth.success() {
            let target = birdTarget().0
            bird.returnTo(target,from:NSPoint(x:bounds.width+45,y:bounds.height-95))
            popTime = 1.8; popText = "Птичка вернулась!"
            message = "Три верные ноты подряд — птичка снова с тобой!"
        }
    }
    func failHold(_ explanation: String, releaseSound: Bool = true) {
        recordMistake()
        if let held = hold {
            if releaseSound { piano.off(held.pitch); pressed.remove(held.pitch) }
            if waitMode { beat = max(beat,held.end) }
            next += 1
        }
        hold = nil; message = explanation
    }
    func tick() {
        let now = ProcessInfo.processInfo.systemUptime; let dt = min(now-last,0.1); last = now
        defer { updateBird(dt:dt) }
        popTime = max(0, popTime-dt)
        for key in Array(glow.keys) { glow[key] = max(0, (glow[key] ?? 0)-dt); if glow[key] == 0 { glow.removeValue(forKey:key) } }
        for i in sparks.indices {
            sparks[i].life -= dt
            sparks[i].x += sparks[i].vx * dt; sparks[i].y += sparks[i].vy * dt
            sparks[i].vy -= 130 * dt
        }
        sparks.removeAll { $0.life <= 0 }
        if animated { needsDisplay = true }
        guard playing else { return }
        var proposed = beat + dt * bpm / 60
        if !demo && next < lesson.notes.count {
            if let held = hold {
                if waitMode { proposed = min(proposed,held.end) }
                let remaining = max(0,held.end-proposed)
                message = remaining <= 0.03 ? "Отпусти " + noteName(held.pitch) + " — нота закончилась!" : "Держи " + noteName(held.pitch) + String(format:" · ещё %.1f с", remaining * 60 / bpm)
                if !waitMode && proposed > held.end+held.tolerance {
                    failHold("Нота закончилась — отпускай раньше")
                }
            } else {
                let target = lesson.notes[next]
                if waitMode && proposed >= target.beat { proposed = target.beat; message = "Твоя очередь: " + noteName(target.pitch) }
                if !waitMode && proposed > target.beat + 0.45 { next += 1; recordMistake(); message = "Продолжай — следующая нота" }
            }
        }
        beat = proposed
        if demo {
            let sounding = lesson.notes.enumerated().filter { beat >= $0.element.beat && beat < $0.element.beat + $0.element.length }
            let indices = Dictionary(uniqueKeysWithValues:sounding.map { ($0.element.pitch,$0.offset) })
            for (pitch,index) in demoIndices where indices[pitch] != index { piano.off(pitch) }
            for (pitch,index) in indices where demoIndices[pitch] != index { piano.on(pitch) }
            demoNotes = Set(indices.keys); demoIndices = indices
        }
        if beat > (lesson.notes.last.map { $0.beat + $0.length + 1 } ?? 0) {
            if demo {
                reset()
                message = "Теперь твоя очередь! Нажми Play на MiniLab и сыграй сам"
                update?()
                return
            }
            playing = false; piano.silence(); demoNotes.removeAll(); demoIndices.removeAll()
            if !demo {
                celebration = true
                if animated {
                    for _ in 0..<110 {
                        let duration = Double.random(in:2...4)
                        sparks.append(Spark(x:CGFloat.random(in:0...bounds.width),y:bounds.height-30,vx:CGFloat.random(in:-60...60),vy:CGFloat.random(in:-180 ... -40),life:duration,duration:duration,color:noteColor(Int.random(in:48...72)),size:CGFloat.random(in:3...7)))
                    }
                }
            }
            message = demo ? "Теперь попробуй сыграть сам" : "Урок завершён! Верно: \(hits) из \(lesson.notes.count)"
        }
        needsDisplay = true; update?()
    }
    func birdTarget() -> (NSPoint,Int) {
        guard !lesson.notes.isEmpty else { return (NSPoint(x:40,y:keyHeight+23),0) }
        let index: Int
        if demo {
            index = lesson.notes.firstIndex(where: { $0.beat+$0.length > beat }) ?? lesson.notes.count-1
        } else { index = min(next,lesson.notes.count-1) }
        let note = lesson.notes[index]
        let x = max(30,min(bounds.width-30,keyRect(note.pitch).midX))
        let top = keyHeight + CGFloat(note.beat+note.length-beat)*78
        let y = top+20 <= bounds.height-85 && top >= keyHeight ? top+20 : keyHeight+22
        return (NSPoint(x:x,y:y),index)
    }
    func updateBird(dt:Double) {
        let (target,index) = birdTarget()
        if let position = bird.position, abs(position.x-target.x) > 2 { birdFacingRight = target.x > position.x }
        bird.advance(target:target,note:index,dt:dt,moving:playing || celebration,animated:animated,mistakes:birdHealth.errors)
        if playing { needsDisplay = true }
    }
    func drawBird() {
        if bird.escaping {
            guard bird.departure < 1 else { return }
            let t = bird.departure
            let origin = bird.departureOrigin
            let center = NSPoint(x:origin.x+CGFloat(t*t)*(bounds.width-origin.x+70),y:origin.y+CGFloat(t)*bounds.height*0.9)
            drawNoteBird(at:center,clock:bird.clock,flying:true,happy:false,animated:animated && (playing || celebration),facingRight:true,bruises:2)
            return
        }
        let target = birdTarget().0
        let position = bird.position ?? target
        // Keep the character above the keys and below the progress panel.
        let center = bird.returning ? position : NSPoint(x:max(30,min(bounds.width-30,position.x)),y:max(keyHeight+20,min(bounds.height-90,position.y)))
        drawNoteBird(at:center,clock:bird.clock,flying:bird.returning || bird.jumping || hold != nil || (demo && playing),happy:popTime > 0 || celebration,animated:animated && playing,facingRight:birdFacingRight,bruises:birdBruises(birdHealth.errors))
    }
    func noteColor(_ p: Int) -> NSColor {
        let hues: [CGFloat] = [0.01,0.05,0.10,0.13,0.18,0.38,0.43,0.51,0.57,0.66,0.73,0.87]
        return NSColor(calibratedHue:hues[p % 12],saturation:0.58,brightness:1,alpha:1)
    }
    func burst(_ p: Int) {
        guard animated && visibleNotes.contains(p) else { return }
        let x = keyRect(p).midX
        for _ in 0..<22 {
            let duration = Double.random(in:0.45...0.9)
            sparks.append(Spark(x:x,y:keyHeight+8,vx:CGFloat.random(in:-100...100),vy:CGFloat.random(in:60...210),life:duration,duration:duration,color:noteColor(p),size:CGFloat.random(in:2...5)))
        }
        if sparks.count > 240 { sparks.removeFirst(sparks.count-240) }
    }
    func drawStage() {
        let time = ProcessInfo.processInfo.systemUptime
        NSGradient(starting:NSColor(calibratedRed:0.095,green:0.065,blue:0.22,alpha:1),ending:NSColor(calibratedRed:0.025,green:0.10,blue:0.17,alpha:1))?.draw(in:bounds,angle:-90)
        if effectsEnabled {
            for i in 0..<48 {
                let x = CGFloat((i * 173 + 29) % 997) / 997 * bounds.width
                let y = keyHeight + CGFloat((i * 97 + 41) % 503) / 503 * max(0,bounds.height-keyHeight)
                let alpha = animated ? 0.17 + 0.12 * sin(time * 1.2 + Double(i)) : 0.22
                NSColor.white.withAlphaComponent(alpha).setFill()
                NSBezierPath(ovalIn:NSRect(x:x,y:y,width:i % 4 == 0 ? 3 : 1.5,height:i % 4 == 0 ? 3 : 1.5)).fill()
            }
        }
    }
    func drawGameHUD() {
        let top = bounds.height
        let area = NSRect(x:bounds.width*0.27,y:top-67,width:bounds.width*0.46,height:51)
        NSColor(calibratedWhite:0.03,alpha:0.76).setFill()
        NSBezierPath(roundedRect:area,xRadius:14,yRadius:14).fill()
        text("✦ \(rewards.points)   ·   Серия \(rewards.combo)   ·   \(min(next,lesson.notes.count))/\(lesson.notes.count) нот",NSRect(x:area.minX,y:area.minY+22,width:area.width,height:21),size:14,color:.white,bold:true)
        let track = NSRect(x:area.minX+18,y:area.minY+10,width:area.width-36,height:5)
        NSColor.white.withAlphaComponent(0.13).setFill(); NSBezierPath(roundedRect:track,xRadius:2.5,yRadius:2.5).fill()
        NSColor.systemMint.setFill()
        let progress = demo ? min(1,beat / (lesson.notes.last?.beat ?? 1)) : Double(next) / Double(max(1,lesson.notes.count))
        NSBezierPath(roundedRect:NSRect(x:track.minX,y:track.minY,width:track.width*progress,height:5),xRadius:2.5,yRadius:2.5).fill()
        if effectsEnabled {
            let bob: CGFloat = animated ? sin(ProcessInfo.processInfo.systemUptime*2.5)*4 : 0
            let center = NSPoint(x:bounds.width-53,y:top-48+bob)
            let happy = popTime > 0 || celebration
            NSColor(calibratedRed:0.67,green:0.59,blue:1,alpha:1).setFill()
            NSBezierPath(ovalIn:NSRect(x:center.x-23,y:center.y-23,width:46,height:46)).fill()
            NSColor.white.withAlphaComponent(0.3).setStroke()
            let orbit = NSBezierPath(ovalIn:NSRect(x:center.x-35,y:center.y-9,width:70,height:18)); orbit.lineWidth = 2; orbit.stroke()
            NSColor(calibratedWhite:0.1,alpha:1).setFill()
            for dx: CGFloat in [-8,8] { NSBezierPath(ovalIn:NSRect(x:center.x+dx-2,y:center.y+2,width:4,height:6)).fill() }
            let smile = NSBezierPath(); smile.move(to:NSPoint(x:center.x-7,y:center.y-5)); smile.curve(to:NSPoint(x:center.x+7,y:center.y-5),controlPoint1:NSPoint(x:center.x-4,y:center.y-(happy ? 15 : 10)),controlPoint2:NSPoint(x:center.x+4,y:center.y-(happy ? 15 : 10))); smile.lineWidth = 2; NSColor.black.setStroke(); smile.stroke()
        }
        if popTime > 0 && !celebration {
            let rise = animated ? CGFloat(1.15-popTime)*16 : 0
            text(popText,NSRect(x:bounds.width*0.3,y:keyHeight+90+rise,width:bounds.width*0.4,height:38),size:27,color:NSColor.systemYellow.withAlphaComponent(min(1,popTime*3)),bold:true)
        }
    }
    func drawCelebration() {
        guard celebration else { return }
        let width = min(430,bounds.width-40)
        let r = NSRect(x:(bounds.width-width)/2,y:keyHeight+max(12,(bounds.height-keyHeight-182)/2),width:width,height:182)
        NSColor(calibratedRed:0.12,green:0.10,blue:0.25,alpha:0.97).setFill(); NSBezierPath(roundedRect:r,xRadius:24,yRadius:24).fill()
        let stars = hits == lesson.notes.count ? "★  ★  ★" : hits * 2 >= lesson.notes.count ? "★  ★  ☆" : "★  ☆  ☆"
        text(stars,NSRect(x:r.minX,y:r.maxY-58,width:width,height:40),size:34,color:.systemYellow,bold:true)
        text(hits > 0 ? "Ты сыграл мелодию!" : "Хорошая тренировка!",NSRect(x:r.minX,y:r.maxY-96,width:width,height:30),size:24,color:.white,bold:true)
        text("\(hits) нот · \(rewards.points) очков · лучшая серия \(rewards.best)",NSRect(x:r.minX,y:r.minY+49,width:width,height:23),size:14,color:.systemMint)
        text("Нажми Play — сыграем ещё раз",NSRect(x:r.minX,y:r.minY+20,width:width,height:22),size:13,color:.lightGray)
    }
    var keyHeight: CGFloat { 136 }
    func keyRect(_ p: Int) -> NSRect {
        let w = bounds.width / CGFloat(whiteKeys.count)
        if let i = whiteKeys.firstIndex(of:p) { return NSRect(x: CGFloat(i)*w, y: 0, width: w, height: keyHeight) }
        let preceding = whiteKeys.filter { $0 < p }.count
        return NSRect(x: CGFloat(preceding)*w-w*0.31, y:keyHeight*0.4, width:w*0.62, height:keyHeight*0.6)
    }
    func text(_ s: String, _ rect: NSRect, size: CGFloat, color: NSColor, bold: Bool = false) {
        let style = NSMutableParagraphStyle(); style.alignment = .center
        (s as NSString).draw(in:rect, withAttributes:[.font: bold ? NSFont.boldSystemFont(ofSize:size) : NSFont.systemFont(ofSize:size), .foregroundColor:color, .paragraphStyle:style])
    }
    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: bounds).addClip()
        defer { NSGraphicsContext.restoreGraphicsState() }
        drawStage()
        let target = next < lesson.notes.count && playing && !demo ? lesson.notes[next].pitch : -1
        for p in whiteKeys {
            let r = keyRect(p)
            NSColor(white:1,alpha:0.045).setStroke(); let line = NSBezierPath(); line.move(to:NSPoint(x:r.minX,y:keyHeight)); line.line(to:NSPoint(x:r.minX,y:bounds.height)); line.stroke()
        }
        let scale: CGFloat = 78
        for (i,n) in lesson.notes.enumerated() {
            guard visibleNotes.contains(n.pitch) else { continue }
            let y = keyHeight + CGFloat(n.beat-beat)*scale
            let r = keyRect(n.pitch)
            guard y + CGFloat(n.length)*scale >= keyHeight && y < bounds.height else { continue }
            let block = NSRect(x:r.minX+4,y:max(y,keyHeight),width:r.width-8,height:max(0,min(CGFloat(n.length)*scale,y+CGFloat(n.length)*scale-keyHeight)))
            guard block.height > 0 else { continue }
            let color = i < next && !demo ? NSColor.systemGreen : noteColor(n.pitch)
            color.withAlphaComponent(i < next ? 0.35 : 0.95).setFill()
            NSBezierPath(roundedRect:block,xRadius:7,yRadius:7).fill()
            NSColor.white.withAlphaComponent(0.3).setFill()
            NSBezierPath(roundedRect:NSRect(x:block.minX+5,y:block.maxY-5,width:max(0,block.width-10),height:2),xRadius:1,yRadius:1).fill()
            if block.height > 23 { text(noteName(n.pitch) + (n.length == 0.5 ? " · ½" : n.length == 1.5 ? " · 1½" : " · \(Int(n.length))"),NSRect(x:block.minX,y:block.maxY-26,width:block.width,height:20),size:12,color:.black,bold:true) }
        }
        for p in whiteKeys { drawKey(p,target) }
        for p in visibleNotes where black(p) { drawKey(p,target) }
        NSColor.systemCyan.setFill(); NSRect(x:0,y:keyHeight,width:bounds.width,height:3).fill()
        if effectsEnabled {
            for (p,life) in glow where visibleNotes.contains(p) {
                let r = keyRect(p)
                let radius = CGFloat(1-life/0.65)*52+10
                noteColor(p).withAlphaComponent(life*0.8).setStroke()
                let ring = NSBezierPath(ovalIn:NSRect(x:r.midX-radius,y:keyHeight-radius,width:radius*2,height:radius*2)); ring.lineWidth = 3; ring.stroke()
            }
            for spark in sparks {
                spark.color.withAlphaComponent(max(0,spark.life/spark.duration)).setFill()
                NSBezierPath(roundedRect:NSRect(x:spark.x,y:spark.y,width:spark.size,height:spark.size*1.4),xRadius:1,yRadius:1).fill()
            }
        }
        drawBird()
        drawGameHUD()
        drawCelebration()
    }
    func drawKey(_ p: Int, _ target: Int) {
        let r = keyRect(p).insetBy(dx:1,dy:1)
        let active = pressed.contains(p) || demoNotes.contains(p)
        (active ? noteColor(p) : p == target ? noteColor(p).blended(withFraction:animated ? 0.12+0.12*sin(ProcessInfo.processInfo.systemUptime*5) : 0.12,of:.white)! : black(p) ? NSColor(calibratedWhite:0.10,alpha:1) : NSColor(calibratedWhite:0.93,alpha:1)).setFill()
        NSBezierPath(roundedRect:r,xRadius:4,yRadius:4).fill()
        if let held = hold, held.pitch == p {
            let progress = max(0,min(1,(beat-held.start)/(held.end-held.start)))
            NSColor.white.withAlphaComponent(0.75).setFill()
            NSBezierPath(roundedRect:NSRect(x:r.minX+5,y:r.minY+5,width:max(0,(r.width-10)*progress),height:5),xRadius:2,yRadius:2).fill()
        }
        if !black(p) { text(noteName(p),NSRect(x:r.minX,y:14,width:r.width,height:21),size:12,color:.darkGray,bold:true) }
        if p % 12 == 0 { text("C\(p/12-1)",NSRect(x:r.minX,y:38,width:r.width,height:18),size:10,color:.gray) }
    }
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow,from:nil)
        let order = Array(visibleNotes).filter { black($0) } + whiteKeys
        if let p = order.first(where: { keyRect($0).contains(point) }) { mousePitch = p; input(p,90,true) }
    }
    override func mouseUp(with event: NSEvent) { if let p = mousePitch { input(p,0,false) }; mousePitch = nil }
}

final class App: NSObject, NSApplicationDelegate {
    let songs = NSPopUpButton()
    let tempoSlider = NSSlider(value:70,minValue:30,maxValue:140,target:nil,action:nil)
    let tempoHint = NSTextField(labelWithString:"")
    let learnTempo = NSButton(title:"Назначить темп…",target:nil,action:nil)
    var learningTempo = false
    var tempoCC = UserDefaults.standard.object(forKey:"tempoCC") as? Int ?? 1
    var window: NSWindow!; let game = GameView(frame:.zero)
    let lastMIDI = NSTextField(labelWithString:"Вход: нажми клавишу MiniLab для проверки"); let status = NSTextField(labelWithString:""); let feedback = NSTextField(labelWithString:"")
    let listenButton = NSButton(title:"Послушать · MIDI 42",target:nil,action:nil)
    let score = NSTextField(labelWithString:""); let play = NSButton(title:"Начать",target:nil,action:nil)
    func applicationDidFinishLaunching(_ notification: Notification) {
        if tempoCC == 16 { tempoCC = 1; UserDefaults.standard.set(1,forKey:"tempoCC") }
        window = NSWindow(contentRect:NSRect(x:0,y:0,width:1100,height:840),styleMask:[.titled,.closable,.miniaturizable,.resizable],backing:.buffered,defer:false)
        window.title = "MiniLab · Учимся играть"; window.minSize = NSSize(width:1050,height:780)
        let root = NSView(); window.contentView = root
        let title = NSTextField(labelWithString:"MINILAB / КОСМИЧЕСКОЕ ПИАНИНО"); title.font = .boldSystemFont(ofSize:22)
        let subtitle = NSTextField(labelWithString:"Knob 1: 0–11 — мелодии · MIDI 42 — послушать · Play — играть"); subtitle.textColor = .secondaryLabelColor
        songs.addItems(withTitles:lessons.map(\.name)); songs.target = self; songs.action = #selector(selectLesson(_:)); songs.widthAnchor.constraint(equalToConstant:230).isActive = true
        play.target = self; play.action = #selector(toggle); play.bezelStyle = .rounded
        let restart = NSButton(title:"Сначала",target:self,action:#selector(reset)); restart.bezelStyle = .rounded
        let demo = listenButton; demo.target = self; demo.action = #selector(setDemo(_:)); demo.bezelStyle = .rounded
        let wait = NSButton(checkboxWithTitle:"Ждать верную ноту",target:self,action:#selector(setWait(_:))); wait.state = .on
        let speed = tempoSlider; speed.target = self; speed.action = #selector(speed(_:)); speed.widthAnchor.constraint(equalToConstant:130).isActive = true
        score.stringValue = "70 BPM · 0 верно"
        let header = NSStackView(views:[title,subtitle]); header.orientation = .vertical; header.alignment = .leading; header.spacing = 5
        let calibrate = NSButton(title:"Настроить клавиатуру",target:self,action:#selector(calibrateKeyboard)); calibrate.bezelStyle = .rounded
        let effects = NSButton(checkboxWithTitle:"Космические эффекты",target:self,action:#selector(setEffects(_:))); effects.state = .on
        let inputControls = NSStackView(views:[lastMIDI,calibrate,effects]); inputControls.spacing = 16
        let controls = NSStackView(views:[songs,play,restart,wait,demo,speed]); controls.spacing = 12
        learnTempo.target = self; learnTempo.action = #selector(assignTempo)
        tempoHint.stringValue = tempoCC == 1 ? "Темп: правый сенсор MiniLab · 30–140 BPM" : "Темп: ползунок CC \(tempoCC) · 30–140 BPM"
        tempoHint.font = .systemFont(ofSize:12); tempoHint.textColor = .secondaryLabelColor
        learnTempo.bezelStyle = .rounded
        let tempoControls = NSStackView(views:[tempoHint,learnTempo,score]); tempoControls.spacing = 12
        status.textColor = .secondaryLabelColor; status.font = .systemFont(ofSize:12)
        feedback.font = .systemFont(ofSize:16,weight:.medium)
        let footer = NSTextField(labelWithString:"Нажми у голубой линии → держи, пока блок проходит линию → отпусти в конце блока. До = C.")
        footer.font = .systemFont(ofSize:12); footer.textColor = .secondaryLabelColor
        let stack = NSStackView(views:[header,status,inputControls,controls,tempoControls,game,feedback,footer]); stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false; root.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo:root.leadingAnchor,constant:24),stack.trailingAnchor.constraint(equalTo:root.trailingAnchor,constant:-24),stack.topAnchor.constraint(equalTo:root.topAnchor,constant:24),stack.bottomAnchor.constraint(equalTo:root.bottomAnchor,constant:-20),game.widthAnchor.constraint(equalTo:stack.widthAnchor),game.heightAnchor.constraint(greaterThanOrEqualToConstant:320)])
        game.update = { [weak self] in self?.refresh() }
        game.midi.status = { [weak self] s in self?.status.stringValue = s }
        game.incoming = { [weak self] s in self?.lastMIDI.stringValue = s }
        game.midi.controlHandler = { [weak self] cc,value in self?.controller(cc,value) }
        game.midi.connect(); refresh()
        if let error = game.piano.error { status.stringValue = "Ошибка звука: " + error }
        window.center(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps:true)
    }
    func refresh() { listenButton.title = game.demo ? "Остановить образец" : "Послушать · MIDI 42"; tempoSlider.doubleValue = game.bpm; feedback.stringValue = game.message; score.stringValue = "\(Int(game.bpm)) BPM · \(game.hits) верно · \(game.mistakes) ошибок"; play.title = game.playing ? "Пауза" : "Начать" }
    @objc func assignTempo() {
        learningTempo.toggle()
        learnTempo.title = learningTempo ? "Отмена" : "Назначить темп…"
        tempoHint.stringValue = learningTempo ? "Подвигай нужный сенсор или ползунок MiniLab" : "Темп: ползунок CC \(tempoCC) · 30–140 BPM"
    }
    func controller(_ cc: Int, _ value: Int) {
        if cc == 16 {
            if learningTempo {
                tempoHint.stringValue = "Knob 1 занят выбором мелодий — подвигай другой регулятор"
                return
            }
            let current = songs.indexOfSelectedItem
            let index = melodyForKnob(value,count:lessons.count)
            if index != current {
                songs.selectItem(at:index)
                selectLesson(songs)
            }
            lastMIDI.stringValue = "Knob 1 = \(value) · песня \(index) (0–\(lessons.count-1)) · " + lessons[index].name
            return
        }
        if learningTempo {
            // Pedals and MIDI bank/parameter selectors aren't continuous tempo controls.
            guard ![0,32,64,96,97,98,99,100,101,120,121,123].contains(cc) else { return }
            tempoCC = cc; UserDefaults.standard.set(cc,forKey:"tempoCC")
            learningTempo = false; learnTempo.title = "Назначить темп…"
            tempoHint.stringValue = "Темп: ползунок CC \(cc) · 30–140 BPM"
        }
        guard cc == tempoCC else { return }
        game.bpm = tempoForController(value)
        lastMIDI.stringValue = "MiniLab · темп \(Int(game.bpm)) BPM"
        refresh()
    }
    @objc func calibrateKeyboard() {
        game.reset(); game.calibrating = true
        lastMIDI.stringValue = "Нажми самое левое До (C) на MiniLab — совместим 25 клавиш"
    }
    @objc func selectLesson(_ sender: NSPopUpButton) { game.lesson = lessons[sender.indexOfSelectedItem].shifted(game.keyboardLow - 60); game.reset() }
    @objc func toggle() { game.setPlaying(!game.playing) }
    @objc func reset() { game.reset() }
    @objc func setDemo(_ sender: NSButton) { if game.demo { game.reset() } else { game.startPreview() } }
    @objc func setEffects(_ sender: NSButton) {
        game.effectsEnabled = sender.state == .on
        game.sparks.removeAll(); game.glow.removeAll(); game.needsDisplay = true
    }
    @objc func setWait(_ sender: NSButton) { game.waitMode = sender.state == .on }
    @objc func speed(_ sender: NSSlider) { game.bpm = sender.doubleValue; refresh() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
if CommandLine.arguments.contains("--self-test") {
    assert(lessons.count == 12)
    for lesson in lessons {
        assert(!lesson.notes.isEmpty)
        assert(lesson.notes.allSatisfy { (60...84).contains($0.pitch) && $0.length > 0 })
        assert(zip(lesson.notes,lesson.notes.dropFirst()).allSatisfy { $0.beat < $1.beat })
    }
    for low in [36,48,60,72] {
        let shifted = lessons[0].shifted(low - 60)
        assert(shifted.notes.first!.pitch == low)
        assert(shifted.notes.allSatisfy { (low...(low+24)).contains($0.pitch) })
    }
    let held = Hold(pitch:60,start:3,end:5)
    assert(!held.releaseIsCorrect(at:3.1,waiting:true))
    assert(!held.releaseIsCorrect(at:4.7,waiting:true))
    assert(held.releaseIsCorrect(at:4.9,waiting:true))
    assert(held.releaseIsCorrect(at:5,waiting:true))
    assert(held.releaseIsCorrect(at:5.1,waiting:false))
    assert(!held.releaseIsCorrect(at:5.3,waiting:false))
    let short = Hold(pitch:60,start:3,end:3.5)
    assert(!short.releaseIsCorrect(at:3.3,waiting:true))
    assert(short.releaseIsCorrect(at:3.45,waiting:true))
    for lesson in lessons {
        for (a,b) in zip(lesson.notes,lesson.notes.dropFirst()) { assert(abs(a.beat+a.length-b.beat) < 0.0001) }
        assert(Set(lesson.notes.map(\.length)).count > 1)
    }
    assert(lessons[1].notes[12].length == 1.5 && lessons[1].notes[13].length == 0.5)
    assert(lessons[2].notes[6].length == 2)
    let game = GameView(frame:NSRect(x:0,y:0,width:1000,height:500))
    game.timer?.invalidate(); game.effectsEnabled = false
    game.piano.engine.mainMixerNode.outputVolume = 0
    game.beat = 3; game.setPlaying(true)
    game.input(48,90,true)
    assert(game.hold != nil && game.hits == 0 && game.next == 0)
    game.beat = 3.2; game.input(48,0,false)
    assert(game.hold == nil && game.hits == 0 && game.next == 1 && game.beat == 4 && game.mistakes == 1)
    assert(game.rewards.points == 0)
    game.input(50,90,true); game.beat = 5; game.input(50,0,false)
    assert(game.hits == 1 && game.next == 2 && game.rewards.points == 110)
    game.input(52,90,true); assert(game.hold != nil)
    game.setPlaying(false)
    assert(game.hold == nil && game.beat == 5 && game.hits == 1)
    game.setPlaying(true); game.input(52,90,true)
    game.beat = 6; game.input(52,0,false)
    assert(game.hits == 2 && game.next == 3)
    game.reset(); assert(game.hold == nil && game.hits == 0 && game.rewards.points == 0)
    game.waitMode = false; game.beat = 3; game.setPlaying(true)
    game.input(48,90,true); game.beat = 3.2; game.input(48,0,false)
    assert(game.next == 1 && game.beat == 3.2 && game.hits == 0 && game.rewards.points == 0)
    game.reset()
    // Adjacent notes overlap: releasing the old key must not end the new hold.
    game.waitMode = true; game.beat = 3; game.setPlaying(true)
    game.input(48,90,true); game.beat = 3.9; game.input(50,90,true)
    assert(game.hits == 1 && game.next == 1 && game.hold?.pitch == 50 && game.mistakes == 0)
    assert(game.pressed.contains(48) && game.pressed.contains(50))
    game.input(48,0,false)
    assert(game.hold?.pitch == 50 && game.mistakes == 0)
    game.beat = 5; game.input(50,0,false)
    assert(game.hits == 2 && game.next == 2)
    game.reset(); game.beat = 3; game.setPlaying(true)
    game.input(48,90,true); game.beat = 3.2; game.input(50,90,true)
    assert(game.hits == 0 && game.next == 1 && game.hold?.pitch == 50 && game.rewards.points == 0)
    game.input(48,0,false); assert(game.hold?.pitch == 50)
    game.beat = 5; game.input(50,0,false); assert(game.hits == 1)
    game.reset(); game.waitMode = false; game.beat = 3; game.setPlaying(true)
    game.input(48,90,true); game.beat = 3.9; game.input(50,90,true)
    assert(game.hits == 1 && game.hold?.pitch == 50 && game.beat == 3.9)
    game.input(48,0,false); assert(game.hold?.pitch == 50)
    game.reset(); game.waitMode = true
    print("PASS: overlapping keys, old-key release, early legato without points and continuous-mode legato")
    game.startPreview()
    assert(game.demo && game.playing && game.next == 0)
    game.beat = game.lesson.notes.last!.beat + game.lesson.notes.last!.length + 2
    game.last = ProcessInfo.processInfo.systemUptime
    game.tick()
    assert(!game.demo && !game.playing && game.beat == 0 && game.hits == 0 && game.next == 0)
    game.setPlaying(true); game.beat = 3; game.input(48,90,true)
    assert(game.hold != nil && !game.demo)
    game.reset()
    print("PASS: preview playback returns to manual practice at start")
    print("PASS: early release skips without points, next note scores, pause/resume, continuous-mode timing and reset")
    print("PASS: musical durations, contiguous timing, early/correct/late release and short-note tolerance")
    game.reset(); game.beat = 3; game.setPlaying(true)
    for _ in 0..<4 { game.input(83,90,true); game.input(83,0,false) }
    game.updateBird(dt:0.1); game.updateBird(dt:0.1)
    assert(game.birdHealth.errors == 4 && game.bird.escaping)
    for _ in 0..<3 {
        let note = game.lesson.notes[game.next]
        game.beat = note.beat; game.input(note.pitch,90,true)
        game.beat = note.beat+note.length; game.input(note.pitch,0,false)
    }
    assert(game.birdHealth.errors == 0 && game.bird.returning && !game.bird.escaping)
    assert(game.mistakes == 4 && game.hits == 3)
    game.input(83,90,true); game.input(83,0,false)
    assert(game.birdHealth.errors == 1 && game.mistakes == 5)
    game.reset(); assert(game.birdHealth.errors == 0 && !game.bird.returning)
    var health = BirdRecovery()
    health.miss(); health.miss()
    assert(!health.success()); assert(!health.success())
    health.miss(); assert(health.streak == 0 && health.errors == 3)
    assert(!health.success()); assert(!health.success()); assert(health.success())
    assert(health.errors == 0)
    print("PASS: three consecutive correct notes restore bird, interrupted streak resets, total errors preserved")
    var bird = NoteBird()
    bird.advance(target:NSPoint(x:40,y:180),note:0,dt:0.016,moving:false,animated:true)
    assert(bird.position == NSPoint(x:40,y:180))
    bird.advance(target:NSPoint(x:120,y:220),note:1,dt:0.1,moving:true,animated:true)
    assert(bird.jumping && bird.position!.x > 40 && bird.position!.x < 120)
    let paused = bird.position
    bird.advance(target:NSPoint(x:200,y:300),note:2,dt:0.1,moving:false,animated:true)
    assert(bird.position == paused && bird.anchor == 1)
    for _ in 0..<5 { bird.advance(target:NSPoint(x:120,y:220),note:1,dt:0.1,moving:true,animated:true) }
    assert(!bird.jumping && bird.position == NSPoint(x:120,y:220))
    bird.advance(target:NSPoint(x:250,y:200),note:2,dt:0.016,moving:true,animated:false)
    assert(!bird.jumping && bird.position == NSPoint(x:250,y:200))
    assert(birdBruises(0) == 0 && birdBruises(1) == 0)
    assert(birdBruises(2) == 1 && birdBruises(3) == 2)
    bird.advance(target:NSPoint(x:250,y:200),note:2,dt:0.1,moving:true,animated:true,mistakes:3)
    assert(!bird.escaping)
    bird.advance(target:NSPoint(x:250,y:200),note:2,dt:0.1,moving:true,animated:true,mistakes:4)
    assert(bird.escaping && bird.departure > 0 && bird.departure < 1)
    let departure = bird.departure
    bird.advance(target:NSPoint(x:250,y:200),note:2,dt:1,moving:false,animated:true,mistakes:4)
    assert(bird.departure == departure)
    bird.advance(target:NSPoint(x:250,y:200),note:2,dt:2,moving:true,animated:true,mistakes:4)
    assert(bird.departure == 1)
    bird = NoteBird(); assert(!bird.escaping && bird.departure == 0)
    print("PASS: first mistake unchanged, bruises at 2/3, flight at 4, pause and reset")
    print("PASS: inline bird jumps between notes, freezes on pause and supports reduced motion")
    var rewards = Rewards()
    for _ in 0..<5 { rewards.hit() }
    assert(rewards.combo == 5 && rewards.best == 5 && rewards.points == 650)
    rewards.miss(); assert(rewards.combo == 0 && rewards.best == 5 && rewards.points == 650)
    rewards.hit(); assert(rewards.combo == 1 && rewards.points == 760)
    print("PASS: combo, points, best streak and retry")
    for i in 0..<lessons.count { assert(melodyForKnob(i,count:lessons.count) == i) }
    assert(melodyForKnob(127,count:12) == 11)
    assert(melodyForKnob(-1,count:12) == 0)
    print("PASS: direct Knob value to song index, all 12 songs and range bounds")
    assert(tempoForController(0) == 30 && tempoForController(127) == 140)
    assert(tempoForController(64) == 85)
    assert((0..<127).allSatisfy { tempoForController($0) <= tempoForController($0+1) })
    let input = MIDIInput()
    var controls: [(Int,Int)] = []
    input.controlHandler = { controls.append(($0,$1)) }
    input.consume([0xB0,1,0,1,127,0xF8,74])
    input.consume([64])
    assert(controls.count == 3 && controls[0].0 == 1 && controls[0].1 == 0 && controls[1].1 == 127 && controls[2].0 == 74 && controls[2].1 == 64)
    print("PASS: tempo mapping and fragmented/running-status CC messages")
    var events: [(Int,Int,Bool)] = []
    input.handler = { events.append(($0,$1,$2)) }
    input.consume([0x90,60])
    input.consume([100,62,0,0xF8,0x80,60,64,0xB0,1,127,0x91,67,90])
    assert(events.count == 4)
    assert(events[0].0 == 60 && events[0].2)
    assert(events[1].0 == 62 && !events[1].2)
    assert(events[2].0 == 60 && !events[2].2)
    assert(events[3].0 == 67 && events[3].2)
    events.removeAll()
    input.consume([0x90,60], source: 1)
    input.consume([0x90,67,100], source: 2)
    input.consume([90], source: 1)
    assert(events.count == 2 && events[0].0 == 67 && events[1].0 == 60)
    print("PASS: isolated MIDI sources")
    print("PASS: lesson timing, keyboard range, fragmented MIDI, running status, note-off, realtime and control messages")
    exit(0)
}
let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = App(); app.delegate = delegate
app.run()
