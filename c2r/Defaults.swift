//
//  Defaults.swift
//  c2r
//
//  Created by 肇鑫 on 2017-4-14.
//  Copyright © 2017年 ParusSoft.com. All rights reserved.
//

import Foundation

struct Defaults {
    static var shared:[String:Any] = [
        "default events calendar id": "",
        "default reminders calendar id": "",
        "alert time in minutes": -1,
        "no alert time check": true,
        "is app running": false
    ]
}
