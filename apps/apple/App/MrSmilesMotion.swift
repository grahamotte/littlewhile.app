import CoreGraphics
import Foundation

struct MrSmilesMotion {
    private(set) var position: CGPoint
    private(set) var velocity: CGVector
    private(set) var elapsed: TimeInterval = 0
    private(set) var rotation: Double
    private(set) var angularVelocity: Double
    private(set) var leftWinkUntil: TimeInterval = -.infinity
    private(set) var rightWinkUntil: TimeInterval = -.infinity

    private let bounds: Bounds
    private let livelyRebounds: Bool
    private var anchorPosition: CGPoint
    private var anchorRotation: Double
    private var anchorTime: TimeInterval = 0
    private var random: Random
    private static let tolerance: CGFloat = 0.000_000_1
    private static let cruisingSpeed: CGFloat = 72
    private static let maximumAmbientSpeed: CGFloat = 84

    var leftEyeWinking: Bool {
        elapsed < leftWinkUntil
    }

    var rightEyeWinking: Bool {
        elapsed < rightWinkUntil
    }

    init(seed: UUID, size: CGSize, faceRadius: CGFloat, screenCornerRadius: CGFloat) {
        var random = Random(seed: seed)
        let quadrant = Double(random.next() % 4)
        let angle = quadrant * .pi / 2 + .pi / 8 + random.unit() * .pi / 4
        let speed = 48 + random.unit() * 36
        self.init(
            size: size,
            faceRadius: faceRadius,
            screenCornerRadius: screenCornerRadius,
            position: CGPoint(x: size.width / 2, y: size.height / 2),
            velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
            randomState: random.next(),
            livelyRebounds: true,
        )
    }

    init(
        size: CGSize,
        faceRadius: CGFloat,
        screenCornerRadius: CGFloat,
        position: CGPoint,
        velocity: CGVector,
        rotation: Double = 0,
        angularVelocity: Double = 0,
        randomState: UInt64 = 0xA076_1D64_78BD_642F,
        livelyRebounds: Bool = false,
    ) {
        bounds = Bounds(size: size, faceRadius: faceRadius, screenCornerRadius: screenCornerRadius)
        self.livelyRebounds = livelyRebounds
        self.position = bounds.confined(position)
        self.rotation = rotation.isFinite ? rotation : 0
        self.angularVelocity = angularVelocity.isFinite && bounds.faceRadius > 0 ? angularVelocity : 0
        anchorPosition = self.position
        anchorRotation = self.rotation
        random = Random(state: randomState)
        self.velocity = CGVector(
            dx: bounds.width > Self.tolerance && velocity.dx.isFinite ? velocity.dx : 0,
            dy: bounds.height > Self.tolerance && velocity.dy.isFinite ? velocity.dy : 0,
        )
    }

    @discardableResult
    mutating func flick(velocity: CGVector) -> Bool {
        guard velocity.dx.isFinite, velocity.dy.isFinite else { return false }
        var nextVelocity = CGVector(
            dx: bounds.width > Self.tolerance ? velocity.dx : 0,
            dy: bounds.height > Self.tolerance ? velocity.dy : 0,
        )
        let largestComponent = max(abs(nextVelocity.dx), abs(nextVelocity.dy))
        guard largestComponent > 0 else { return false }
        let direction = CGVector(dx: nextVelocity.dx / largestComponent, dy: nextVelocity.dy / largestComponent)
        let directionLength = hypot(direction.dx, direction.dy)
        guard largestComponent >= 20 / directionLength else { return false }
        if largestComponent > 500 / directionLength {
            nextVelocity = CGVector(dx: direction.dx * 500 / directionLength, dy: direction.dy * 500 / directionLength)
        }
        self.velocity = nextVelocity
        anchorPosition = position
        anchorRotation = rotation
        anchorTime = elapsed
        return true
    }

    mutating func stop() {
        velocity = .zero
        angularVelocity = 0
        anchorPosition = position
        anchorRotation = rotation
        anchorTime = elapsed
    }

    @discardableResult
    mutating func move(to target: CGPoint) -> Bool {
        guard target.x.isFinite, target.y.isFinite else { return false }
        let confined = bounds.confined(target)
        position = confined
        velocity = .zero
        angularVelocity = 0
        anchorPosition = confined
        anchorRotation = rotation
        anchorTime = elapsed
        return true
    }

    mutating func advance(to time: TimeInterval) {
        guard time.isFinite, time > elapsed else { return }
        var remaining = time - anchorTime
        var collisionTime = anchorTime
        while remaining > 0 {
            guard let collision = bounds.nextCollision(position: anchorPosition, velocity: velocity, within: remaining) else {
                rotation = anchorRotation + angularVelocity * remaining
                position = bounds.confined(CGPoint(
                    x: anchorPosition.x + velocity.dx * remaining,
                    y: anchorPosition.y + velocity.dy * remaining,
                ))
                break
            }
            rotation = anchorRotation + angularVelocity * collision.time
            position = bounds.confined(CGPoint(
                x: anchorPosition.x + velocity.dx * collision.time,
                y: anchorPosition.y + velocity.dy * collision.time,
            ))
            collisionTime += collision.time
            remaining = time - collisionTime
            let cosine = cos(rotation)
            let sine = sin(rotation)
            let incomingX = velocity.dx * cosine + velocity.dy * sine
            for normal in collision.normals {
                let localX = normal.dx * cosine + normal.dy * sine
                let localY = normal.dy * cosine - normal.dx * sine
                if localY < -Self.tolerance {
                    if localX < -Self.tolerance || (abs(localX) <= Self.tolerance && incomingX < 0) {
                        leftWinkUntil = collisionTime + 1
                    } else {
                        rightWinkUntil = collisionTime + 1
                    }
                }
                let projection = velocity.dx * normal.dx + velocity.dy * normal.dy
                if projection > 0 {
                    velocity.dx -= 2 * projection * normal.dx
                    velocity.dy -= 2 * projection * normal.dy
                }
            }
            if livelyRebounds {
                varyRebound(collision.normals)
            }
            anchorPosition = position
            anchorRotation = rotation
            anchorTime = collisionTime
        }
        elapsed = time
    }

    private mutating func varyRebound(_ normals: [CGVector]) {
        let speed = hypot(velocity.dx, velocity.dy)
        guard speed > Self.tolerance else { return }
        let settledSpeed = speed > Self.maximumAmbientSpeed
            ? Self.cruisingSpeed + (speed - Self.cruisingSpeed) * 0.72
            : speed
        let reflectedDirection = CGVector(dx: velocity.dx / speed, dy: velocity.dy / speed)
        let jitter = (random.unit() - 0.5) * .pi / 5
        let cosine = cos(jitter)
        let sine = sin(jitter)
        var direction = CGVector(
            dx: (velocity.dx * cosine - velocity.dy * sine) / speed,
            dy: (velocity.dx * sine + velocity.dy * cosine) / speed,
        )
        if normals.contains(where: { direction.dx * $0.dx + direction.dy * $0.dy >= -Self.tolerance }) {
            direction = reflectedDirection
        }
        if bounds.width > Self.tolerance, bounds.height > Self.tolerance {
            let minimumComponent: CGFloat = 0.24
            if abs(direction.dx) < minimumComponent {
                direction.dx = copysign(minimumComponent, direction.dx == 0 ? (random.unit() < 0.5 ? -1 : 1) : direction.dx)
            }
            if abs(direction.dy) < minimumComponent {
                direction.dy = copysign(minimumComponent, direction.dy == 0 ? (random.unit() < 0.5 ? -1 : 1) : direction.dy)
            }
            let length = hypot(direction.dx, direction.dy)
            direction.dx /= length
            direction.dy /= length
        }
        if normals.contains(where: { direction.dx * $0.dx + direction.dy * $0.dy >= -Self.tolerance }) {
            direction = reflectedDirection
        }
        velocity = CGVector(dx: direction.dx * settledSpeed, dy: direction.dy * settledSpeed)
        if bounds.faceRadius > 0, let normal = normals.first {
            let tangent = CGVector(dx: -normal.dy, dy: normal.dx)
            let rollingVelocity = velocity.dx * tangent.dx + velocity.dy * tangent.dy
            angularVelocity = angularVelocity * 0.65 - rollingVelocity / bounds.faceRadius * 0.35
        }
    }

    private struct Collision {
        var time: TimeInterval
        var normals: [CGVector]
    }

    private struct Bounds {
        let minX: CGFloat
        let minY: CGFloat
        let maxX: CGFloat
        let maxY: CGFloat
        let radius: CGFloat
        let faceRadius: CGFloat

        var width: CGFloat { maxX - minX }
        var height: CGFloat { maxY - minY }

        init(size: CGSize, faceRadius: CGFloat, screenCornerRadius: CGFloat) {
            let width = size.width.isFinite ? max(0, size.width) : 0
            let height = size.height.isFinite ? max(0, size.height) : 0
            let halfSide = min(width, height) / 2
            let face = faceRadius.isFinite ? min(halfSide, max(0, faceRadius)) : 0
            let corner = screenCornerRadius.isFinite ? min(halfSide, max(0, screenCornerRadius)) : 0
            self.faceRadius = face
            minX = face
            minY = face
            maxX = width - face
            maxY = height - face
            radius = max(0, corner - face)
        }

        func confined(_ point: CGPoint) -> CGPoint {
            let x = point.x.isFinite ? min(maxX, max(minX, point.x)) : (minX + maxX) / 2
            let y = point.y.isFinite ? min(maxY, max(minY, point.y)) : (minY + maxY) / 2
            guard radius > 0 else { return CGPoint(x: x, y: y) }
            let center = CGPoint(
                x: min(maxX - radius, max(minX + radius, x)),
                y: min(maxY - radius, max(minY + radius, y)),
            )
            let dx = x - center.x
            let dy = y - center.y
            let distance = hypot(dx, dy)
            guard distance > radius else { return CGPoint(x: x, y: y) }
            return CGPoint(x: center.x + dx * radius / distance, y: center.y + dy * radius / distance)
        }

        func nextCollision(position: CGPoint, velocity: CGVector, within duration: TimeInterval) -> Collision? {
            var result: Collision?
            func consider(_ time: CGFloat, normal: CGVector) {
                guard time.isFinite, time >= -MrSmilesMotion.tolerance, time <= duration,
                      velocity.dx * normal.dx + velocity.dy * normal.dy > MrSmilesMotion.tolerance else { return }
                let time = max(0, time)
                if let existing = result {
                    if abs(time - existing.time) <= MrSmilesMotion.tolerance {
                        if !existing.normals.contains(where: {
                            abs($0.dx - normal.dx) <= MrSmilesMotion.tolerance &&
                                abs($0.dy - normal.dy) <= MrSmilesMotion.tolerance
                        }) {
                            result?.normals.append(normal)
                        }
                    } else if time < existing.time {
                        result = Collision(time: time, normals: [normal])
                    }
                } else {
                    result = Collision(time: time, normals: [normal])
                }
            }
            if velocity.dx != 0 {
                for (edge, direction) in [(minX, CGFloat(-1)), (maxX, CGFloat(1))] {
                    let time = (edge - position.x) / velocity.dx
                    let y = position.y + velocity.dy * time
                    if y >= minY + radius - MrSmilesMotion.tolerance && y <= maxY - radius + MrSmilesMotion.tolerance {
                        consider(time, normal: CGVector(dx: direction, dy: 0))
                    }
                }
            }
            if velocity.dy != 0 {
                for (edge, direction) in [(minY, CGFloat(-1)), (maxY, CGFloat(1))] {
                    let time = (edge - position.y) / velocity.dy
                    let x = position.x + velocity.dx * time
                    if x >= minX + radius - MrSmilesMotion.tolerance && x <= maxX - radius + MrSmilesMotion.tolerance {
                        consider(time, normal: CGVector(dx: 0, dy: direction))
                    }
                }
            }
            let speedSquared = velocity.dx * velocity.dx + velocity.dy * velocity.dy
            guard radius > 0, speedSquared > 0 else { return result }
            for horizontal in [CGFloat(-1), CGFloat(1)] {
                for vertical in [CGFloat(-1), CGFloat(1)] {
                    let center = CGPoint(
                        x: horizontal < 0 ? minX + radius : maxX - radius,
                        y: vertical < 0 ? minY + radius : maxY - radius,
                    )
                    let dx = position.x - center.x
                    let dy = position.y - center.y
                    let projection = dx * velocity.dx + dy * velocity.dy
                    let constant = dx * dx + dy * dy - radius * radius
                    let discriminant = projection * projection - speedSquared * constant
                    guard discriminant >= 0 else { continue }
                    let time = (-projection + sqrt(discriminant)) / speedSquared
                    let hitX = dx + velocity.dx * time
                    let hitY = dy + velocity.dy * time
                    if hitX * horizontal >= -MrSmilesMotion.tolerance && hitY * vertical >= -MrSmilesMotion.tolerance {
                        let length = hypot(hitX, hitY)
                        if length > 0 {
                            consider(time, normal: CGVector(dx: hitX / length, dy: hitY / length))
                        }
                    }
                }
            }
            return result
        }
    }

    private struct Random {
        var state: UInt64

        init(state: UInt64) {
            self.state = state
        }

        init(seed: UUID) {
            state = seed.uuidString.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
        }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
            value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
            return value ^ (value >> 31)
        }

        mutating func unit() -> Double {
            Double(next() >> 11) / 9_007_199_254_740_992
        }
    }
}
