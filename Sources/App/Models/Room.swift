import Vapor
import FluentProvider
import HTTP

final class Room: Model {
    let storage = Storage()
    
    // MARK: Properties and database keys
    var name: String
    
    static let idKey = "id"
    static let nameKey = "name"

    init(name: String) {
        self.name = name
    }

    // MARK: Fluent Serialization
    init(row: Row) throws {
        name = try row.get(Room.nameKey)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Room.nameKey, name)
        return row
    }
}

// MARK: Fluent Preparation
extension Room: Preparation {
    
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Room.nameKey)
        }
    }

    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: JSON
extension Room: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            name: json.get(Room.nameKey)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Room.idKey, id)
        try json.set(Room.nameKey, name)
        return json
    }
}

// MARK: HTTP
extension Room: ResponseRepresentable { }

// MARK: Update
extension Room: Updateable {
    public static var updateableKeys: [UpdateableKey<Room>] {
        return [
            UpdateableKey(Room.nameKey, String.self) { room, name in
                room.name = name
            }
        ]
    }
}
