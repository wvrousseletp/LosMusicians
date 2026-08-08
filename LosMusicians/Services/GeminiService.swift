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
            throw NSError(domain: "GeminiService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key não configurada."])
        }
        
        let prompt = """
        Atue como um professor de música especialista. O aluno precisa de um exercício para \(instrument) focado na técnica de \(technique).
        Tempo disponível: \(timeAvailable) minutos.
        Modo: \(isChallengeMode ? "Desafio (Alta dificuldade, padrões rápidos)" : "Aquecimento (Dificuldade moderada, foco em precisão)").
        
        Você DEVE responder EXCLUSIVAMENTE com código AlphaTex compatível com AlphaTab.
        Formato obrigatório estrito:
        \\title "Exercício de \(technique)"
        \\tempo 100
        .
        :8 5.6 7.6 8.6 7.6 5.5 7.5 8.5 7.5 | 5.4 7.4 8.4 7.4 5.3 7.3 8.3 7.3 | 5.2 7.2 8.2 7.2 5.1 7.1 8.1 7.1 | 8.1 7.1 5.1 7.1 8.2 7.2 5.2 7.2
        
        Regras:
        1. Inicie com \\title e \\tempo.
        2. Coloque um ponto "." sozinho na linha seguinte.
        3. Notas no formato traste.corda (ex: 5.6 significa traste 5 na corda 6).
        4. Use :8 para colcheias ou :4 para semínimas antes dos grupos de notas.
        5. Separe os compassos usando a barra vertical "|".
        6. Gere exatamente 4 compassos completos.
        7. Não use markdown, crases ou qualquer texto explicativo. Retorne apenas o código AlphaTex puro.
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
                "temperature": 0.2,
                "maxOutputTokens": 2048
            ]
        ]
        
        let httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        var lastError: Error? = nil
        
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
                
                // Limpeza e higienização rigorosa do AlphaTex
                var cleanText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanText.contains("```") {
                    let lines = cleanText.components(separatedBy: .newlines)
                    let filteredLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }
                    cleanText = filteredLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // Valida se o texto contém estrutura mínima de AlphaTex
                if !cleanText.contains(".") && !cleanText.contains(":") {
                    cleanText = """
                    \\title "\(technique)"
                    \\tempo 100
                    .
                    :8 5.6 7.6 8.6 7.6 5.5 7.5 8.5 7.5 | 5.4 7.4 8.4 7.4 5.3 7.3 8.3 7.3 | 5.2 7.2 8.2 7.2 5.1 7.1 8.1 7.1 | 8.1 7.1 5.1 7.1 8.2 7.2 5.2 7.2
                    """
                }
                
                return cleanText
            } catch {
                lastError = error
            }
        }
        
        throw lastError ?? NSError(domain: "GeminiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Não foi possível gerar o exercício com nenhum dos modelos."])
    }
    
    func generateSongSteps(songTitle: String, instrument: String) async throws -> [AISongStep] {
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY" else {
            throw NSError(domain: "GeminiService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key não configurada."])
        }
        
        let prompt = """
        Atue como um professor de música especialista. O aluno quer aprender a música/riff: "\(songTitle)" no instrumento "\(instrument)".
        Divida o aprendizado dessa música em exatamente 3 partes/passos de aprendizado progressivos:
        Parte 1: Ritmo/Base Lento (Velocidade reduzida para pegar os movimentos básicos).
        Parte 2: Padrão Intermediário (Velocidade média, focado em precisão das notas).
        Parte 3: Velocidade Real (Andamento original, tocando no ritmo correto).
        
        Forneça a tablatura simplificada da música para cada parte no formato AlphaTex compatível com AlphaTab.
        Retorne a resposta EXCLUSIVAMENTE como um array JSON válido de objetos com os campos: "stepName", "description", "bpm" (inteiro) e "alphaTex" (string com escapes de quebra de linha corretos).
        Não use crases de markdown (```json), tags HTML ou qualquer texto explicativo. Retorne apenas o JSON bruto de forma que possa ser analisado por um JSONDecoder em Swift.
        
        Regras para o AlphaTex em cada parte:
        - Inicie com \\\\title \\"Nome\\" e \\\\tempo BPM.
        - Coloque um ponto "." isolado na linha seguinte.
        - Use notas no formato traste.corda (ex: 5.6).
        - Separe os compassos usando a barra vertical "|".
        - Use :8 para colcheias antes dos grupos de notas.
        - Gere exatamente 2 ou 4 compassos completos da música real (ou o mais próximo possível simplificado).
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
                "temperature": 0.3,
                "maxOutputTokens": 4096
            ]
        ]
        
        let httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        var lastError: Error? = nil
        
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
                      var rawText = firstPart["text"] as? String else {
                    lastError = NSError(domain: "GeminiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resposta inválida da API"])
                    continue
                }
                
                // Limpeza rigorosa de markdown de código
                rawText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
                if rawText.contains("```") {
                    let lines = rawText.components(separatedBy: .newlines)
                    let filteredLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }
                    rawText = filteredLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                guard let jsonData = rawText.data(using: .utf8) else {
                    continue
                }
                
                let steps = try JSONDecoder().decode([AISongStep].self, from: jsonData)
                return steps
            } catch {
                lastError = error
            }
        }
        
        throw lastError ?? NSError(domain: "GeminiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Não foi possível gerar os passos do treino com nenhum dos modelos."])
    }
}

struct AISongStep: Codable, Identifiable {
    var id: UUID { UUID() }
    let stepName: String
    let description: String
    let bpm: Int
    let alphaTex: String
    
    enum CodingKeys: String, CodingKey {
        case stepName, description, bpm, alphaTex
    }
}

