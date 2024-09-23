//
//  Chapter10EOCategory.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/22.
//

import Foundation

struct Chapter10EOCategory: Decodable {
    let id: Int
    let name: String
    let description: String
    
    var events = [Chapter10EOEvent]()
    var endpoint: String {
        return "\(Chapter10EONET.categoriesEndpoint)/\(self.id)"
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name = "title"
        case description
    }
}

extension Chapter10EOCategory: Equatable {
    static func == (lhs: Chapter10EOCategory, rhs: Chapter10EOCategory) -> Bool {
        lhs.id == rhs.id
    }
}
