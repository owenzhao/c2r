//
//  Model.swift
//  c2r
//
//  Created by 肇鑫 on 2017-4-16.
//  Copyright © 2017年 ParusSoft.com. All rights reserved.
//

import Foundation
import RealmSwift
import EventKit

class CREvent:Object {
    dynamic var calendarItemIdentifier: String = ""
    dynamic var calendarItemExternalIdentifier: String = ""
    dynamic var reminder:CRReminder? = nil
    
    override class func primaryKey() -> String? { return "calendarItemIdentifier" }
    
    convenience init(_ ekEvent:EKEvent) {
        self.init()
        calendarItemIdentifier = ekEvent.calendarItemIdentifier
        calendarItemExternalIdentifier = ekEvent.calendarItemExternalIdentifier
    }
}

class CRReminder:Object {
    dynamic var calendarItemIdentifier: String = ""
    dynamic var calendarItemExternalIdentifier: String = ""
    
    override class func primaryKey() -> String? { return "calendarItemIdentifier" }
    
    convenience init(_ ekReminder:EKReminder) {
        self.init()
        calendarItemIdentifier = ekReminder.calendarItemIdentifier
        calendarItemExternalIdentifier = ekReminder.calendarItemExternalIdentifier
    }
}

extension EKReminder {
    convenience init(event:EKEvent, store:EKEventStore, minutesBeforeEndDate minutes:Int, reminderCalendar calendar: EKCalendar) {
        self.init(eventStore: store)
        
        self.calendar = calendar
        title = String(format: "\"%@\"在%d分钟后结束", event.title, minutes)//event.title
        timeZone = event.timeZone
        notes = event.notes
        recurrenceRules = event.recurrenceRules
        
        let cal = Calendar(identifier: .gregorian)
        var cps = cal.dateComponents([.timeZone, .year, .month, .day, .hour, .minute], from: event.endDate)
        cps.minute = cps.minute! - minutes
        startDateComponents = cps
        dueDateComponents = cps
        
        let alarm = EKAlarm(absoluteDate: cal.date(from: dueDateComponents!)!)
        addAlarm(alarm)
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        func optionalEqual<T:Hashable>(lhs:Optional<T>, rhs:Optional<T>) -> Bool {
            if lhs == nil { return rhs == nil }
            if rhs == nil { return lhs == nil }
            guard type(of:lhs) == type(of:rhs) else { return false }
            return lhs! == rhs!
        }
        
        guard let rhs = object as? EKReminder else { return false }
        let lhs = self
        
        return lhs.calendar == rhs.calendar
            && lhs.title == rhs.title
            && lhs.hasRecurrenceRules == rhs.hasRecurrenceRules
            && (!lhs.hasRecurrenceRules || lhs.recurrenceRules! == rhs.recurrenceRules!)
            && optionalEqual(lhs: lhs.timeZone, rhs: rhs.timeZone)
            && optionalEqual(lhs: lhs.notes, rhs: rhs.notes)
            && optionalEqual(lhs: lhs.startDateComponents, rhs: rhs.startDateComponents)
            && optionalEqual(lhs: lhs.dueDateComponents, rhs: rhs.dueDateComponents)
    }
}

