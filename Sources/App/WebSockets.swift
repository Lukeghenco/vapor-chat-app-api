import Vapor
import Foundation

let roomsChannel = RoomsChannel()
let users = ["luke", "jim", "alex", "sarah", "sue", "alexis", "sandra"]

extension Droplet {
    public func setupWebSockets() throws {
        
        print("Mounting Websockets")
        
        socket("rooms") { req, ws in
            
            let randomIndex = Int(arc4random_uniform(UInt32(users.count)))
            let randomUser = users[randomIndex]
            roomsChannel.connections[randomUser] = ws;
            
            print("Connected to Rooms socket")
            
            background {
                while ws.state == .open {
                    try? ws.ping()
                    self.console.wait(seconds: 10) // every 10 seconds
                }
            }
            
            ws.onText = { ws, text in
                let json = try JSON(bytes: Array(text.utf8))
                print(json)
                
                if let type = json["type"] {
                    switch type {
                    case "GET_ROOMS":
                        let rooms = try Room.all().makeJSON()
                        roomsChannel.send(meta: rooms)
                    case "ADD_ROOM":
                        if let roomJSON = json["room"] {
                            let newRoom = try Room(json: roomJSON)
                            try newRoom.save()
                            let room = try newRoom.makeJSON()
                            roomsChannel.send(meta: room)
                        }
                    case "CLOSE_ROOM":
                        if let roomJSON = json["room"],
                            let roomId = roomJSON.object?["id"]?.int {
                            if let room = try Room.find(roomId) {
                                try room.delete()
                                var jsonResponse = JSON()
                                try jsonResponse.set("message", "The \(room.name) room was just closed")
                                try jsonResponse.set("roomId", roomId)
                                roomsChannel.send(meta: jsonResponse)
                            } else {
                                var jsonResponse = JSON()
                                try jsonResponse.set("message", "Unable to destroy room")
                                roomsChannel.send(meta: jsonResponse)
                            }
                        }
                    default:
                        roomsChannel.send(meta: "No Type was sent with the request")
                    }
                }
                
                ws.onClose = { ws, _, _, _ in
                    roomsChannel.connections.removeValue(forKey: randomUser)
                }
            }
        }
    }
}
