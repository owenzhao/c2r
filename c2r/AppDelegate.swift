//
//  AppDelegate.swift
//  c2r
//
//  Created by 肇鑫 on 2017-4-14.
//  Copyright © 2017年 ParusSoft.com. All rights reserved.
//

import Cocoa
import EventKit
import RxSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var store = EKEventStore()
    let disposeBag = DisposeBag()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        requestCapabilityOfAccessesToEventAndReminder()
        registerDefaults()
    }
    
    private func requestCapabilityOfAccessesToEventAndReminder() {
        let types:[EKEntityType] = [.event, .reminder]
        types.forEach {
            store.requestAccess(to: $0) { (success, error) in
                guard error == nil else { fatalError(error!.localizedDescription) }
            }
        }
    }
    
    private func registerDefaults() {
        UserDefaults.standard.register(defaults: Defaults.shared)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
