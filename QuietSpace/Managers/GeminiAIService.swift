// Nguyen Minh Triet Luu — Student ID: 101542519

import Foundation

/// Google Places context passed into Gemini (mirrors React Native `placeMatchInfo`).
struct GeminiPlaceMatchInfo {
    let placeId: String?
    let name: String?
    let address: String?
    let rating: Double?
    let userRatingsTotal: Int?
    let types: [String]
    let latitude: Double?
    let longitude: Double?
    let matchQuality: String
    let matchNotes: String
}

/// Parsed Gemini validation output (same fields as `GeminiAIService.js`).
struct LocationValidationResult {
    let isLegitimate: Bool
    let isSuspicious: Bool
    let suspicionLevel: String
    let concerns: [String]
    let reasoning: String
    let isAppropriateForQuietSpace: Bool
    let suggestedTags: [String]
    let confidence: Double
    let googlePlaceVerified: Bool
    let recommendedAction: String
    let isValid: Bool
    let suggestions: [String]
}

/// Calls Gemini REST API for location submission review (same model as React Native).
final class GeminiAIService {
    static let shared = GeminiAIService()

    private static let generateContentURL = URL(
        string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"
    )!

    private let session = URLSession(configuration: .default)

    private init() {}

    func validateLocationSubmission(
        name: String,
        address: String,
        type: String,
        description: String = "",
        tags: [String] = [],
        placeMatchInfo: GeminiPlaceMatchInfo? = nil
    ) async -> LocationValidationResult {
        let key = AppConfig.geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            return makeErrorResult(message: "Gemini API key is not configured", googleVerified: placeMatchInfo?.matchQuality == "strong")
        }

        let prompt = buildValidationPrompt(
            name: name,
            address: address,
            type: type,
            description: description,
            tags: tags.joined(separator: ", "),
            placeMatchInfo: placeMatchInfo
        )

        guard let text = await callGeminiAPI(prompt: prompt, apiKey: key) else {
            return makeErrorResult(message: lastError ?? "Unknown error", googleVerified: placeMatchInfo?.matchQuality == "strong")
        }

        return parseValidationResponse(text)
    }

    private var lastError: String?

    private func callGeminiAPI(prompt: String, apiKey: String) async -> String? {
        lastError = nil
        var comp = URLComponents(url: Self.generateContentURL, resolvingAgainstBaseURL: false)!
        comp.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = comp.url else { return nil }

        let body: [String: Any] = [
            "contents": [[
                "parts": [["text": prompt]]
            ]],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 2048
            ]
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                lastError = "Invalid response"
                return nil
            }
            guard (200..<300).contains(http.statusCode) else {
                lastError = "HTTP \(http.statusCode)"
                return nil
            }
            let decoded = try JSONDecoder().decode(GeminiGenerateResponse.self, from: data)
            let text = decoded.candidates?.first?.content?.parts?.first?.text
            if let text {
                return text
            }
            lastError = "No content in response"
            return nil
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    private struct GeminiGenerateResponse: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable { let text: String? }
                let parts: [Part]?
            }
            let content: Content?
        }
        let candidates: [Candidate]?
    }

    private func buildValidationPrompt(
        name: String,
        address: String,
        type: String,
        description: String,
        tags: String,
        placeMatchInfo: GeminiPlaceMatchInfo?
    ) -> String {
        let googlePlacesSection: String
        if let p = placeMatchInfo {
            let typesStr = p.types.joined(separator: ", ")
            googlePlacesSection = """
Google Places Verification:
- Match Quality: \(p.matchQuality.uppercased())
- Match Notes: \(p.matchNotes)
- Google Place ID: \(p.placeId ?? "Not found")
- Google Name: \(p.name ?? "N/A")
- Google Address: \(p.address ?? "N/A")
- Google Rating: \(p.rating.map { String($0) } ?? "N/A") (\(p.userRatingsTotal ?? 0) reviews)
- Google Types: \(typesStr.isEmpty ? "N/A" : typesStr)
"""
        } else {
            googlePlacesSection = "Google Places Verification: NO MATCH FOUND - location may not exist"
        }

        return """
You are validating a location submission for a "Quiet Space" app.

SUBMITTED LOCATION:
- Name: \(name)
- Address: \(address)
- Type: \(type)
- Description: \(description)
- Tags: \(tags)

\(googlePlacesSection)

Analyze and respond with ONLY a raw JSON object. Do not use markdown, code blocks, or any explanation. Just the JSON:
{"isLegitimate":true,"isSuspicious":false,"suspicionLevel":"low","concerns":[],"reasoning":"explanation here","isAppropriateForQuietSpace":true,"suggestedTags":["quiet","study"],"confidence":0.8,"googlePlaceVerified":true,"recommendedAction":"approve"}

Rules:
- If NO Google match: set isSuspicious=true, suspicionLevel="high"
- Reject nightclubs, bars, loud venues
- Accept libraries, cafes, parks, study spaces
- Flag spam/offensive content
- suspicionLevel must be: "low", "medium", or "high"
- recommendedAction must be: "approve", "reject", or "manual_review"
"""
    }

    private func parseValidationResponse(_ jsonString: String) -> LocationValidationResult {
        var clean = jsonString
        if clean.contains("```json") {
            let parts = clean.components(separatedBy: "```json")
            if parts.count > 1 {
                clean = parts[1].components(separatedBy: "```").first ?? clean
            }
        } else if clean.contains("```") {
            let parts = clean.components(separatedBy: "```")
            if parts.count > 1 {
                clean = parts[1]
            }
        }

        guard let start = clean.firstIndex(of: "{"),
              let end = clean.lastIndex(of: "}") else {
            return makeErrorResult(message: "No JSON found in response", googleVerified: false)
        }
        let slice = String(clean[start...end])

        guard let data = slice.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return makeErrorResult(message: "Failed to parse JSON", googleVerified: false)
        }

        let concerns = (obj["concerns"] as? [String]) ?? []
        let suggested = (obj["suggestedTags"] as? [String]) ?? []
        let isLegitimate = obj["isLegitimate"] as? Bool ?? false
        let isSuspicious = obj["isSuspicious"] as? Bool ?? true

        return LocationValidationResult(
            isLegitimate: isLegitimate,
            isSuspicious: isSuspicious,
            suspicionLevel: obj["suspicionLevel"] as? String ?? "medium",
            concerns: concerns,
            reasoning: obj["reasoning"] as? String ?? "No reasoning provided",
            isAppropriateForQuietSpace: obj["isAppropriateForQuietSpace"] as? Bool ?? true,
            suggestedTags: suggested,
            confidence: obj["confidence"] as? Double ?? 0.5,
            googlePlaceVerified: obj["googlePlaceVerified"] as? Bool ?? false,
            recommendedAction: obj["recommendedAction"] as? String ?? "manual_review",
            isValid: isLegitimate,
            suggestions: suggested
        )
    }

    private func makeErrorResult(message: String, googleVerified: Bool) -> LocationValidationResult {
        LocationValidationResult(
            isLegitimate: false,
            isSuspicious: true,
            suspicionLevel: "medium",
            concerns: ["AI validation failed: \(message)"],
            reasoning: "API Error: \(message) - flagged for manual review",
            isAppropriateForQuietSpace: true,
            suggestedTags: [],
            confidence: 0,
            googlePlaceVerified: googleVerified,
            recommendedAction: "manual_review",
            isValid: false,
            suggestions: []
        )
    }
}
