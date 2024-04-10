//
//  ContentView.swift
//  Pixboard
//
//  Created by apple on 2023/8/23.
//

import SwiftUI
import FileHash
import SDWebImageSwiftUI
import UniformTypeIdentifiers
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

extension View {
   @ViewBuilder
   func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
   }
}

extension String {
    var boolValue: Bool { return (self as NSString).boolValue }
}

extension Data {
    var md5: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = self
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}

class AuthStore {
    var window: NSWindow
    init(window: NSWindow) { self.window = window }
}

extension View {
    /// Adds a double click handler this view (macOS only)
    ///
    /// Example
    /// ```
    /// Text("Hello")
    ///     .onDoubleClick { print("Double click detected") }
    /// ```
    /// - Parameters:
    ///   - handler: Block invoked when a double click is detected
    func onDoubleClick(handler: @escaping () -> Void) -> some View {
        modifier(DoubleClickHandler(handler: handler))
    }
}

struct DoubleClickHandler: ViewModifier {
    let handler: () -> Void
    func body(content: Content) -> some View {
        content.overlay {
            DoubleClickListeningViewRepresentable(handler: handler)
        }
    }
}

struct DoubleClickListeningViewRepresentable: NSViewRepresentable {
    let handler: () -> Void
    func makeNSView(context: Context) -> DoubleClickListeningView {
        DoubleClickListeningView(handler: handler)
    }
    func updateNSView(_ nsView: DoubleClickListeningView, context: Context) {}
}

class DoubleClickListeningView: NSView {
    let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount == 2 {
            handler()
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { self.window = view.window }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct ContentView: View {
    var mainWindow = false
    @State private var window: NSWindow?
    
    @Environment(\.colorScheme) var colorScheme
    @State private var scale = 1.0
    @State private var offsetX = 0.0
    @State private var offsetY = 0.0
    @State private var rotation = 0.0
    @State private var resize_lock = false
    @State private var showAlert = false
    @State private var invert = false
    @State private var HDR = UserDefaults.standard.bool(forKey: "HDR")
    @State private var mode = UserDefaults.standard.string(forKey: "mode") ?? "LED"
    @State private var subMode = UserDefaults.standard.string(forKey: "subMode") ?? ""
    @State private var nearest = (UserDefaults.standard.object(forKey: "nearest") ?? true) as! Bool
    @State private var imageURL = URL(fileURLWithPath: Bundle.main.resourcePath! + "/welcome.png")
    @State private var imageURL_bak = URL(fileURLWithPath: Bundle.main.resourcePath! + "/welcome.png")
    @State private var hash = [String]()
    @State private var size: CGSize = .zero
    
    let tempPath = NSTemporaryDirectory() + "/com.lihaoyun6.Pixboard/"
    private let gifsicle = Bundle.main.resourcePath! + "/gifsicle"
    private let about = URL(fileURLWithPath: Bundle.main.resourcePath! + "/about.png")
    private let welcome = URL(fileURLWithPath: Bundle.main.resourcePath! + "/welcome.png")
    private let loading = URL(fileURLWithPath: Bundle.main.resourcePath! + "/loading.gif")
    
    //let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    func saveGIF(url: URL, img: CIImage) -> URL {
        let destinationGIF = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destinationGIF, CIContext(options: nil).createCGImage(img, from: img.extent)!, nil)
        CGImageDestinationFinalize(destinationGIF)
        return url
    }
    
    func pngData(_ image: NSImage) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let imageRep = NSBitmapImageRep(cgImage: cgImage)
        imageRep.size = image.size // display size in points
        return imageRep.representation(using: .png, properties: [:])
    }
    
    func api(_ url: URL) {
        let opt = url.host()
        if !["mode", "resize", "rotate", "ontop", "hdr", "invert", "clear_cache", "image_data", "image_file"].contains(opt?.lowercased()) { return }
        let value = url.query()
        if opt == "clear_cache" {
            PixboardApp().appDelegate.clearCache()
            hash.removeAll()
        }
        if opt == "mode", ["LED", "LED_CIRCLE", "CRT", "CRT_GREEN", "CRT_AMBER", "CRT_MONO", "LCD", "LCD_BLUE", "VFD", "VFD_YELLOW"].contains(value?.uppercased()) {
            let values = value?.components(separatedBy: "_")
            mode = values?.first!.uppercased() ?? "LED"
            subMode = (values?.count == 2) ? values!.last!.lowercased() : ""
            UserDefaults.standard.set(mode, forKey: "mode")
            UserDefaults.standard.set(subMode, forKey: "subMode")
        }
        if opt == "resize", ["nearest", "normal"].contains(value?.uppercased()) {
            nearest = (value?.uppercased() == "nearest") ? true : false
            UserDefaults.standard.set(nearest, forKey: "nearest")
        }
        if opt == "rotate", ["0", "90", "180", "270"].contains(value?.uppercased()) {
            guard let angle = Double(value!) else { return }
            rotation = angle
        }
        if opt == "hdr", ["1", "0"].contains(value?.uppercased()) {
            HDR = (value ?? "0").boolValue
            UserDefaults.standard.set(HDR, forKey: "HDR")
        }
        if opt == "invert", ["1", "0"].contains(value?.uppercased()) {
            invert = (value ?? "0").boolValue
            UserDefaults.standard.set(invert, forKey: "invert")
        }
        if opt == "ontop", ["1", "0"].contains(value?.uppercased()) {
            let onTop = (value ?? "1").boolValue
            let windows = NSApplication.shared.windows
            for w in windows { if onTop { w.level = .floating } else { w.level = .normal } }
        }
        if opt == "image_file" {
            guard let path = value!.removingPercentEncoding else { return }
            resize(url: URL(filePath: path))
        }
        if opt == "image_data" {
            guard let data = Data(base64Encoded: value!) else { return }
            guard let image = NSImage(data: data) else { return }
            resize(data: image)
        }
    }
    
    func setOffset(_ url: URL) {
        guard let img = CIImage(contentsOf: url) else { return }

        if Int(min(img.extent.size.width, img.extent.size.height))/5 % 2 != 0 {
            let land = img.extent.size.width > img.extent.size.height
            offsetX = !land ? -2.3 : 0.0
            offsetY = land ? -2.3 : 0.0
        }
    }
    
    func resize(url: URL? = nil, data: NSImage? = nil) {
        if resize_lock { return }
        resize_lock = true
        
        var imgID = UUID().uuidString
        var img: CIImage
        var u = url
        offsetX = 0.0
        offsetY = 0.0
        
        if let data = data {
            img = CIImage(cgImage: data.cgImage!)
            imgID = pngData(data)!.md5
            if hash.contains(imgID) { return }
            u = saveGIF(url: URL(filePath: tempPath + "temp.g"), img: img)
        }else{
            guard let t = CIImage(contentsOf: url!) else { resize_lock = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { imageURL = imageURL_bak; setOffset(imageURL) }; return }
            imgID = Hasher.md5HashOfFile(atPath: url!.path)!
            if url!.pathExtension.lowercased() != "gif", !hash.contains(imgID) { u = saveGIF(url: URL(filePath: tempPath + "temp.g"), img: t) }
            img = t
        }
        
        
        if !hash.contains(imgID) {
            hash.append(imgID)
            
            let task = Process()
            task.arguments = ["-c", "'\(gifsicle)' --resize-method sample --resize\(img.extent.size.width > img.extent.size.height ? "width" : "height") 64 --colors 256 '\(u!.path)' 2>/dev/null|'\(gifsicle)' --scale 5 --resize-method sample -o '\(tempPath + imgID + ".gif.nearest.gif")' 2>/dev/null;'\(gifsicle)'  --resize\(img.extent.size.width > img.extent.size.height ? "width" : "height") 64 --colors 256 '\(u!.path)' 2>/dev/null|'\(gifsicle)' --scale 5 --resize-method sample -o '\(tempPath + imgID + ".gif")' 2>/dev/null"]
            task.launchPath = "/bin/bash"
            task.launch()
            task.waitUntilExit()
        } else { usleep(20000) }
        
        imageURL = URL(filePath: tempPath + imgID + (nearest ? ".gif.nearest.gif" : ".gif"))
        imageURL_bak = imageURL
        setOffset(URL(filePath: tempPath + imgID + (nearest ? ".gif.nearest.gif" : ".gif")))
        
        resize_lock = false
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("board_\(mode)")
                Group {
                    if mode.contains("LED") {
                        Color.white .frame(width: 320, height: 320, alignment: .center) .opacity(colorScheme == .dark ? 0.03: 0.08) .opacity(HDR ? 0.6 : 1.0)
                        WebImage(url: imageURL) .if(invert){$0.colorInvert()} .blendMode(.lighten) .offset(x: offsetX, y: offsetY)
                        Image("mask_\(mode)_\(subMode)")
                        WebImage(url: imageURL) .frame(width: 320, height: 320, alignment: .center) .if(invert){$0.colorInvert()} .saturation(1.6) .opacity(HDR ? 0.0 : 0.3) .blur(radius: 4.0) .blendMode(.plusLighter) .clipped() .offset(x: offsetX, y: offsetY)
                    }
                    if mode == "CRT" {
                        Color.black .frame(width: 320, height: 320, alignment: .center)
                        WebImage(url: imageURL) .if(invert){$0.colorInvert()} .saturation(subMode == "" ? 1.0 : 0.0) .blur(radius: 1.2) .blendMode(.normal) .clipped() .offset(x: offsetX, y: offsetY)
                        Image("mask_CRT_sub") .opacity(0.4) .saturation(subMode == "" ? 1.0 : 0.0) .blendMode(.hardLight) .offset(x: offsetX, y: offsetY)
                        Image("mask_\(mode)")
                        WebImage(url: imageURL) .if(invert){$0.colorInvert()} .frame(width: 320, height: 320, alignment: .center) .opacity(HDR ? 0.0 : 0.2) .saturation(subMode == "" ? 1.4 : 0.0) .blur(radius: 1.2) .blendMode(.plusLighter) .clipped() .offset(x: offsetX, y: offsetY)
                        Color("color_CRT_\(subMode)") .frame(width: 320, height: 320, alignment: .center) .blendMode(.multiply)
                    }
                    if mode == "LCD" {
                        Color("bottom_\(mode)_\(subMode)") .frame(width: 320, height: 320, alignment: .center)
                        WebImage(url: imageURL) .if(invert){$0.colorInvert()} .saturation(0.0) .blendMode(subMode=="" ? .multiply : .lighten) .offset(x: offsetX, y: offsetY)
                        Image("mask_\(mode)_\(subMode)")
                    }
                    if mode == "VFD" {
                        Color.black .frame(width: 321, height: 321, alignment: .center)
                        Color.white .frame(width: 320, height: 320, alignment: .center) .opacity(colorScheme == .dark ? 0.1: 0.16) .opacity(HDR ? 0.7 : 1.0)
                        WebImage(url: imageURL) .if(invert){$0.colorInvert()} .saturation(0.0) .blendMode(.lighten) .offset(x: offsetX, y: offsetY)
                        WebImage(url: imageURL) .if(invert){$0.colorInvert()} .frame(width: 320, height: 320, alignment: .center) .opacity(HDR ? 0.0 : 0.32) .saturation(0.0) .blendMode(.multiply) .clipped() .offset(x: offsetX, y: offsetY)
                        Image("mask_\(mode)")
                        Color("color_VFD_\(subMode)") .frame(width: 320, height: 320, alignment: .center) .blendMode(.multiply)
                        
                    }
                }
                .rotationEffect(Angle(degrees: rotation))
                Group {
                    Rectangle() .frame(width: 320, height: 320, alignment: .center) .opacity(HDR ? 1.0 : 0.0) .brightness(colorScheme == .dark ? 0.6: 1.68) .blendMode(.multiply)
                    Image("cover_\(mode)")
                }
            }
            .dropDestination(for: URL.self) { (items, _) in
                if items.count > 0 {
                    rotation = 0.0
                    imageURL = loading
                    Thread.detachNewThread { resize(url:items.first!) }
                }
                return true
            }
            .onOpenURL { (url) in
                api(url)
            }
            .onDoubleClick { window!.toggleFullScreen(nil) }
            .contextMenu {
                Button(
                    action: {
                        NSApplication.shared.setActivationPolicy(.accessory)
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [.gif, .jpeg, .png, .bmp, .webP, .tiff, .heic, .heif]
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK {
                            rotation = 0.0
                            resize(url:loading)
                            let u = panel.url!
                            Thread.detachNewThread { resize(url:u) }
                        }
                        NSApplication.shared.setActivationPolicy(.prohibited)
                    },
                    label: {Text("Open..."); Image(systemName: "photo.on.rectangle.angled")}
                )
                Button(
                    action: {
                        rotation += 90
                        rotation = (rotation == 360) ? 0.0 : rotation
                    },
                    label: {Text("Rotate View"); Image(systemName: "rotate.right")}
                )
                Menu {
                    Menu {
                        Button ( action:{ mode = "LED"
                            subMode = ""
                            UserDefaults.standard.set(mode, forKey: "mode")
                            UserDefaults.standard.set(subMode, forKey: "subMode") }, label:{ Text("Square LED"); Image(systemName: "square.grid.3x3.fill") })
                        Button ( action:{ mode = "LED"
                            subMode = "circle"
                            UserDefaults.standard.set(mode, forKey: "mode")
                            UserDefaults.standard.set(subMode, forKey: "subMode") }, label:{ Text("Circle LED"); Image(systemName: "circle.grid.3x3.fill") })
                    } label: { Text("LED Matrix"); Image(systemName: "square.grid.4x3.fill") }
                    Menu {
                        Button ( action:{ mode = "VFD"; subMode = ""
                            UserDefaults.standard.set(mode, forKey: "mode")
                            UserDefaults.standard.set(subMode, forKey: "subMode") }, label:{ Text("Cyan VFD"); Image(systemName: "checkerboard.rectangle") })
                        Button ( action:{ mode = "VFD"; subMode = "yellow"
                            UserDefaults.standard.set(mode, forKey: "mode")
                            UserDefaults.standard.set(subMode, forKey: "subMode") }, label:{ Text("Yellow VFD"); Image(systemName: "checkerboard.rectangle") })
                    } label: { Text("VFD Display"); Image(systemName: "checkerboard.rectangle") }
                    Menu {
                        Button ( action:{ mode = "CRT"; subMode = ""
                            UserDefaults.standard.set(mode, forKey: "mode")
                            UserDefaults.standard.set(subMode, forKey: "subMode") }, label:{ Text("Color CRT"); Image(systemName: "sparkles.tv") })
                        Button ( action:{ mode = "CRT"; subMode = "mono"
                            UserDefaults.standard.set(mode, forKey: "mode")
                            UserDefaults.standard.set(subMode, forKey: "subMode") }, label:{ Text("Mono CRT"); Image(systemName: "tv.inset.filled") })
                        Button ( action:{ mode = "CRT"; subMode = "green"
                            UserDefaults.standard.set(mode, forKey: "mode")
                            UserDefaults.standard.set(subMode, forKey: "subMode") }, label:{ Text("Green CRT"); Image(systemName: "tv") })
                        Button ( action:{ mode = "CRT"; subMode = "amber"
                            UserDefaults.standard.set(mode, forKey: "mode")
                            UserDefaults.standard.set(subMode, forKey: "subMode") }, label:{ Text("Amber CRT"); Image(systemName: "tv") })
                    } label: { Text("CRT Monitor"); Image(systemName: "photo.tv") }
                    Menu {
                        Button ( action:{ mode = "LCD"
                            subMode = ""
                            UserDefaults.standard.set(mode, forKey: "mode")
                            UserDefaults.standard.set(subMode, forKey: "subMode") }, label:{ Text("GameBoy"); Image(systemName: "lightswitch.on") })
                        Button ( action:{ mode = "LCD"
                            subMode = "blue"
                            UserDefaults.standard.set(mode, forKey: "mode")
                            UserDefaults.standard.set(subMode, forKey: "subMode") }, label:{ Text("Blue LCD"); Image(systemName: "rectangle.split.3x3.fill") })
                    } label: { Text("Mono LCD"); Image(systemName: "rectangle.split.3x3") }
                    
                    Divider()
                    Button (
                        action:{
                            let EDR = (window?.screen!.maximumPotentialExtendedDynamicRangeColorComponentValue ?? 1.0) > 1.0
                            if(!EDR && !HDR) {
                                showAlert=true
                                //DispatchQueue.main.asyncAfter(deadline: .now() + 6) { self.showAlert = false }
                            }
                            HDR.toggle()
                            UserDefaults.standard.set(HDR, forKey: "HDR")
                        },
                        label:{ Text(HDR ? "SDR Mode" : "HDR Mode"); Image(systemName: HDR ? "sun.max.fill" : "sun.max") })
                    Button (
                        action:{
                            nearest.toggle()
                            UserDefaults.standard.set(nearest, forKey: "nearest")
                            if imageURL != welcome {
                                imageURL = URL(filePath: imageURL.path.replacingOccurrences(of: ".gif", with: "").replacingOccurrences(of: ".nearest", with: "") + (nearest ? ".gif.nearest.gif" : ".gif"))
                                imageURL_bak = imageURL
                            }
                            
                        }, label:{ Text(nearest ? "More Smooth" : "More Rough"); Image(systemName: nearest ? "sparkle.magnifyingglass" : "text.magnifyingglass") })
                    Button (
                        action:{
                            invert.toggle()
                            UserDefaults.standard.set(invert, forKey: "invert")
                        }, label:{ Text(invert ? "Normal view" : "Invert Color"); Image(systemName: invert ? "photo" : "photo.fill") })
                } label: { Text("Effect..."); Image(systemName: "sparkles") }
                Divider()
                Group {
                    Button( action:{ openNewWindow(window!) }, label:{ Text("New Board");Image(systemName: "plus.square.on.square") })
                    if !mainWindow {
                        Button( action:{ window!.close() }, label:{ Text("Close Board"); Image(systemName: "multiply.square") })
                    }
                    Menu{
                        Button(
                            action: {
                                /*guard let window = NSApplication.shared.windows.first else { assertionFailure(); return }
                                 onTop.toggle()
                                 if onTop { window.level = .floating } else { window.level = .normal }
                                 UserDefaults.standard.set(onTop, forKey: "onTop")
                                 }, label: { Text(onTop ? "Always on Top 􀆅" : "Always on Top"); Image(systemName: onTop ? "pin.slash" : "pin") }*/
                                if window!.level == .normal { window!.level = .floating } else { window!.level = .normal }
                            }, label: { Text("Pin / Unpin"); Image(systemName: "pin") })
                        Button( action:{
                            window!.toggleFullScreen(nil)
                            //let fullScreen = window!.styleMask.contains(NSWindow.StyleMask.fullScreen)
                            //if fullScreen { scale = min(window!.screen!.frame.height, window!.screen!.frame.width)/352 } else { scale = 1.0 }
                        }, label:{ Text("Full Screen"); Image(systemName: "arrow.up.left.and.arrow.down.right") })
                    } label: { Text("More..."); Image(systemName: "command.square.fill") }
                    Divider()
                    Button( action:{ imageURL = about }, label:{ Text("About Pixboard");Image(systemName: "info.square") })
                    //Button ( action:{ PixboardApp().appDelegate.clearCache() }, label:{ Text("Clear Cache"); Image(systemName: "trash.square") })
                    Button( action:{ NSApplication.shared.terminate(self) }, label:{ Text("Quit"); Image(systemName: "x.square.fill") })
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("HDR Check Failed"), message: Text("This is not an HDR monitor, or you have not enabled HDR mode in your system!\n\nPixboard will show HDR content, but you may get the wrong brightness and color."))
            }
            //.onReceive(timer) { time in }
            .scaleEffect(scale)
            .background(WindowAccessor(window: $window))
            .onAppear { size = window?.frame.size ?? .zero }
            .onChange(of: geometry.size) { newSize in scale = max(1.0, min(newSize.width, newSize.height)/352) }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

func openNewWindow(_ pWindow: NSWindow) {
    //let point = NSEvent.mouseLocation
    let point = CGPoint(x: pWindow.frame.minX+18, y: pWindow.frame.minY+10)
    let window = NSWindow(contentRect: .zero, styleMask: [.titled, .fullSizeContentView, .resizable], backing: .buffered, defer: false)
    window.isOpaque = false
    window.level = .floating
    window.makeKeyAndOrderFront(nil)
    window.isReleasedWhenClosed = false
    window.titlebarAppearsTransparent = true
    window.isMovableByWindowBackground = true
    window.standardWindowButton(.closeButton)?.isHidden = true
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window.standardWindowButton(.zoomButton)?.isHidden = true
    window.setFrame(NSRect(x:point.x, y:point.y, width: 352, height: 324), display: true)
    window.contentView = NSHostingView(rootView: ContentView().frame(minWidth: 352, maxWidth: .infinity, minHeight: 324, maxHeight: .infinity))
}

/*struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
*/
