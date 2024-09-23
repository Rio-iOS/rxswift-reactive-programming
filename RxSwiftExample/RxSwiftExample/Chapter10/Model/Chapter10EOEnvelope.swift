//
//  Chapter10EOEnvelope.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/23.
//

import Foundation

extension CodingUserInfoKey {
    static let contentIdentifier = CodingUserInfoKey(rawValue: "contentIdentifier")!
}

struct Chapter10EOEnvelope<Content: Decodable>: Decodable {
    let content: Content
    
    private struct CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int? = nil
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        init?(intValue: Int) {
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        guard let ci = decoder.userInfo[CodingUserInfoKey.contentIdentifier],
              let contentIdentifier = ci as? String,
              let key = CodingKeys(stringValue: contentIdentifier)
        else {
            throw Chapter10EOError.invalidDecopderConfiguration
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(Content.self, forKey: key)
    }
}
