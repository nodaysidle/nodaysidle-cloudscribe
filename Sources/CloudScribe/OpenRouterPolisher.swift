import Foundation

enum PolishError: Error, Equatable {
    case missingAPIKey
    case invalidResponse
    case httpError(Int, String)
    case emptyResult
}

/// Optional text-only polish via OpenRouter. Never receives audio.
struct OpenRouterPolisher {
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private let model = "google/gemini-2.0-flash-lite-preview-02-05:free"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func polish(_ text: String, apiKey: String) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }
        guard !apiKey.isEmpty else { throw PolishError.missingAPIKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("CloudScribe", forHTTPHeaderField: "X-Title")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "You polish dictated speech-to-text for grammar and punctuation only. Return plain text with no markdown or commentary."
                ],
                [
                    "role": "user",
                    "content": trimmed
                ]
            ],
            "temperature": 0.2
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PolishError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw PolishError.httpError(http.statusCode, message)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw PolishError.invalidResponse
        }

        let polished = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !polished.isEmpty else { throw PolishError.emptyResult }
        return polished
    }
}