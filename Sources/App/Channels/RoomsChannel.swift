import Vapor

class Rooms {
    var connections: [String: WebSocket]
    
    func send(meta: JSON) {
        
        let metaNode: [String: NodeRepresentable] = [
            "meta": meta
        ]
        
        guard let json = try? JSON(node: metaNode) else {
            return
        }
        
        for (_, socket) in connections {
            
            try? socket.send(json)
        }
    }
    
    init() {
        connections = [:]
    }
}
