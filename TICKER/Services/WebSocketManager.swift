import Foundation
import Combine

public class WebSocketManager: NSObject, ObservableObject {
    public static let shared = WebSocketManager()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let url = URL(string: "ws://127.0.0.1:8080/ws/websocket")!
    
    @Published var isConnected = false
    
    // Callback for received messages
    var onMessageReceived: ((NotificationDto) -> Void)?
    
    private override init() {
        super.init()
    }
    
    public func connect(userId: Int) {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        self.receiveMessage()
        
        // Send CONNECT frame
        sendStompFrame(command: "CONNECT", headers: [
            "accept-version": "1.2",
            "heart-beat": "10000,10000"
        ])
        
        // Subscribe to user notifications
        subscribe(to: "/topic/user/\(userId)/notifications")
        // Subscribe to user stock updates (for real-time price on my profile)
        subscribe(to: "/topic/stock/\(userId)")
    }
    
    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
    
    public func subscribe(to destination: String) {
        sendStompFrame(command: "SUBSCRIBE", headers: [
            "id": "sub-\(destination)",
            "destination": destination
        ])
    }
    
    private func sendStompFrame(command: String, headers: [String: String], body: String = "") {
        var frame = "\(command)\n"
        for (key, value) in headers {
            frame += "\(key):\(value)\n"
        }
        frame += "\n\(body)\0"
        
        let message = URLSessionWebSocketTask.Message.string(frame)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleStompMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleStompMessage(text)
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage() // Continue receiving
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.isConnected = false
            }
        }
    }
    
    private func handleStompMessage(_ text: String) {
        // Skip heartbeat frames (empty lines)
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }
        
        // Simple STOMP parser handling both \n and \r\n
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        let parts = normalizedText.components(separatedBy: "\n\n")
        guard !parts.isEmpty else { return }
        
        let headerLines = parts[0].components(separatedBy: "\n")
        guard !headerLines.isEmpty else { return }
        
        let command = headerLines[0]
        
        if command == "CONNECTED" {
            DispatchQueue.main.async {
                self.isConnected = true
            }
            print("WebSocket STOMP Connected")
            return
        }
        
        if command == "MESSAGE" {
            // Body is everything after the first \n\n
            if let bodyStartIndex = normalizedText.range(of: "\n\n")?.upperBound {
                let remainder = String(normalizedText[bodyStartIndex...])
                let body = remainder.trimmingCharacters(in: CharacterSet(charactersIn: "\0\n\r "))
                
                if let data = body.data(using: .utf8) {
                    do {
                        let notification = try JSONDecoder().decode(NotificationDto.self, from: data)
                        DispatchQueue.main.async {
                            self.onMessageReceived?(notification)
                        }
                    } catch {
                        print("Failed to decode STOMP message: \(error)")
                        print("Raw body: \(body)")
                    }
                }
            }
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol `protocol`: String?) {
        print("WebSocket Opened")
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket Closed")
        self.isConnected = false
    }
}
