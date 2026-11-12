//
//  TripModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 11/11/26.
//

import Foundation
import SwiftData

enum StopCategory:String,Codable,CaseIterable{
    case travel = "Transit"
    case accomodation = "Stay"
    case viewpoint = "Viewpoint"
    case food = "Food & Cafe"
    case permit = "Permit Checkpost"
    
    var iconName:String{
        switch self{
        case .travel: return "car.fill"
        case .accomodation:return "bed.double.fill"
        case .viewpoint:return "mountain.2.fill"
        case .food:return "fork.knife"
        case .permit:return "shield.checkered"
        }
    }
}

enum ExpensesCategory:String,Codable,CaseIterable{
    case transport = "Transport & Fuel"
    case food = "Dining & Snacks"
    case permit = "Permits & Passes" //kisi gjah ka pass,jaise wo buddha park ka ticket
    case stay = "Hotels"
    case emergency = "Emergency Supplies" //jaise gurudonmarg m oxygen supply
    
    var iconName:String{
        switch self{
        case .transport:return "car.fill"
        case .food:return "fork.knife.circle.fill"
        case .permit:return "doc.text.badge.plus"
        case .stay:return "house.fill"
        case .emergency:return "cross.case.fill"
        }
    }
}

@Model
final class Trip{
    @Attribute(.unique) var id:UUID
    var title:String //North Sikkim
    var subtitle:String //Gangtok
    var creationDate:Date
    var members:[String]
    
    @Relationship(deleteRule:.cascade,inverse: \ItineraryStop.trip)
    var stops:[ItineraryStop] = [] //all stops of the trip
    
    @Relationship(deleteRule:.cascade,inverse: \Expense.trip)
    var expenses:[Expense] = []
    
    init(
        id: UUID = UUID(),
        title: String = "",
        subtitle: String = "",
        creationDate: Date = Date(),
        members: [String] = ["Sahil", "Sania", "Baibhav", "Sohal"],
        stops: [ItineraryStop] = [],
        expenses: [Expense] = []
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.creationDate = creationDate
        self.members = members
        self.stops = stops
        self.expenses = expenses
    }
    
}
@Model
final class ItineraryStop{
    @Attribute(.unique) var id:UUID
    var dayNumber:Int
    var title:String
    var locationName:String
    var latitude:Double
    var longitude:Double
    var altitudeMeters:Int
    var timeString:String
    var notes:String
    var isCompleted:Bool
    var rawCategory:String
    var trip:Trip?
    var category:StopCategory{
        get{ StopCategory(rawValue:rawCategory) ?? .travel}
        set { rawCategory = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        dayNumber: Int = 1,
        title: String = "",
        locationName: String = "",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        altitudeMeters: Int = 0,
        timeString: String = "",
        notes: String = "",
        isCompleted: Bool = false,
        category: StopCategory = .travel,
        trip: Trip? = nil
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.title = title
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeMeters = altitudeMeters
        self.timeString = timeString
        self.notes = notes
        self.isCompleted = isCompleted
        self.rawCategory = category.rawValue
        self.trip = trip
    }
}
@Model
final class Expense{
    @Attribute(.unique) var id:UUID
    var title:String
    var amount:Double
    var paidBy:String
    var rawCategory:String
    var date:Date
    var splitAmong:[String]
    var trip:Trip?
    var category: ExpensesCategory {
        get { ExpensesCategory(rawValue: rawCategory) ?? .transport }
        set { rawCategory = newValue.rawValue }
    }
    init(
        id: UUID = UUID(),
        title: String = "",
        amount: Double = 0.0,
        paidBy: String = "",
        category: ExpensesCategory = .transport,
        splitAmong: [String] = [],
        date: Date = Date(),
        trip: Trip? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.paidBy = paidBy
        self.rawCategory = category.rawValue
        self.splitAmong = splitAmong
        self.date = date
        self.trip = trip
    }
}
