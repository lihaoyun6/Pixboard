//
//  PixboardApp.swift
//  Pixboard
//
//  Created by apple on 2023/8/23.
//

import SwiftUI
import Quartz
import SDWebImageSwiftUI

@main
struct PixboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView(mainWindow: true)
                .frame(minWidth: 352, maxWidth: .infinity, minHeight: 324, maxHeight: .infinity)
                .handlesExternalEvents(preferring: [""], allowing: ["*"])
        }
        .windowStyle(.hiddenTitleBar)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        hideTitleBar()
        clearCache()
              /*let image = NSImage(named:  "test")
              let appDockTile =  NSApplication.shared.dockTile
              appDockTile.contentView = NSImageView(image: image!)
              appDockTile.display()*/
        //let appDockTile =  NSApplication.shared.dockTile
        //appDockTile.contentView = NSHostingView(rootView: ContentView())
        //appDockTile.display()
    }

    func hideTitleBar() {
        guard let window = NSApplication.shared.windows.first else { assertionFailure(); return }
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        try! FileManager.default.createDirectory(atPath: ContentView().tempPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    func clearCache() {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(atPath: ContentView().tempPath)
            for filePath in filePaths {
                try FileManager.default.removeItem(atPath: ContentView().tempPath + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
}
