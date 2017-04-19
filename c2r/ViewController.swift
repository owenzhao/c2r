//
//  ViewController.swift
//  c2r
//
//  Created by 肇鑫 on 2017-4-14.
//  Copyright © 2017年 ParusSoft.com. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa
import EventKit
import RealmSwift

class ViewController: NSViewController {
    let defaults = UserDefaults.standard
    let store = (NSApp.delegate as! AppDelegate).store
    var disposeBag = DisposeBag()
    
    var eventCalendars:[EKCalendar]!
    var reminderCalendars:[EKCalendar]!
    
    var currentObserveOnEventCalendar:EKCalendar { return eventCalendars[eventCalendarPopUpButton.indexOfSelectedItem] }
    var currentWriteToReminderCalendar:EKCalendar { return reminderCalendars[reminderCalendarPopUpButton.indexOfSelectedItem] }
    var minutes:Int { return Int(alertTimeInMinutesTextField.stringValue) ?? 3 }
    
    var vEvents = Variable<[EKEvent]>([])
    var crEvents:Results<CREvent>! = nil
    
    var initTimer:Timer? = nil
    var rxTimer:Timer? = nil
    
    private func createNewReminder(event:EKEvent) -> EKReminder? {
        switch noAlertTimeCheckButton.state {
        case NSOnState:
            let timeLength = event.endDate.timeIntervalSince(event.startDate)
            if timeLength > 15 * 60 { fallthrough }
            else { return nil }
        case NSOffState:
            return EKReminder(event: event, store: store, minutesBeforeEndDate: minutes, reminderCalendar: currentWriteToReminderCalendar)
        default:
            fatalError()
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        crEvents = try! Realm().objects(CREvent.self)
        
        waitForEventKitAuthorization()
        
        initTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(eventKitAuthorized), userInfo: nil, repeats: true)
            
//            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [unowned self] timer in
//            let eventAccess = EKEventStore.authorizationStatus(for: .event)
//            let reminderAccess = EKEventStore.authorizationStatus(for: .reminder)
//            if eventAccess == .authorized && reminderAccess == .authorized {
//                timer.invalidate()
//                DispatchQueue.main.async { [unowned self] in
//                    self.eventKitAuthorized()
//                }
//            }
//        }
    }
    
    private func waitForEventKitAuthorization() {
        disableEverything()
        self.progressBar.startAnimation(nil)
    }
    
    @objc private func eventKitAuthorized() {
        let eventAccess = EKEventStore.authorizationStatus(for: .event)
        let reminderAccess = EKEventStore.authorizationStatus(for: .reminder)
        if eventAccess == .authorized && reminderAccess == .authorized {
            initTimer?.invalidate()
            self.progressBar.stopAnimation(nil)
            self.progressBar.isHidden = true
            
            self.setup()
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBOutlet weak var progressBar: NSProgressIndicator!

    @IBOutlet weak var eventCalendarPopUpButton: NSPopUpButton!
    @IBOutlet weak var reminderCalendarPopUpButton: NSPopUpButton!

    @IBOutlet weak var alertTimeInMinutesTextField: NSTextField!
    @IBOutlet weak var noAlertTimeCheckButton: NSButton!
    
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var endButton: NSButton!
    
    private func setup() {
        setupUI()
        setupRx()
    }
    
    private func setupUI() {
        setupPopUpButtons()
        
        alertTimeInMinutesTextField.stringValue = {
            let intValue = defaults.integer(forKey: "alert time in minutes")
            return intValue == -1 ? "" : String(intValue)
        }()
        
        noAlertTimeCheckButton.state = {
            let state = defaults.bool(forKey: "no alert time check")
            return state ? NSOnState : NSOffState
        }()
        
        self.enableEverything()
        self.endButton.isEnabled = false
    }
    
    private func setupPopUpButtons() {
        func setupPopButton(popButton button:NSPopUpButton, sourcesCalendars calendars:[EKCalendar], defaultKey key:String) {
            button.removeAllItems()
            button.addItems(withTitles: calendars.map { $0.title })
            if let defaultCalendarId = defaults.string(forKey: key),
                let index = calendars.map({ $0.calendarIdentifier }).index(of: defaultCalendarId)
            {
                button.selectItem(at: index)
            }
        }
        
        eventCalendars = store.calendars(for: .event).filter { $0.allowsContentModifications }
        reminderCalendars = store.calendars(for: .reminder).filter { $0.allowsContentModifications }
        setupPopButton(popButton: eventCalendarPopUpButton, sourcesCalendars: eventCalendars, defaultKey: "default events calendar id")
        setupPopButton(popButton: reminderCalendarPopUpButton, sourcesCalendars: reminderCalendars, defaultKey: "default reminders calendar id")
    }
    
    private func setupRxNotification() {
        NotificationCenter.default.rx.notification(.EKEventStoreChanged)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [unowned self] _ in self.notificationDealer() })
            .disposed(by: disposeBag)
    }
    
    private func setupRx() {
        setupRxNotification()
        
        eventCalendarPopUpButton.rx.tap
            .map { [unowned self] _ in self.eventCalendarPopUpButton.indexOfSelectedItem }
            .subscribe(onNext: { [unowned self] in self.defaults.set(self.eventCalendars[$0].calendarIdentifier, forKey: "default events calendar id") })
            .disposed(by: disposeBag)
        
        
        reminderCalendarPopUpButton.rx.tap
            .map { [unowned self] _ in self.reminderCalendarPopUpButton.indexOfSelectedItem }
            .subscribe(onNext: { [unowned self] in self.defaults.set(self.reminderCalendars[$0].calendarIdentifier, forKey: "default reminders calendar id") })
            .disposed(by: disposeBag)
        
        let alertTimerDriver = alertTimeInMinutesTextField.rx.text.orEmpty
            .map { stringValue -> String in
                if let intValue = Int(stringValue), 0 <= intValue && intValue <= 15 {
                    return stringValue
                }
                else { return "" }
            }
            .asDriver(onErrorJustReturn: "")
        alertTimerDriver
            .drive(alertTimeInMinutesTextField.rx.text)
            .disposed(by: disposeBag)
        alertTimerDriver
            .drive(onNext: { [unowned self] stringValue in
                self.defaults.set(Int(stringValue) ?? -1, forKey: "alert time in minutes")
            })
            .disposed(by:disposeBag)
        
        noAlertTimeCheckButton.rx.state
            .subscribe(onNext: { [unowned self]  in self.defaults.set($0 == NSOnState, forKey: "no alert time check") })
            .disposed(by: disposeBag)
        
        startButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                self.disableEverything()
                self.endButton.isEnabled = true
                self.vEvents.value = self.eventQuery()
            })
            .disposed(by: disposeBag)
        
        endButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                self.enableEverything()
                self.endButton.isEnabled = false
            })
            .disposed(by: disposeBag)
        
        vEvents.asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [unowned self] events in
                self.rxTimer?.invalidate()
                let userInfo = events
                self.rxTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.eventChanged(timer:)), userInfo: userInfo, repeats: false)
            })
            .disposed(by: disposeBag)
    }
        
    @objc private func eventChanged(timer:Timer) {
        guard self.startButton.isEnabled == false else { return }
        defer { self.setupRxNotification() }
        // MARK: - keep data in Realm is updated
        let events = timer.userInfo as! [EKEvent]
        let realm = try! Realm()
        for crEvent in self.crEvents {
            let event = self.store.event(withIdentifier: crEvent.calendarItemIdentifier)
            let reminder = self.store.calendarItem(withIdentifier: crEvent.reminder!.calendarItemIdentifier) as? EKReminder
            
            realm.beginWrite()
            switch (event, reminder) {
            case (nil,nil):
                realm.delete(crEvent.reminder!)
                realm.delete(crEvent)
            case (nil,.some(let reminder)):
                try! self.store.remove(reminder, commit: false)
                
                realm.delete(crEvent.reminder!)
                realm.delete(crEvent)
            case (.some(let event), nil):
                if let newReminder = self.createNewReminder(event: event) {
                    try! self.store.save(newReminder, commit: false)
                    
                    realm.delete(crEvent.reminder!)
                    let newCRReminder = CRReminder(newReminder)
                    crEvent.reminder = newCRReminder
                    realm.add(crEvent, update: true)
                }
                else {
                    realm.delete(crEvent.reminder!)
                    realm.delete(crEvent)
                }
            case (.some(let event), .some(let reminder)):
                if let newReminder = self.createNewReminder(event: event) {
                    //                            if newReminder == reminder {
                    if newReminder != reminder {
                        try! self.store.remove(reminder, commit: false)
                        try! self.store.save(newReminder, commit: false)
                        
                        realm.delete(crEvent.reminder!)
                        let newCRReminder = CRReminder(newReminder)
                        crEvent.reminder = newCRReminder
                        realm.add(crEvent, update: true)
                    }
                }
                else {
                    try! self.store.remove(reminder, commit: false)
                    
                    realm.delete(crEvent.reminder!)
                    realm.delete(crEvent)
                }
                
            }
            try! realm.commitWrite()
        }
        
        // deal with new events
        let eventsFromCREvents:[EKEvent] = self.crEvents
            .map { self.store.event(withIdentifier: $0.calendarItemIdentifier) }
            .filter { $0 != nil }
            .map { $0! }
        let newEvents = Set(events).subtracting(eventsFromCREvents)
        
        realm.beginWrite()
        newEvents.forEach { [unowned self] in
            if let newReminder = self.createNewReminder(event: $0) {
                try! self.store.save(newReminder, commit: false)
                
                let crReminder = CRReminder(newReminder)
                let crEvent = CREvent($0)
                crEvent.reminder = crReminder
                
                realm.add(crEvent)
            }
        }
        try! realm.commitWrite()
        try! self.store.commit()
    }
    
    private func disableEverything() {
        [eventCalendarPopUpButton, reminderCalendarPopUpButton, alertTimeInMinutesTextField, noAlertTimeCheckButton, startButton, endButton]
            .forEach { $0.isEnabled = false }
    }
    
    private func enableEverything() {
        [eventCalendarPopUpButton, reminderCalendarPopUpButton, alertTimeInMinutesTextField, noAlertTimeCheckButton, startButton, endButton]
            .forEach { $0.isEnabled = true }
    }
    
    private func eventQuery() -> [EKEvent] {
        let date = Date()
        let calendar = Calendar(identifier: .gregorian)
        var cps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        cps.hour = cps.hour! - 3
        let withInLastThreeHours = calendar.date(from: cps)!
        cps.day = cps.day! + 3
        let withInThreeDays = calendar.date(from: cps)!
        
        let predicateForEvents = store.predicateForEvents(withStart: withInLastThreeHours, end: withInThreeDays, calendars: [currentObserveOnEventCalendar])
        return store.events(matching: predicateForEvents)
            .filter { date < $0.endDate }
    }
    
    @objc private func notificationDealer() {
        if !currentObserveOnEventCalendar.refresh() ||  !currentWriteToReminderCalendar.refresh(){
            let alert = { () -> NSAlert in 
                let a = NSAlert()
                a.alertStyle = .critical
                a.informativeText = "当前选定的日历被删除，请重新选择"
                return a
            }()
            if startButton.isEnabled == false { endButton.performClick(nil) }
            alert.beginSheetModal(for: view.window!, completionHandler: nil)
        }
        
        setupPopUpButtons()
        
        if startButton.isEnabled == false { vEvents.value = eventQuery() }
    }
    
//    // MARK: - Notification
//    private func registerNotification() {
//        NotificationCenter.default.addObserver(self, selector: #selector(notificationDealer), name: .EKEventStoreChanged, object: nil)
//    }
//    private func removeNotification() {
//        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: nil)
//    }
}
