import Foundation

// MARK: - Serviço de IA Gemini

final class GeminiService {
    static let shared = GeminiService()
    
    // Chave injetada pela CI/CD — nunca inclua valores reais no código
    private let apiKey = "INJECTED_BY_CI"
    
    // Modelos em ordem de prioridade (mais rápido primeiro)
    private let models = ["gemini-2.0-flash", "gemini-1.5-flash"]
    
    private init() {}
    
    // MARK: - Geração de Exercício AlphaTex
    
    func generateExercise(instrument: String, technique: String, timeAvailable: Int, isChallengeMode: Bool) async throws -> String {
        guard isAPIKeyValid() else {
            return buildFallbackExercise(technique: technique)
        }
        let prompt = """
        Atue como professor de música. O aluno precisa de um exercício para \(instrument) focado em \(technique).
        Tempo: \(timeAvailable) minutos. Modo: \(isChallengeMode ? "Desafio (rápido)" : "Aquecimento (moderado)").
        Responda APENAS com AlphaTex puro (sem markdown):
        \\title "Exercício de \(technique)"
        \\tempo 100
        .
        :8 5.6 7.6 8.6 7.6 5.5 7.5 8.5 7.5 | 5.4 7.4 8.4 7.4 5.3 7.3 8.3 7.3 | 5.2 7.2 8.2 7.2 5.1 7.1 8.1 7.1 | 8.1 7.1 5.1 7.1 8.2 7.2 5.2 7.2
        Gere exatamente 4 compassos reais de \(technique). Formato: traste.corda (ex: 5.6). Separador de compasso: |
        """
        return try await callGemini(prompt: prompt, maxTokens: 2048, temperature: 0.2) { rawText in
            var clean = self.stripMarkdownFences(rawText)
            if !clean.contains(".") && !clean.contains(":") {
                clean = self.buildFallbackExercise(technique: technique)
            }
            return clean
        }
    }
    
    // MARK: - Dicas de Aula (Real via IA)
    
    func generateLessonTips(songTitle: String, artist: String, difficulty: String, bpm: Int) async throws -> [String] {
        guard isAPIKeyValid() else {
            return fallbackLessonTips(for: difficulty)
        }
        let prompt = """
        Você é professor de guitarra. O aluno vai tocar "\(songTitle)" de \(artist).
        Dificuldade: \(difficulty). BPM: \(bpm).
        Gere EXATAMENTE 3 dicas práticas e específicas para ESSA música (mencione técnicas reais usadas nela).
        Retorne APENAS um array JSON: ["Dica 1...", "Dica 2...", "Dica 3..."]
        Sem markdown, sem texto extra — apenas o JSON.
        """
        return try await callGemini(prompt: prompt, maxTokens: 512, temperature: 0.4) { rawText in
            let clean = self.stripMarkdownFences(rawText)
            if let data = clean.data(using: .utf8),
               let tips = try? JSONDecoder().decode([String].self, from: data),
               tips.count >= 3 {
                return Array(tips.prefix(3))
            }
            return self.fallbackLessonTips(for: difficulty)
        }
    }
    
    // MARK: - Passos Progressivos para Aprender Música
    
    func generateSongSteps(songTitle: String, instrument: String) async throws -> [AISongStep] {
        guard isAPIKeyValid() else {
            throw NSError(domain: "GeminiService", code: 401,
                         userInfo: [NSLocalizedDescriptionKey: "API Key não configurada."])
        }
        let prompt = """
        Professor de música: transcreva o riff/melodia REAL de "\(songTitle)" para \(instrument) em AlphaTex.
        NÃO use notas genéricas. Use a sequência correta de trastes e cordas da música real.
        Referências (traste.corda):
        - Smoke on the Water: :4 0.6 3.6 5.6 | 0.6 3.6 6.6 5.6 | 0.6 3.6 5.6 | 3.6 0.6
        - Seven Nation Army: :4 7.5 7.5 10.5 7.5 5.5 3.5 2.5
        Divida em 3 partes progressivas (lento, médio, velocidade real).
        Retorne APENAS array JSON com campos: "stepName", "description", "bpm" (int), "alphaTex" (string).
        """
        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": ["temperature": 0.3, "maxOutputTokens": 4096]
        ]
        let httpBody = try JSONSerialization.data(withJSONObject: body)
        var lastError: Error?
        
        for model in models {
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = httpBody
            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
                    lastError = NSError(domain: "GeminiService", code: (resp as? HTTPURLResponse)?.statusCode ?? 500,
                                       userInfo: [NSLocalizedDescriptionKey: "HTTP error em \(model)"])
                    continue
                }
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard var rawText = extractText(from: json) else { continue }
                rawText = stripMarkdownFences(rawText)
                guard let jsonData = rawText.data(using: .utf8) else { continue }
                return try JSONDecoder().decode([AISongStep].self, from: jsonData)
            } catch { lastError = error }
        }
        throw lastError ?? NSError(domain: "GeminiService", code: 500,
                                   userInfo: [NSLocalizedDescriptionKey: "Não foi possível gerar passos."])
    }
    
    // MARK: - Helpers Privados
    
    private func callGemini<T>(prompt: String, maxTokens: Int, temperature: Double, transform: @escaping (String) throws -> T) async throws -> T {
        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": ["temperature": temperature, "maxOutputTokens": maxTokens]
        ]
        let httpBody = try JSONSerialization.data(withJSONObject: body)
        var lastError: Error?
        
        for model in models {
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = httpBody
            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
                    lastError = NSError(domain: "GeminiService", code: (resp as? HTTPURLResponse)?.statusCode ?? 500,
                                       userInfo: [NSLocalizedDescriptionKey: "HTTP error"])
                    continue
                }
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let rawText = extractText(from: json) else { continue }
                return try transform(rawText)
            } catch { lastError = error }
        }
        throw lastError ?? NSError(domain: "GeminiService", code: 500,
                                   userInfo: [NSLocalizedDescriptionKey: "Falha em todos os modelos."])
    }
    
    private func extractText(from json: [String: Any]?) -> String? {
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else { return nil }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func stripMarkdownFences(_ text: String) -> String {
        guard text.contains("```") else { return text }
        return text.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func isAPIKeyValid() -> Bool {
        return !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY" && apiKey != "INJECTED_BY_CI"
    }
    
    private func buildFallbackExercise(technique: String) -> String {
        return """
        \\title "Exercício: \(technique)"
        \\tempo 100
        .
        :8 5.6 7.6 8.6 7.6 5.5 7.5 8.5 7.5 | 5.4 7.4 8.4 7.4 5.3 7.3 8.3 7.3 | 5.2 7.2 8.2 7.2 5.1 7.1 8.1 7.1 | 8.1 7.1 5.1 7.1 8.2 7.2 5.2 7.2
        """
    }
    
    private func fallbackLessonTips(for difficulty: String) -> [String] {
        return fallbackTipsPublic(for: difficulty)
    }
    
    /// Exposto para uso em Views como fallback gracioso quando a API não está disponível
    func fallbackTipsPublic(for difficulty: String) -> [String] {
        switch difficulty {
        case "Insano":
            return [
                "Esta música exige palhetada alternada rápida. Aqueça o pulso direito por 5 minutos antes.",
                "Pratique os riffs a 50% da velocidade até memorizar todos os trastes, depois acelere gradualmente.",
                "Use o Speed Trainer: suba 5 BPM a cada 3 repetições perfeitas consecutivas."
            ]
        case "Difícil":
            return [
                "Divida a música em seções de 4 compassos e domine cada uma antes de juntar.",
                "Foque na limpeza: cada nota deve soar clara sem buzz das cordas adjacentes.",
                "Use o loop A-B no player para repetir partes difíceis em isolamento."
            ]
        default:
            return [
                "Comece devagar e foque em tocar cada nota com clareza antes de pensar em velocidade.",
                "Use o metrônomo incluído para manter o tempo constante desde o início.",
                "Divida em loops de 4 compassos para memorizar mais rápido e com menos frustração."
            ]
        }
    }
}

// MARK: - Modelo de Passo de Aula com ID Estável

struct AISongStep: Codable, Identifiable {
    /// UUID estável — armazenado, não computado (evita breaks no ForEach do SwiftUI)
    let id: UUID
    let stepName: String
    let description: String
    let bpm: Int
    let alphaTex: String
    
    enum CodingKeys: String, CodingKey {
        case stepName, description, bpm, alphaTex
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.stepName = try c.decode(String.self, forKey: .stepName)
        self.description = try c.decode(String.self, forKey: .description)
        self.bpm = try c.decode(Int.self, forKey: .bpm)
        self.alphaTex = try c.decode(String.self, forKey: .alphaTex)
    }
    
    init(stepName: String, description: String, bpm: Int, alphaTex: String) {
        self.id = UUID()
        self.stepName = stepName
        self.description = description
        self.bpm = bpm
        self.alphaTex = alphaTex
    }
}
