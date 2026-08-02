import Foundation

class GeminiService {
    static let shared = GeminiService()
    
    // A chave real é injetada pela esteira de CI/CD por segurança.
    private let apiKey = "INJECTED_BY_CI"
    
    // Modelos ativos e compatíveis em ordem de prioridade
    private let models = [
        "gemini-flash-latest",
        "gemini-3.5-flash",
        "gemini-3-flash-preview"
    ]
    
    func generateExercise(instrument: String, technique: String, timeAvailable: Int, isChallengeMode: Bool) async throws -> String {
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY" else {
            throw NSError(domain: "GeminiService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key não configurada. Edite GeminiService.swift."])
        }
        
        let prompt = """
        Atue como um professor de música especialista. O aluno precisa de um exercício de \(instrument) focado na técnica de \(technique).
        Tempo disponível: \(timeAvailable) minutos.
        Modo: \(isChallengeMode ? "Desafio (Alta dificuldade, velocidade rápida, técnicas avançadas)" : "Aquecimento (Dificuldade moderada, foco em precisão)").
        
        Gere uma partitura curta (4 a 8 compassos) no formato AlphaTex (um formato de texto simples para renderização de tablatura).
        O AlphaTex DEVE iniciar com a tab `\\title "Exercício de \(technique)"` e conter a trilha `\\track "Guitar"`.
        Retorne APENAS o código AlphaTex puro, sem markdown, sem explicações, e sem tags de bloco de código (ex: não use ```).
        Exemplo de AlphaTex válido:
        \\title "Aquecimento"
        \\track "Guitarra"
        .
        :4 5.6.7.8 | 8.7.6.5
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 800
            ]
        ]
        
        let httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        var lastError: Error? = nil
        
        // Tentativa nos modelos disponíveis com fallback automático
        for model in models {
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = httpBody
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let errorText = String(data: data, encoding: .utf8) ?? "Erro desconhecido"
                    lastError = NSError(domain: "GeminiService", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Erro na API (\(model)): \(errorText)"])
                    continue
                }
                
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let candidates = json?["candidates"] as? [[String: Any]],
                      let firstCandidate = candidates.first,
                      let content = firstCandidate["content"] as? [String: Any],
                      let parts = content["parts"] as? [[String: Any]],
                      let firstPart = parts.first,
                      let rawText = firstPart["text"] as? String else {
                    lastError = NSError(domain: "GeminiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resposta inválida da API"])
                    continue
                }
                
                // Limpa marcações markdown se a IA colocar ```alphatex ou ```
                var cleanText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanText.contains("```") {
                    let lines = cleanText.components(separatedBy: .newlines)
                    let filteredLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }
                    cleanText = filteredLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                return cleanText
            } catch {
                lastError = error
            }
        }
        
        throw lastError ?? NSError(domain: "GeminiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Não foi possível gerar o exercício com nenhum dos modelos."])
    }
}
