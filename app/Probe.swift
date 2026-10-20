import SwiftUI

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
