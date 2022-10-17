//
//  Item.swift
//  TilesByKia
//
//  Created by Michael Kampouris on 5/7/22.
//

import Foundation

struct Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.name == rhs.name
    }
    
    var upc: String
    var name: String
    let locations: [String : Any?]
    
    var quantity: String {
        var value = 0.0
        locations.forEach { location in
            let doubleString = location.value
            value += Double(doubleString as? String ?? "0") ?? 0.0
        }
        return String(value)
    }
    
    var locationString: String {
        var string = ""
        locations.forEach { location in
            string += "\(location.key) - \(location.value ?? "0") \(uom)\n"
        }
        return string
    }
    
    let uom: String
    var squareFeetPerBox: String?
    
    init(upc: String, name: String, uom: String, locations: [String:Any?]) {
        self.upc = upc
        self.name = name
        self.locations = locations
        self.uom = uom
    }
    
    init(key: String, dictionary: [String : Any]) {
        self.upc = key
        self.name = dictionary["name"] as? String ?? ""
        self.locations = dictionary["locations"] as? [String:String] ?? [:]
        self.uom = dictionary["uom"] as? String ?? ""
        self.squareFeetPerBox = dictionary["squareFeetPerBox"] as? String ?? nil
    }
    
    var asJSON: [String:Any?] {
        return [
            "name" : self.name,
            "locations" : self.locations,
            "uom" : self.uom,
            "squareFeetPerBox" : self.squareFeetPerBox ?? nil
        ]
    }

}
