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

final class ViewController: NSViewController {
    private let defaults = UserDefaults.standard
    private let eventStore = (NSApp.delegate as! AppDelegate).eventStore
    private var disposeBag = DisposeBag()
    
    private var eventCalendars:[EKCalendar]!
    private var reminderCalendars:[EKCalendar]!
    
    private var observedEventCalendar:EKCalendar { return eventCalendars[calendarGroupNamesPopUpButton.indexOfSelectedItem] }
    private var writtenToReminderCalendar:EKCalendar { return reminderCalendars[reminderGroupNamesPopUpButton.indexOfSelectedItem] }
    private var alertBeforeEndOfTaskInMinutes:Int { return Int(alertTimeInMinutesTextField.stringValue) ?? 3 }
    
    var vEvents = Variable<[EKEvent]>([])
    lazy var crEvents:Results<CREvent> = try! Realm().objects(CREvent.self)
    
    var initTimer:Timer? = nil
    var dispatchWorkItem:DispatchWorkItem? = nil
    
    lazy var tileView:NSView = {
        let tile = NSApp.dockTile
        
        let view = NSView(frame: NSRect(x: 0, y: 0, width: tile.size.width, height: tile.size.height))
        let icon = NSApp.applicationIconImage
        let imageView = NSImageView(frame: NSRect(x: 0, y: 10, width: tile.size.width, height: tile.size.height))
        imageView.image = icon
        view.addSubview(imageView)
        
        let runningLabel = NSTextField(frame: NSRect(x: 0, y: 0 , width: tile.size.width, height: imageView.bounds.height * 45 / 100))
        runningLabel.backgroundColor = #colorLiteral(red: 0.0119239362, green: 0.4746654034, blue: 0.9847092032, alpha: 1)
        runningLabel.isBordered = false
        view.addSubview(runningLabel)
        
        return view
    }()
    
    private func createNewReminder(event:EKEvent) -> EKReminder? {
        switch noAlertTimeCheckButton.state {
        case .on:
            let timeLength = event.endDate.timeIntervalSince(event.startDate)
            if timeLength > 15 * 60 { fallthrough }
            else { return nil }
        case .off:
            return EKReminder(event: event, store: eventStore, minutesBeforeEndDate: alertBeforeEndOfTaskInMinutes, reminderCalendar: writtenToReminderCalendar)
        default:
            fatalError()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        waitForEventKitAuthorization()
        initTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(eventKitAuthorized), userInfo: nil, repeats: true)
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

    @IBOutlet weak var calendarGroupNamesPopUpButton: NSPopUpButton!
    @IBOutlet weak var reminderGroupNamesPopUpButton: NSPopUpButton!

    @IBOutlet weak var alertTimeInMinutesTextField: NSTextField!
    @IBOutlet weak var noAlertTimeCheckButton: NSButton!
    
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var endButton: NSButton!
    
    private func setup() {
        setupUI()
        setupRx()
        restoreRunningStat()
    }
    
    private func setupUI() {
        setupPopUpButtons()
        
        alertTimeInMinutesTextField.stringValue = {
            let intValue = defaults.integer(forKey: "alert time in minutes")
            return intValue == -1 ? "" : String(intValue)
        }()
        
        noAlertTimeCheckButton.state = {
            let state = defaults.bool(forKey: "no alert time check")
            return state ? .on : .off
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
            else if let calendarId = calendars.first?.calendarIdentifier {
                defaults.set(calendarId, forKey: key)
            }
        }
        
        func retrieveWritableEventCalendarsFor(type:EKEntityType) -> [EKCalendar] {
            return eventStore.calendars(for: type).filter { $0.allowsContentModifications }
        }
        
        let eventCalendars = retrieveWritableEventCalendarsFor(type: .event)
        let reminderCalendars = retrieveWritableEventCalendarsFor(type: .reminder)
        setupPopButton(popButton: calendarGroupNamesPopUpButton, sourcesCalendars: eventCalendars, defaultKey: "default events calendar id")
        setupPopButton(popButton: reminderGroupNamesPopUpButton, sourcesCalendars: reminderCalendars, defaultKey: "default reminders calendar id")
    }
    
    private func setupRxNotification() {
        NotificationCenter.default.rx.notification(.EKEventStoreChanged)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [unowned self] _ in self.notificationDealer() })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.NSCalendarDayChanged)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [unowned self] _ in
                self.dailyCleanUp()
                self.notificationDealer()
            })
            .disposed(by:disposeBag)
    }
    
    private func setupRx() {
        setupRxNotification()
        
        calendarGroupNamesPopUpButton.rx.tap
            .map { [unowned self] _ in self.calendarGroupNamesPopUpButton.indexOfSelectedItem }
            .subscribe(onNext: { [unowned self] in self.defaults.set(self.eventCalendars[$0].calendarIdentifier, forKey: "default events calendar id") })
            .disposed(by: disposeBag)
        
        
        reminderGroupNamesPopUpButton.rx.tap
            .map { [unowned self] _ in self.reminderGroupNamesPopUpButton.indexOfSelectedItem }
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
            .subscribe(onNext: { [unowned self]  in self.defaults.set($0 == .on, forKey: "no alert time check") })
            .disposed(by: disposeBag)
        
        startButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                self.disableEverything()
                self.endButton.isEnabled = true
                self.vEvents.value = self.eventQuery()
                
                let tile = NSApp.dockTile
                tile.contentView = self.tileView
                tile.display()
                
                self.defaults.set(true, forKey: "is app running")
            })
            .disposed(by: disposeBag)
        
        endButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                self.enableEverything()
                self.endButton.isEnabled = false
                
                let tile = NSApp.dockTile
                tile.contentView = nil
                tile.display()
                
                self.defaults.set(false, forKey: "is app running")
            })
            .disposed(by: disposeBag)
        
        vEvents.asObservable()
            .skip(1)
            .subscribe(onNext: { [unowned self] events in
                let twoSeconds = DispatchTime(uptimeNanoseconds: 2 * 1000_0000_000)
                self.dispatchWorkItem?.cancel()
                self.dispatchWorkItem = DispatchWorkItem(block: { [unowned self] in
                    self.eventChanged(events:events)
                })
                DispatchQueue.main.asyncAfter(deadline: twoSeconds, execute: self.dispatchWorkItem!)
            })
            .disposed(by: disposeBag)
    }
        
    private func eventChanged(events:[EKEvent]) {
        defer { self.setupRxNotification() }
        // MARK: - keep data in Realm is updated
        let now = Date()
        let realm = crEvents.realm!
        for crEvent in crEvents {
            let event = self.eventStore.event(withIdentifier: crEvent.calendarItemIdentifier)
            let reminder = self.eventStore.calendarItem(withIdentifier: crEvent.reminder!.calendarItemIdentifier) as? EKReminder
            
            realm.beginWrite()
            switch (event, reminder) {
            case (nil,nil):
                realm.delete(crEvent.reminder!)
                realm.delete(crEvent)
            case (nil,.some(let reminder)):
                try! self.eventStore.remove(reminder, commit: false)
                
                realm.delete(crEvent.reminder!)
                realm.delete(crEvent)
            case (.some(let event), nil):
                guard event.endDate > now else { break }
                if event.calendar == self.observedEventCalendar,
                    let newReminder = self.createNewReminder(event: event)
                {
                    try! self.eventStore.save(newReminder, commit: false)
                    
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
//                guard event.endDate > now else { break }
                if event.calendar == self.observedEventCalendar,
                    let newReminder = self.createNewReminder(event: event)
                {
                    //                            if newReminder == reminder {
                    if newReminder != reminder {
                        try! self.eventStore.remove(reminder, commit: false)
                        try! self.eventStore.save(newReminder, commit: false)
                        
                        realm.delete(crEvent.reminder!)
                        let newCRReminder = CRReminder(newReminder)
                        crEvent.reminder = newCRReminder
                        realm.add(crEvent, update: true)
                    }
                }
                else {
                    try! self.eventStore.remove(reminder, commit: false)
                    
                    realm.delete(crEvent.reminder!)
                    realm.delete(crEvent)
                }
                
            }
            try! realm.commitWrite()
        }
        
        // deal with new events
        let eventsFromCREvents:[EKEvent] = crEvents
            .compactMap { self.eventStore.event(withIdentifier: $0.calendarItemIdentifier) }
        let newEvents = Set(events).subtracting(eventsFromCREvents)
        
        realm.beginWrite()
        newEvents.forEach { [unowned self] in
            if let newReminder = self.createNewReminder(event: $0) {
                try! self.eventStore.save(newReminder, commit: false)
                
                let crReminder = CRReminder(newReminder)
                let crEvent = CREvent($0)
                crEvent.reminder = crReminder
                
                realm.add(crEvent)
            }
        }
        try! realm.commitWrite()
        try! self.eventStore.commit()
    }
    
    private func disableEverything() {
        [calendarGroupNamesPopUpButton, reminderGroupNamesPopUpButton, alertTimeInMinutesTextField, noAlertTimeCheckButton, startButton, endButton]
            .forEach { $0.isEnabled = false }
    }
    
    private func enableEverything() {
        [calendarGroupNamesPopUpButton, reminderGroupNamesPopUpButton, alertTimeInMinutesTextField, noAlertTimeCheckButton, startButton, endButton]
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
        
        let predicateForEvents = eventStore.predicateForEvents(withStart: withInLastThreeHours, end: withInThreeDays, calendars: [observedEventCalendar])
        return eventStore.events(matching: predicateForEvents)
            .filter { date < $0.endDate }
    }
    
    private func notificationDealer() {
        if !observedEventCalendar.refresh() ||  !writtenToReminderCalendar.refresh(){
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
    
    private func dailyCleanUp() {
        let realm = crEvents.realm!
        let now = Date()
        
        realm.beginWrite()
        for crEvent in crEvents {
            if let event = eventStore.event(withIdentifier: crEvent.calendarItemIdentifier),
                event.endDate > now
            {
                realm.delete(crEvent.reminder!)
                realm.delete(crEvent)
            }
        }
        try! realm.commitWrite()
    }
    
    private func restoreRunningStat() {
        DispatchQueue.main.async { [unowned self] in
            let runningState = self.defaults.bool(forKey: "is app running")
            let eventsCalendarId = self.defaults.string(forKey: "default events calendar id") ?? ""
            let remindersCalendarId = self.defaults.string(forKey: "default reminders calendar id") ?? ""
            
            if runningState
                && self.observedEventCalendar.calendarIdentifier == eventsCalendarId
                && self.writtenToReminderCalendar.calendarIdentifier == remindersCalendarId
            {
                self.startButton.performClick(nil)
            }
        }
    }
}
