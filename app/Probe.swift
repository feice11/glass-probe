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
            if arg("dump", "0") == "1" { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { dumpAll() } }
        }
    }
    @ViewBuilder var content: some View {
        switch glass {
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

func describeFilter(_ f: Any) -> String {
    guard let o = f as? NSObject else { return "\(f)" }
    var parts = ["\(type(of: o)) name=\(o.value(forKey: "name") ?? "-")"]
    for k in inputKeys { if let v = o.value(forKey: k) { parts.append("\(k)=\(show(v))") } }
    return parts.joined(separator: " | ")
}

func dumpLayer(_ l: CALayer, _ depth: Int, _ out: inout String) {
    let pad = String(repeating: "  ", count: depth)
    out += "\(pad)\(type(of: l)) frame=\(l.frame) corner=\(l.cornerRadius) opacity=\(l.opacity)\n"
    let cls = "\(type(of: l))"
    let interesting = ["SDF", "Backdrop", "Glass", "Portal"].contains { cls.contains($0) }
    if interesting { for p in props(l, stopAt: CALayer.self) { out += "\(pad)  . \(p)\n" } }
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
