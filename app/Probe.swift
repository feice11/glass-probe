import SwiftUI
import UIKit
import ObjectiveC

// 启动参数 -scene <名字> -glass <capsule|circle|tabbar|none>
// 背景都用纯色块画，像素可控，方便和安卓的结果逐像素比
@main
struct ProbeApp: App {
    var body: some Scene {
        WindowGroup { Root() }
    }
}

func arg(_ key: String, _ def: String) -> String {
    let a = ProcessInfo.processInfo.arguments
    if let i = a.firstIndex(of: "-" + key), i + 1 < a.count { return a[i + 1] }
    return def
}

struct Background: View {
    let scene: String
    var body: some View {
        Canvas { ctx, size in
            func fill(_ r: CGRect, _ c: Color) { ctx.fill(Path(r), with: .color(c)) }
            let w = size.width, h = size.height
            switch scene {
            case let g where g.hasPrefix("g") && Double(g.dropFirst()) != nil:
                fill(CGRect(origin: .zero, size: size), Color(.sRGB, white: Double(g.dropFirst())! / 100))
            case "black": fill(CGRect(origin: .zero, size: size), .black)
            case "white": fill(CGRect(origin: .zero, size: size), .white)
            case "gray": fill(CGRect(origin: .zero, size: size), Color(.sRGB, white: 0.5))
            case "red": fill(CGRect(origin: .zero, size: size), Color(.sRGB, red: 1, green: 0, blue: 0))
            case "green": fill(CGRect(origin: .zero, size: size), Color(.sRGB, red: 0, green: 1, blue: 0))
            case "blue": fill(CGRect(origin: .zero, size: size), Color(.sRGB, red: 0, green: 0, blue: 1))
            case "hstripes", "vstripes":
                // 8pt 黑白条纹
                let n = Int((scene == "hstripes" ? h : w) / 8) + 1
                for k in 0..<n {
                    let c: Color = k % 2 == 0 ? .black : .white
                    if scene == "hstripes" { fill(CGRect(x: 0, y: CGFloat(k) * 8, width: w, height: 8), c) }
                    else { fill(CGRect(x: CGFloat(k) * 8, y: 0, width: 8, height: h), c) }
                }
            case "checker":
                for y in stride(from: 0.0, to: h, by: 16) {
                    for x in stride(from: 0.0, to: w, by: 16) {
                        let odd = (Int(x / 16) + Int(y / 16)) % 2 == 1
                        fill(CGRect(x: x, y: y, width: 16, height: 16), odd ? .white : .black)
                    }
                }
            case "ramp":
                // 横向 0..255 灰阶
                for k in 0..<256 {
                    let v = Double(k) / 255
                    fill(CGRect(x: w * CGFloat(k) / 256, y: 0, width: w / 256 + 1, height: h), Color(.sRGB, white: v))
                }
            case "edge":
                // 左半白右半黑，再上半白下半黑叠成四象限
                for (r, c) in [(CGRect(x: 0, y: 0, width: w / 2, height: h / 2), Color.white),
                               (CGRect(x: w / 2, y: 0, width: w / 2, height: h / 2), Color.black),
                               (CGRect(x: 0, y: h / 2, width: w / 2, height: h / 2), Color.black),
                               (CGRect(x: w / 2, y: h / 2, width: w / 2, height: h / 2), Color.white)] { fill(r, c) }
            case "hues":
                let cs: [Color] = [.red, .orange, .yellow, .green, .mint, .cyan, .blue, .purple, .pink, .brown]
                for (k, c) in cs.enumerated() {
                    fill(CGRect(x: 0, y: h * CGFloat(k) / CGFloat(cs.count), width: w, height: h / CGFloat(cs.count) + 1), c)
                }
            default: fill(CGRect(origin: .zero, size: size), .gray)
            }
        }
        .ignoresSafeArea()
    }
}

struct Root: View {
    let scene = arg("scene", "gray")
    let glass = arg("glass", "capsule")
    var body: some View {
        content.onAppear {
            if arg("dump", "0") == "1" { DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { dumpAll() } }
            if arg("colors", "0") == "1" { dumpColors(); DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dumpButtons() } }
            if let sec = Double(arg("watch", "0")), sec > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { Watcher.shared.begin(seconds: sec) }
            }
        }
    }
    @ViewBuilder var content: some View {
        switch glass {
        case "edge", "edgehard":
            // iOS 26 的滚动边缘效果（scroll edge effect）：内容滚到中间，上面导航栏、下面工具栏都压着内容
            NavigationStack {
                ScrollView {
                    Background(scene: scene).frame(height: 3000)
                }
                .defaultScrollAnchor(.center)
                .scrollEdgeEffectStyle(glass == "edgehard" ? .hard : .soft, for: .all)
                .navigationTitle("Title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { Button("Edit") {} }
                    ToolbarItem(placement: .bottomBar) { Button("Action") {} }
                }
            }
        case "edgetab":
            TabView {
                ForEach(["house", "magnifyingglass", "bell", "person"], id: \.self) { s in
                    NavigationStack {
                        ScrollView { Background(scene: scene).frame(height: 3000) }
                            .defaultScrollAnchor(.center)
                            .navigationTitle("Title")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tabItem { Label(s, systemImage: s) }
                }
            }
        case "tabbar":
            TabView {
                ForEach(["house", "magnifyingglass", "bell", "person"], id: \.self) { s in
                    Background(scene: scene).tabItem { Label(s, systemImage: s) }
                }
            }
            .statusBarHidden()
        default:
            ZStack {
                Background(scene: scene)
                switch glass {
                case "capsule":
                    Color.clear.frame(width: 300, height: 62).glassEffect(.regular, in: .capsule)
                case "circle":
                    Color.clear.frame(width: 62, height: 62).glassEffect(.regular, in: .circle)
                case "clear":
                    Color.clear.frame(width: 300, height: 62).glassEffect(.clear, in: .capsule)
                default: EmptyView()
                }
            }
            .statusBarHidden()
        }
    }
}

// 调试：把自己窗口里的图层树和图层上挂的滤镜参数写到 Documents/dump.txt（和 Xcode 视图调试器看到的是同一份东西）
let inputKeys: [String] = ["inputAberrationAmount", "inputAberrationAngle", "inputAberrationHeight", "inputAberrationOffset", "inputAdaptive", "inputAddWhite", "inputAllowsGroup", "inputAlphaValues", "inputAmount", "inputAngle", "inputAspectRatio", "inputBackColor0", "inputBackColor1", "inputBackEnabled", "inputBackdropAware", "inputBias", "inputBleedAmount", "inputBleedBlurRadius", "inputBleedColorMatrixBlack", "inputBleedColorMatrixFillColor", "inputBleedColorMatrixSaturation", "inputBleedColorMatrixWhite", "inputBleedDarkenBlend", "inputBleedDistance0", "inputBleedDistance1", "inputBleedHeight", "inputBleedOffset", "inputBleedOpacity", "inputBleedSaturation", "inputBlueOffset", "inputBlueValues", "inputBlurDistance0", "inputBlurDistance1", "inputBlurDistance2", "inputBlurDistance3", "inputBlurDistance4", "inputBlurFillBlurRadius", "inputBlurFillDarkenOpacity", "inputBlurFillLightenOpacity", "inputBlurFillNormalOpacity", "inputBlurOpacity0", "inputBlurOpacity1", "inputBlurOpacity2", "inputBlurOpacity3", "inputBlurOpacity4", "inputBlurRadius", "inputBounds", "inputClamp", "inputClampPreserveHue", "inputColor", "inputColor0", "inputColor1", "inputColorMap", "inputColorMatrix", "inputDither", "inputEdgeEnd", "inputEdgeOpacityEnd", "inputEdgeOpacityStart", "inputEdgeStart", "inputEnd", "inputEndAngle", "inputExtendEdges", "inputFaceColorMatrixBlack", "inputFaceColorMatrixFillColor", "inputFaceColorMatrixMaxLuma", "inputFaceColorMatrixMaxLumaSDR", "inputFaceColorMatrixSaturation", "inputFaceColorMatrixWhite", "inputFaceOpacity", "inputFade", "inputFrontColor", "inputFrontEnabled", "inputGreenOffset", "inputGreenValues", "inputHSVSpace", "inputHardEdges", "inputInnerRefractionAmount", "inputInnerRefractionHeight", "inputIntermediateBitDepth", "inputKeyFillHighlightAmount", "inputKeyFillHighlightAngle", "inputKeyFillHighlightColorBias", "inputKeyFillHighlightEffectOffset", "inputKeyFillHighlightHeight", "inputKeyFillHighlightSpread", "inputKeyFillHighlightSpreadSDR", "inputLinear", "inputMaskImage", "inputMaxHeadroom", "inputNormalizeEdges", "inputOffset", "inputOuterRefractionAmount", "inputOuterRefractionHeight", "inputOverlayOpacity", "inputPremultipliedValues", "inputQuality", "inputRadius", "inputRedOffset", "inputRedValues", "inputRefractionAmount", "inputRefractionDistance0", "inputRefractionDistance1", "inputRefractionHeight", "inputRefractionOffset", "inputRefractionOpacity", "inputReversed", "inputRingShadowBlurRadius", "inputRingShadowMask", "inputRingShadowOffset", "inputRingShadowOpacity", "inputRingShadowStrokeWidth", "inputSDRGradientDistance0", "inputSDRGradientDistance1", "inputSDRHoldingToneEnabled", "inputSDRHoldingToneWhite", "inputSDRShadowOpacity", "inputScale", "inputShadowAmount", "inputShadowBlurRadius", "inputShadowBounds", "inputShadowColor", "inputShadowColorMatrixBlack", "inputShadowColorMatrixFillColor", "inputShadowColorMatrixSaturation", "inputShadowColorMatrixWhite", "inputShadowDistanceOffset", "inputShadowHeight", "inputShadowOffset", "inputShadowOpacity", "inputShadowRadius", "inputShadowVibrancyContribution", "inputSourceSublayerName", "inputStart", "inputStartAngle", "inputTime", "inputValues"]

func props(_ obj: NSObject, stopAt: AnyClass) -> [String] {
    var out: [String] = []
    var c: AnyClass? = type(of: obj)
    while let cls = c, cls != stopAt {
        var n: UInt32 = 0
        if let list = class_copyPropertyList(cls, &n) {
            for i in 0..<Int(n) {
                let name = String(cString: property_getName(list[i]))
                let attrs = property_getAttributes(list[i]).map { String(cString: $0) } ?? ""
                var getter = name
                if let g = attrs.split(separator: ",").first(where: { $0.hasPrefix("G") }) { getter = String(g.dropFirst()) }
                if !obj.responds(to: Selector(getter)) { continue }
                if attrs.hasPrefix("T^") || attrs.hasPrefix("T?") || attrs.hasPrefix("T*") { continue }
                if ["description", "debugDescription", "hash", "superclass", "statistics"].contains(name) { continue }
                if let v = obj.value(forKey: name) {
                    if let e = v as? NSObject, "\(type(of: e))".hasPrefix("CASDF") {
                        out.append("\(name)=\(type(of: e)) {" + props(e, stopAt: NSObject.self).joined(separator: ", ") + "}")
                    } else {
                        out.append("\(name)=\(show(v))")
                    }
                }
            }
            free(list)
        }
        c = class_getSuperclass(cls)
    }
    return out
}

var imageCount = 0
func saveImage(_ img: CGImage, _ tag: String) -> String {
    imageCount += 1
    let name = "img\(imageCount)_\(tag)_\(img.width)x\(img.height).png"
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
    try? UIImage(cgImage: img).pngData()?.write(to: url)
    return name
}

func describeFilter(_ f: Any) -> String {
    guard let o = f as? NSObject, "\(type(of: o))".contains("Filter") else { return "\(type(of: f)) \(f)" }
    var parts = ["\(type(of: o)) name=\(o.value(forKey: "name") ?? "-") type=\(o.value(forKey: "type") ?? "-")"]
    for k in inputKeys {
        guard let v = o.value(forKey: k) else { continue }
        if CFGetTypeID(v as CFTypeRef) == CGImage.typeID { parts.append("\(k)=" + saveImage(v as! CGImage, k)); continue }
        parts.append("\(k)=\(show(v))")
    }
    return parts.joined(separator: " | ")
}

func dumpLayer(_ l: CALayer, _ depth: Int, _ out: inout String) {
    let pad = String(repeating: "  ", count: depth)
    out += "\(pad)\(type(of: l)) frame=\(l.frame) corner=\(l.cornerRadius) opacity=\(l.opacity)\n"
    let cls = "\(type(of: l))"
    let interesting = ["SDF", "Backdrop", "Glass", "Portal", "Pocket", "Edge", "Blur", "Variable", "Gradient"].contains { cls.contains($0) }
    if interesting { for p in props(l, stopAt: CALayer.self) { out += "\(pad)  . \(p)\n" } }
    if l.isHidden { out += "\(pad)  . HIDDEN\n" }
    if l.shadowOpacity > 0 || "\(type(of: l))".contains("Shadow") {
        out += "\(pad)  . shadow opacity=\(l.shadowOpacity) radius=\(l.shadowRadius) offset=\(l.shadowOffset) color=" + (l.shadowColor.map { show($0) } ?? "nil")
        out += " path=" + (l.shadowPath.map { "\($0.boundingBox)" } ?? "nil") + " bounds=\(l.bounds) masksToBounds=\(l.masksToBounds) compositing=" + (l.compositingFilter.map { "\($0)" } ?? "nil") + "\n"
        for p in props(l, stopAt: CALayer.self) { out += "\(pad)  . \(p)\n" }
    }
    if let p = l.presentation(), let fs = p.filters, !fs.isEmpty, l.animationKeys()?.isEmpty == false {
        for f in fs { out += "\(pad)  presentation filter: \(describeFilter(f))\n" }
    }
    if let keys = l.animationKeys(), !keys.isEmpty { out += "\(pad)  . anims=\(keys)\n" }
    if let g = l as? CAGradientLayer {
        out += "\(pad)  . gradient type=\(g.type.rawValue) start=\(g.startPoint) end=\(g.endPoint) locations=\(g.locations ?? []) colors=" + (g.colors ?? []).map { show($0) }.joined(separator: " ") + "\n"
    }
    if let bg = l.backgroundColor { out += "\(pad)  . bg=" + show(bg) + " compositing=" + (l.compositingFilter.map { "\($0)" } ?? "nil") + "\n" }
    if !CATransform3DIsIdentity(l.transform) { out += "\(pad)  . transform=" + show(NSValue(caTransform3D: l.transform)) + "\n" }
    if let c = l.contents, CFGetTypeID(c as CFTypeRef) == CGImage.typeID {
        out += "\(pad)  . contents=" + saveImage(c as! CGImage, "contents") + " gravity=\(l.contentsGravity.rawValue) scale=\(l.contentsScale)\n"
    }
    if let m = l.mask {
        out += "\(pad)  . mask=\(type(of: m)) frame=\(m.frame)\n"
        dumpLayer(m, depth + 2, &out)
    }
    for f in l.filters ?? [] { out += "\(pad)  filter: \(describeFilter(f))\n" }
    for f in l.backgroundFilters ?? [] { out += "\(pad)  bgfilter: \(describeFilter(f))\n" }
    if let f = l.compositingFilter { out += "\(pad)  compositing: \(describeFilter(f))\n" }
    for s in l.sublayers ?? [] { dumpLayer(s, depth + 1, &out) }
}

func dumpAll() {
    var out = ""
    for scene in UIApplication.shared.connectedScenes {
        guard let ws = scene as? UIWindowScene else { continue }
        for w in ws.windows { dumpLayer(w.layer, 0, &out) }
    }
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("dump.txt")
    try? out.write(to: url, atomically: true, encoding: .utf8)
}

func show(_ v: Any) -> String {
    if let nv = v as? NSValue, !(v is NSNumber) {
        var size = 0
        NSGetSizeAndAlignment(nv.objCType, &size, nil)
        if size == 128 {
            var d = [Double](repeating: 0, count: 16)
            nv.getValue(&d, size: 128)
            return "m4[" + d.map { String(format: "%.6f", $0) }.joined(separator: ",") + "]"
        }
        if size == 80 {
            var f = [Float](repeating: 0, count: 20)
            nv.getValue(&f, size: 80)
            return "floats[" + f.map { String(format: "%.6f", $0) }.joined(separator: ",") + "]"
        }
    }
    if let d = v as? Data { return "data[" + d.map { String(format: "%02x", $0) }.joined() + "]" }
    if CFGetTypeID(v as CFTypeRef) == CGColor.typeID {
        let c = v as! CGColor
        return "color(" + (c.components ?? []).map { String(format: "%.6f", $0) }.joined(separator: ",") + ")"
    }
    return "\(v)"
}


// 按压逆向：逐帧记录屏幕底部（y > 780pt）图层的 presentation 状态（只记变化），以及新挂上的 CAAnimation 的全部属性。
// 写到 Documents/anim.txt。时间是相对开始记录的秒数
final class Watcher: NSObject {
    static let shared = Watcher()
    var link: CADisplayLink?
    var start: CFTimeInterval = 0
    var seconds = 0.0
    var last: [String: String] = [:]
    var seen = Set<String>()
    var savedContents = Set<String>()
    var out = ""

    func begin(seconds: Double) {
        self.seconds = seconds
        start = CACurrentMediaTime()
        out += "BEGIN media=\(start)\n"
        link = CADisplayLink(target: self, selector: #selector(tick))
        link?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link?.add(to: .main, forMode: .common)
    }

    @objc func tick() {
        let t = CACurrentMediaTime() - start
        var lines: [String] = []
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for (wi, w) in ws.windows.enumerated() { walk(w.layer, "w\(wi)", w.layer, &lines) }
        }
        if !lines.isEmpty { out += String(format: "T %.4f\n", t) + lines.joined(separator: "\n") + "\n" }
        if t > seconds {
            link?.invalidate()
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("anim.txt")
            try? out.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    func walk(_ l: CALayer, _ path: String, _ root: CALayer, _ lines: inout [String]) {
        let r = l.convert(l.bounds, to: root)
        if r.maxY > 780 || r.height > 900 {
            let p = l.presentation() ?? l
            if r.maxY > 780 && r.height < 900 {
                var st = "\(type(of: l)) pos=\(p.position) bounds=\(p.bounds) anchor=\(p.anchorPoint) win=\(r) op=\(p.opacity) corner=\(p.cornerRadius) hidden=\(p.isHidden)"
                if !CATransform3DIsIdentity(p.transform) { st += " transform=\(show(NSValue(caTransform3D: p.transform)))" }
                if !CATransform3DIsIdentity(p.sublayerTransform) { st += " subT=\(show(NSValue(caTransform3D: p.sublayerTransform)))" }
                for f in p.filters ?? [] { st += " || filter: " + describeFilter(f) }
                for f in p.backgroundFilters ?? [] { st += " || bg: " + describeFilter(f) }
                if abs(p.bounds.width - 93) < 0.5 && abs(p.bounds.height - 93) < 0.5 {
                    // 光斑：背景色、圆角、遮罩、合成方式、阴影都记下
                    st += " || glow: bg=" + (p.backgroundColor.map { show($0) } ?? "nil") + " cornerCurve=" + p.cornerCurve.rawValue
                    st += " masksToBounds=" + String(p.masksToBounds) + " compositing=" + (p.compositingFilter.map { describeFilter($0) } ?? "nil")
                    st += " shadow=" + String(p.shadowOpacity) + "/" + String(describing: p.shadowRadius) + " mask=" + (p.mask.map { String(describing: type(of: $0)) + " " + String(describing: $0.bounds) + " contents=" + String(describing: $0.contents != nil) } ?? "nil")
                    st += " props: " + props(p, stopAt: NSObject.self).joined(separator: ", ")
                    if let m = p.mask, let c = m.contents, CFGetTypeID(c as CFTypeRef) == CGImage.typeID, !savedContents.contains(path + "mask") {
                        savedContents.insert(path + "mask")
                        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("contents_glowmask.png")
                        try? UIImage(cgImage: c as! CGImage).pngData()?.write(to: url)
                    }
                }
                let cls = "\(type(of: l))"
                if ["SDF", "Portal", "Backdrop"].contains(where: { cls.contains($0) }) {
                    st += " || props: " + props(p, stopAt: CALayer.self).joined(separator: ", ")
                }
                if last[path] != st { lines.append("\(path) \(st)"); last[path] = st }
                // 图层自带的贴图（光斑这类）存一份 PNG
                if let c = p.contents, CFGetTypeID(c as CFTypeRef) == CGImage.typeID, !savedContents.contains(path) {
                    savedContents.insert(path)
                    let img = UIImage(cgImage: c as! CGImage)
                    let name = "contents_" + path.replacingOccurrences(of: "/", with: "_") + ".png"
                    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
                    try? img.pngData()?.write(to: url)
                    lines.append("CONTENTS \(path) \(name) \(c as! CGImage).width x \((c as! CGImage).height) gravity=\(p.contentsGravity.rawValue) scale=\(p.contentsScale)")
                }
            }
            for key in l.animationKeys() ?? [] {
                guard let a = l.animation(forKey: key) else { continue }
                let id = "\(path)#\(key)#\(a.beginTime)"
                if seen.contains(id) { continue }
                seen.insert(id)
                lines.append("ANIM \(path) \(type(of: l)) key=\(key) " + describeAnim(a))
            }
        }
        for (i, s) in (l.sublayers ?? []).enumerated() { walk(s, path + "/\(i)", root, &lines) }
    }
}

func describeAnim(_ a: CAAnimation) -> String {
    var parts = ["\(type(of: a))"]
    parts += props(a, stopAt: NSObject.self)
    if let tf = a.timingFunction {
        var c1: [Float] = [0, 0], c2: [Float] = [0, 0]
        tf.getControlPoint(at: 1, values: &c1)
        tf.getControlPoint(at: 2, values: &c2)
        parts.append("timing=(\(c1[0]),\(c1[1]),\(c2[0]),\(c2[1]))")
    }
    if let g = a as? CAAnimationGroup {
        for (i, s) in (g.animations ?? []).enumerated() { parts.append("[sub\(i): " + describeAnim(s) + "]") }
    }
    return parts.joined(separator: " ; ")
}

// 读系统语义色：浅色 / 深色 × 普通 / 高对比 × 基础 / 抬升层级，各解析成 extended sRGB 分量，写到 Documents/colors.txt
func dumpColors() {
    let named: [(String, UIColor)] = [
        ("systemRed", .systemRed), ("systemOrange", .systemOrange), ("systemYellow", .systemYellow), ("systemGreen", .systemGreen),
        ("systemMint", .systemMint), ("systemTeal", .systemTeal), ("systemCyan", .systemCyan), ("systemBlue", .systemBlue),
        ("systemIndigo", .systemIndigo), ("systemPurple", .systemPurple), ("systemPink", .systemPink), ("systemBrown", .systemBrown),
        ("systemGray", .systemGray), ("systemGray2", .systemGray2), ("systemGray3", .systemGray3), ("systemGray4", .systemGray4),
        ("systemGray5", .systemGray5), ("systemGray6", .systemGray6), ("tintColor", .tintColor),
        ("label", .label), ("secondaryLabel", .secondaryLabel), ("tertiaryLabel", .tertiaryLabel), ("quaternaryLabel", .quaternaryLabel),
        ("placeholderText", .placeholderText), ("link", .link), ("separator", .separator), ("opaqueSeparator", .opaqueSeparator),
        ("systemBackground", .systemBackground), ("secondarySystemBackground", .secondarySystemBackground),
        ("tertiarySystemBackground", .tertiarySystemBackground), ("systemGroupedBackground", .systemGroupedBackground),
        ("secondarySystemGroupedBackground", .secondarySystemGroupedBackground),
        ("tertiarySystemGroupedBackground", .tertiarySystemGroupedBackground),
        ("systemFill", .systemFill), ("secondarySystemFill", .secondarySystemFill), ("tertiarySystemFill", .tertiarySystemFill),
        ("quaternarySystemFill", .quaternarySystemFill), ("lightText", .lightText), ("darkText", .darkText),
    ]
    func comps(_ c: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        let cs = (c.cgColor.colorSpace?.name as String?) ?? "?"
        let raw = (c.cgColor.components ?? []).map { String(format: "%.6f", $0) }.joined(separator: ",")
        return String(format: "%.6f %.6f %.6f %.6f", r, g, b, a) + " " + cs + " [" + raw + "]"
    }
    var out = ""
    for style in [UIUserInterfaceStyle.light, .dark] {
        for contrast in [UIAccessibilityContrast.normal, .high] {
            for level in [UIUserInterfaceLevel.base, .elevated] {
                let tc = UITraitCollection(traitsFrom: [
                    UITraitCollection(userInterfaceStyle: style),
                    UITraitCollection(accessibilityContrast: contrast),
                    UITraitCollection(userInterfaceLevel: level),
                ])
                let key = "\(style == .dark ? "dark" : "light") \(contrast == .high ? "high" : "normal") \(level == .elevated ? "elevated" : "base")"
                for (n, c) in named { out += "\(key) \(n) \(comps(c.resolvedColor(with: tc)))\n" }
                tc.performAsCurrent {
                    let configs: [(String, UIButton.Configuration)] = [
                        ("filled", .filled()), ("tinted", .tinted()), ("gray", .gray()), ("plain", .plain()),
                        ("borderedProminent", .borderedProminent()), ("bordered", .bordered()), ("borderedTinted", .borderedTinted()),
                    ]
                    for (n, cfg) in configs {
                        let bg = cfg.background.resolvedBackgroundColor(for: .systemBlue).resolvedColor(with: tc)
                        out += "\(key) button.\(n).background \(comps(bg))\n"
                        if let fg = cfg.baseForegroundColor { out += "\(key) button.\(n).foreground \(comps(fg.resolvedColor(with: tc)))\n" }
                    }
                }
            }
        }
    }
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("colors.txt")
    try? out.write(to: url, atomically: true, encoding: .utf8)
}

// 把各种配置的按钮真的放进窗口布局一遍，读它的底色视图（tinted / gray / filled 这些在 iOS 26 的真实底色）
func dumpButtons() {
    guard let win = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.windows.first }).first else { return }
    var out = ""
    for style in [UIUserInterfaceStyle.light, .dark] {
        win.overrideUserInterfaceStyle = style
        let configs: [(String, UIButton.Configuration)] = [
            ("filled", .filled()), ("tinted", .tinted()), ("gray", .gray()), ("plain", .plain()),
            ("borderedProminent", .borderedProminent()), ("bordered", .bordered()), ("borderedTinted", .borderedTinted()),
        ]
        for (n, cfg) in configs {
            var c = cfg
            c.title = "Button"
            let b = UIButton(configuration: c)
            b.frame = CGRect(x: 20, y: 200, width: 200, height: 50)
            win.addSubview(b)
            b.layoutIfNeeded()
            CATransaction.flush()
            func walk(_ v: UIView, _ d: Int) {
                let bg = v.backgroundColor.map { col -> String in
                    var r: CGFloat = 0, g: CGFloat = 0, bl: CGFloat = 0, a: CGFloat = 0
                    col.resolvedColor(with: win.traitCollection).getRed(&r, green: &g, blue: &bl, alpha: &a)
                    return String(format: "%.6f %.6f %.6f %.6f", r, g, bl, a)
                } ?? "-"
                var lb = "-"
                if let cg = v.layer.backgroundColor, let comps = cg.components { lb = comps.map { String(format: "%.6f", $0) }.joined(separator: ",") + " " + ((cg.colorSpace?.name as String?) ?? "") }
                let tc = (v as? UILabel).map { l -> String in
                    var r: CGFloat = 0, g: CGFloat = 0, bl: CGFloat = 0, a: CGFloat = 0
                    l.textColor.resolvedColor(with: win.traitCollection).getRed(&r, green: &g, blue: &bl, alpha: &a)
                    return String(format: " text=%.6f %.6f %.6f %.6f", r, g, bl, a)
                } ?? ""
                out += "\(style == .dark ? "dark" : "light") \(n) \(String(repeating: " ", count: d))\(type(of: v)) bg=\(bg) layer=\(lb) frame=\(v.frame)\(tc)\n"
                for s in v.subviews { walk(s, d + 1) }
            }
            walk(b, 0)
            b.removeFromSuperview()
        }
    }
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("buttons.txt")
    try? out.write(to: url, atomically: true, encoding: .utf8)
}
