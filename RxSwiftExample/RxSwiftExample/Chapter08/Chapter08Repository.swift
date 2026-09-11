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
