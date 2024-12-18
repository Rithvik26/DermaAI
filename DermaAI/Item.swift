//
//  Item.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/14/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
