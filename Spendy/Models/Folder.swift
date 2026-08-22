//
//  Folder.swift
//  Spendy
//
//  Folder Model for Grouping Categories
//

import SwiftUI

struct Folder: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var type: TransactionType
    
    init(id: String = UUID().uuidString.lowercased(), name: String, type: TransactionType) {
        self.id = id
        self.name = name
        self.type = type
    }
}
