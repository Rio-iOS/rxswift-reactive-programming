//
//  Chapter08Repository.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/18.
//

import Foundation

struct Chapter08Repository: Codable {
    let name: String
    let owner: Chapter08Owner?

    enum CodingKeys: String, CodingKey {
        case name
        case owner
    }
}

struct Chapter08Owner: Codable {
    let name: String
    let avatar: URL

    enum CodingKeys: String, CodingKey {
        case name = "login"
        case avatar = "avatar_url"
    }
}
