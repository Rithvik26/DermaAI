//
//  ClaudeAPITester.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/15/24.
//


import Foundation

class ClaudeAPITester {
    static func testAPI() async {
        // API endpoint
#if DEBUG
let apiKey = Bundle.main.infoDictionary?["ANTHROPIC_API_KEY"] as? String ?? ""
#else
let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
#endif
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            print("Invalid URL")
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Headers
        let headers = [
            "Content-Type": "application/json",
            "anthropic-version": "2024-02-15",
            "x-api-key": apiKey  // Replace with your API key
        ]
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Simple message body
        let messageBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": "Please respond with a simple JSON: { \"test\": \"successful\" }"
                ]
            ]
        ]
        
        do {
            // Convert body to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: messageBody)
            request.httpBody = jsonData
            
            // Print request details for debugging
            print("\n=== Request Details ===")
            print("URL: \(url.absoluteString)")
            print("Headers:")
            headers.forEach { print("\($0): \($1)") }
            print("\nBody:")
            if let bodyString = String(data: jsonData, encoding: .utf8) {
                print(bodyString)
            }
            
            // Make the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Print response details
            print("\n=== Response Details ===")
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
                print("\nResponse Headers:")
                httpResponse.allHeaderFields.forEach { print("\($0): \($1)") }
            }
            
            print("\nResponse Body:")
            if let responseString = String(data: data, encoding: .utf8) {
                print(responseString)
            }
            
        } catch {
            print("\n=== Error ===")
            print("Error Type: \(type(of: error))")
            print("Error Description: \(error.localizedDescription)")
        }
    }
}
