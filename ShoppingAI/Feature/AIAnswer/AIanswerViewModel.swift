//
//  AIanswerViewModel.swift
//  ShoppingAI
//
//  Created by 김은찬 on 7/12/25.
//

import Foundation

@MainActor
final class AIanswerViewModel: ObservableObject {
    @Published var aiResponse: String = ""
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?

    let products: [Product]

    init(products: [Product]) {
        self.products = products
    }

    func requestRecommendation() async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            isLoading = false
            errorMessage = "요청 URL이 잘못되었습니다."
            return
        }

        let apiKey = Bundle.main.openAIKey
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": Self.systemPrompt],
                ["role": "user", "content": generatePrompt()]
            ],
            "temperature": 0.7
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                let serverMessage = Self.extractErrorMessage(from: data)
                    ?? "HTTP \(httpResponse.statusCode)"
                isLoading = false
                errorMessage = "OpenAI 오류: \(serverMessage)"
                return
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                isLoading = false
                errorMessage = "AI 응답을 해석할 수 없습니다."
                return
            }

            aiResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "네트워크 오류: \(error.localizedDescription)"
        }
    }

    func extractRecommendedProductName() -> String? {
        let lines = aiResponse.components(separatedBy: "\n")
        for line in lines where line.contains("추천–") {
            let cleaned = line
                .replacingOccurrences(of: "*", with: "")
                .trimmingCharacters(in: .whitespaces)

            guard let range = cleaned.range(of: "추천–") else { continue }
            let after = cleaned[range.upperBound...].trimmingCharacters(in: .whitespaces)

            if let nameEnd = after.range(of: "을 구매")?.lowerBound
                ?? after.range(of: "를 구매")?.lowerBound {
                var productName = String(after[..<nameEnd]).trimmingCharacters(in: .whitespaces)
                if productName.hasPrefix("[") && productName.hasSuffix("]") {
                    productName = String(productName.dropFirst().dropLast())
                }
                return productName
            }
        }
        return nil
    }

    func recommendedProduct() -> Product? {
        guard let name = extractRecommendedProductName() else { return nil }
        return products.first { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) == name }
    }

    func makeValidURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let directURL = URL(string: trimmed), directURL.scheme != nil {
            return directURL
        }

        if trimmed.contains("?"),
           let base = trimmed.components(separatedBy: "?").first {
            var components = URLComponents(string: base)
            let queryString = trimmed.components(separatedBy: "?").last ?? ""

            let queryItems = queryString
                .components(separatedBy: "&")
                .compactMap { item -> URLQueryItem? in
                    let pair = item.components(separatedBy: "=")
                    return pair.count == 2 ? URLQueryItem(name: pair[0], value: pair[1]) : nil
                }

            components?.queryItems = queryItems
            return components?.url
        }

        let httpsAdded = "https://" + trimmed
        return URL(string: httpsAdded.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? httpsAdded)
    }

    private func generatePrompt() -> String {
        var result = "다음 \(products.count)개의 상품 중 어떤 것을 먼저 사는 것이 가장 좋은지 추천해줘.\n\n"
        for (index, product) in products.enumerated() {
            result += """
            \(index + 1)번 상품
            - 이름: \(product.name)
            - 가격: \(product.price)
            - 욕구: \(product.purchaseDesire)/10
            - 사용 용도: \(product.usageContext)
            - 특징: \(product.features)
            - URL: \(product.url)

            """
        }

        result += """
        살까말까? 라는 질문에 답해주세요.
        가장 먼저 구매해야 할 제품을 하나만 추천해줘.
        이유도 조목조목 설명해줘.
        형식은 아래처럼 해줘:

        추천– [제품명]을 구매하는 것을 추천합니다.
        이유
        1. ...
        2. ...
        3. ...

        그리고 선택되지 않은 나머지 상품(\(products.count - 1)개)이 왜 우선순위에서 밀리는지도 설명해줘.
        """
        return result
    }

    private static let systemPrompt = """
    당신은 소비자가 어떤 제품을 먼저 구매하면 좋을지 도와주는 AI입니다.
    - 각 상품에 대해 가격, 구매 욕구 수치, 사용 용도, 특징 등 다양한 요소를 모두 종합적으로 고려해 주세요.
    - 단순히 욕구 수치가 높다고 추천하지 말고, 실제 사용 가능성, 활용도, 실용성, 상황 적합성 등을 기준으로 합리적으로 판단해야 합니다.
    - 추천 문장은 다음 형식을 반드시 따르세요: '추천– [제품명]을 구매하는 것을 추천합니다.'
    - 분석 시작 전에는 '살까말까?'라는 질문 문장을 반드시 포함하세요.
    - 추천하는 상품의 이유는 3가지 이상 구체적으로 작성하세요.
    - 선택되지 않은 나머지 상품들도 번호로 표기하고, 각각 왜 추천되지 않았는지 설명해 주세요.
    """

    private static func extractErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else { return nil }
        return message
    }
}
