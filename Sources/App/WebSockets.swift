import Vapor
import Foundation

let rooms = Rooms()
let users = ["luke", "jim", "alex", "sarah", "sue", "alexis", "sandra"]

extension Droplet {
    public func setupWebSockets() throws {
        
        print("Mounting Websockets")
        
        socket("rooms") { req, ws in
            
            let randomIndex = Int(arc4random_uniform(UInt32(users.count)))
            let randomUser = users[randomIndex]
            rooms.connections[randomUser] = ws;
            
            print("Connected to Rooms socket")
            
            background {
                while ws.state == .open {
                    try? ws.ping()
                    self.console.wait(seconds: 10) // every 10 seconds
                }
            }
            
            ws.onText = { ws, text in
                print(rooms.connections)
                
                let json = try JSON(bytes: Array(text.utf8))
                print(json)
                
                if let type = json["type"] {
                    switch type {
                    case "GET_ROOMS":
                        let posts = try Post.all().makeJSON()
                        rooms.send(meta: posts)
                    case "ADD_ROOM":
                        if let roomJSON = json["room"] {
                            let newPost = try Post(json: roomJSON)
                            try newPost.save()
                            let post = try newPost.makeJSON()
                            rooms.send(meta: post)
                        }
                    case "CLOSE_ROOM":
                        if let roomJSON = json["room"],
                            let roomId = roomJSON.object?["id"]?.int {
                            if let post = try Post.find(roomId) {
                                try post.delete()
                                var jsonResponse = JSON()
                                try jsonResponse.set("message", "The \(post.name) was just closed")
                                try jsonResponse.set("roomId", roomId)
                                rooms.send(meta: jsonResponse)
                            } else {
                                var jsonResponse = JSON()
                                try jsonResponse.set("message", "Unable to destroy room")
                                rooms.send(meta: jsonResponse)
                            }
                            
                        }
                    default:
                        rooms.send(meta: "No Type was sent with the request")
                    }
                }
                
                ws.onClose = { ws, _, _, _ in
                    
                    rooms.connections.removeValue(forKey: randomUser)
                }
            }
        }
    }
}
