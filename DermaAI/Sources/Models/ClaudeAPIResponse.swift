// Directory: /Users/rithvikgolthi/Desktop/DermaAI/DermaAI/Sources/Models/ClaudeAPIResponse.swift

struct ClaudeAPIResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ContentItem]
    let model: String
    let usage: UsageInfo?
    
    struct ContentItem: Codable {
        let type: String
        let text: String
    }
    
    struct UsageInfo: Codable {
        let input_tokens: Int
        let output_tokens: Int
    }
}
struct MessageRequest: Codable {
    let model: String
    let max_tokens: Int
    let messages: [Message]
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}
