import AppKit

func birdBruises(_ mistakes: Int) -> Int { max(0,min(2,mistakes-1)) }

struct BirdRecovery {
    var errors = 0
    var streak = 0
    mutating func miss() { errors += 1; streak = 0 }
    mutating func success() -> Bool {
        streak += 1
        if streak >= 3 && errors > 0 { errors = 0; streak = 0; return true }
        return false
    }
}

struct NoteBird {
    var position: NSPoint?
    var origin = NSPoint.zero
    var anchor: Int?
    var elapsed = 0.0
    var jumping = false
    var clock = 0.0
    var returning = false
    var escaping = false
    var departure = 0.0
    var departureOrigin = NSPoint.zero
    mutating func returnTo(_ target:NSPoint, from point:NSPoint) {
        self = NoteBird()
        position = point; origin = point
        returning = true; jumping = true
    }
    mutating func advance(target: NSPoint, note: Int, dt: Double, moving: Bool, animated: Bool, mistakes: Int = 0) {
        guard let current = position else { position = target; anchor = note; return }
        if mistakes >= 4 && !escaping {
            escaping = true; departureOrigin = current; departure = 0
        }
        if escaping {
            if moving { clock += dt; departure = animated ? min(1,departure+dt/1.3) : 1 }
            return
        }
        guard moving else { return }
        clock += dt
        if note != anchor {
            if !returning { origin = current; elapsed = 0 }
            jumping = true; anchor = note
        }
        if !animated { position = target; jumping = false; return }
        if jumping {
            elapsed += dt
            let t = min(1,elapsed / (returning ? 0.95 : 0.40))
            let eased = t*t*(3-2*t)
            position = NSPoint(x:origin.x+(target.x-origin.x)*eased,y:origin.y+(target.y-origin.y)*eased+sin(t * .pi)*48)
            if t >= 1 { jumping = false; returning = false }
        } else {
            position = NSPoint(x:current.x+(target.x-current.x)*min(1,dt*16),y:current.y+(target.y-current.y)*min(1,dt*16))
        }
    }
}

func drawNoteBird(at c:NSPoint, clock:Double, flying:Bool, happy:Bool, animated:Bool, facingRight:Bool, bruises:Int = 0) {
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    let transform = NSAffineTransform()
    transform.translateX(by:c.x,yBy:c.y)
    transform.scaleX(by:facingRight ? 1 : -1,yBy:1)
    transform.concat()
    func oval(_ r:NSRect,_ color:NSColor) { color.setFill(); NSBezierPath(ovalIn:r).fill() }
    oval(NSRect(x:-17,y:-20,width:34,height:6),.black.withAlphaComponent(0.15))
    oval(NSRect(x:-20,y:-15,width:40,height:34),NSColor(calibratedRed:1,green:0.76,blue:0.21,alpha:1))
    oval(NSRect(x:-12,y:-12,width:25,height:21),NSColor(calibratedRed:1,green:0.91,blue:0.50,alpha:1))
    let lift: CGFloat = flying && animated ? CGFloat(sin(clock*22))*8 : 0
    oval(NSRect(x:-24,y:-3+lift,width:24,height:13),NSColor(calibratedRed:0.99,green:0.48,blue:0.16,alpha:1))
    oval(NSRect(x:-7,y:5,width:9,height:11),.white)
    oval(NSRect(x:-2,y:8,width:4,height:5),NSColor(calibratedWhite:0.12,alpha:1))
    oval(NSRect(x:3,y:4,width:12,height:13),.white)
    oval(NSRect(x:9,y:7,width:5,height:6),NSColor(calibratedWhite:0.12,alpha:1))
    if bruises >= 1 {
        oval(NSRect(x:3,y:-3,width:12,height:7),NSColor(calibratedRed:0.45,green:0.27,blue:0.63,alpha:0.95))
        oval(NSRect(x:6,y:-2,width:6,height:3),NSColor(calibratedRed:0.63,green:0.43,blue:0.78,alpha:1))
    }
    if bruises >= 2 {
        oval(NSRect(x:-8,y:-2,width:10,height:6),NSColor(calibratedRed:0.45,green:0.27,blue:0.63,alpha:0.95))
        oval(NSRect(x:-5,y:-1,width:5,height:3),NSColor(calibratedRed:0.63,green:0.43,blue:0.78,alpha:1))
    }
    let beak = NSBezierPath(); beak.move(to:NSPoint(x:18,y:4)); beak.line(to:NSPoint(x:29,y:0)); beak.line(to:NSPoint(x:18,y:-4)); beak.close(); NSColor.systemOrange.setFill(); beak.fill()
    if happy && bruises == 0 { oval(NSRect(x:9,y:-7,width:6,height:4),.systemPink.withAlphaComponent(0.7)) }
    if !flying {
        NSColor.systemOrange.setFill()
        for x:CGFloat in [-10,3] { NSBezierPath(roundedRect:NSRect(x:x,y:-18,width:10,height:3),xRadius:1.5,yRadius:1.5).fill() }
    }
}
