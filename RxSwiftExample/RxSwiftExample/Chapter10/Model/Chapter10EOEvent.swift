//
//  Chapter10EOEvent.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/22.
//

import Foundation

struct Chapter10EOEventCategory: Decodable {
    let id: Int
    let title: String
}

struct Chapter10EOEvent: Decodable {
    let id: String
    let title: String
    let description: String
    let link: URL?
    let closeDate: Date?
    let categories: [Chapter10EOEventCategory]
    let locations: [Chapter10EOLocation]?
    var date: Date? {
        closeDate ?? locations?.compactMap(\.date).first
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case link
        case closeDate = "closed"
        case categories
        case locations = "geometries"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        link = try container.decode(URL?.self, forKey: .link)
        closeDate = try container.decode(Date.self, forKey: .closeDate)
        categories = try container.decode([Chapter10EOEventCategory].self, forKey: .categories)
        locations = try? container.decode([Chapter10EOLocation].self, forKey: .locations)
    }
    
    static func compareDates(lhs: Chapter10EOEvent, rhs: Chapter10EOEvent) -> Bool {
        switch (lhs.date, rhs.date) {
        case (nil, nil):
            return false
        
        case (nil, _):
            return true
            
        case (_, nil):
            return false
            
        case (let ldate, let rdate):
            return ldate! < rdate!
        }
    }
}
