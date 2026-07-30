import Foundation

class GeminiService {
    static let shared = GeminiService()
    
    // ATENÇÃO: Em produção, NUNCA deixe a API Key hardcoded no app. Use Firebase Remote Config ou Cloud Functions.
    // Para fins de teste e protótipo, substitua pela sua chave do Google AI Studio.
    private let apiKey = "YOUR_GEMINI_API_KEY" 
    
    private let modelURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent"
    
    func generateExercise(instrument: String, technique: String, timeAvailable: Int, isChallengeMode: Bool) async throws -> String {
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY" else {
            throw NSError(domain: "GeminiService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key não configurada. Edite GeminiService.swift."])
        }
        
        let url = URL(string: "\(modelURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Erro desconhecido"
            throw NSError(domain: "GeminiService", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Erro na API: \(errorText)"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw NSError(domain: "GeminiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resposta inválida da API"])
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
