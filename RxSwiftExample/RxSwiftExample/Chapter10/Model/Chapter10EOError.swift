//
//  Chapter10EOError.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/22.
//

import Foundation

enum Chapter10EOError: Error {
    case invalidURL(String)
    case invalidParameter(String, Any)
    case invalidJSON(String)
    case invalidDecopderConfiguration
}
