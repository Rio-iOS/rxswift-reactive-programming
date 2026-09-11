import Foundation
import CoreLocation

enum Chapter10GeometryType: Decodable {
    case position
    case point
    case polygon
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let typeString = try container.decode(String.self)
        switch typeString {
        case "Point":
            self = .point
            
        case "Position":
            self = .position
            
        case "Polygon":
            self = .polygon
            
        default:
            throw Chapter10EOError.invalidJSON("Unknown geometry type \(typeString)")
        }
    }
}

struct Chapter10EOLocation: Decodable {
    let type: Chapter10GeometryType
    let date: Date?
    let coordinates: Array<CLLocationCoordinate2D>
    
    private enum CodingKeys: String, CodingKey {
        case type
        case date
        case coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(Chapter10GeometryType.self, forKey: .type)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        let positions: [[Double]]
        switch type {
        case .position, .point:
            positions = [try container.decode([Double].self, forKey: .coordinates)]
        case .polygon:
            positions = try container.decode([[[Double]]].self, forKey: .coordinates).flatMap { $0 }
        }
        guard !positions.isEmpty else { throw Chapter10EOError.invalidJSON("Empty coordinates") }
        coordinates = try positions.map { position in
            // GeoJSONの座標順は経度・緯度。高度などの追加要素は地図表示では使いません。
            guard position.count >= 2, position[0].isFinite, position[1].isFinite,
                  (-180...180).contains(position[0]), (-90...90).contains(position[1]) else {
                throw Chapter10EOError.invalidJSON("Invalid coordinates")
            }
            return CLLocationCoordinate2D(latitude: position[1], longitude: position[0])
        }
    }
}
