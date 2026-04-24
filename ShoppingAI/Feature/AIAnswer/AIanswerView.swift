import SwiftUI

struct AIanswerView: View {
    @StateObject private var viewModel: AIanswerViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showInvalidURLAlert = false

    init(products: [Product]) {
        _viewModel = StateObject(wrappedValue: AIanswerViewModel(products: products))
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else {
                        answerView
                    }
                }
                .padding()
            }

            actionButtons
                .padding()
                .alert("유효하지 않은 URL입니다", isPresented: $showInvalidURLAlert) {
                    Button("확인", role: .cancel) {}
                }
        }
        .background(Color.white.ignoresSafeArea())
        .task {
            await viewModel.requestRecommendation()
        }
    }

    // MARK: - 로딩 뷰

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .customRed))
                .scaleEffect(1.5)
            Text("AI가 상품을 분석 중입니다...")
                .font(.body)
                .foregroundColor(.gray)
            Text("잠시만 기다려 주세요")
                .font(.callout)
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.top, 80)
    }

    // MARK: - 에러 뷰

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundColor(.customRed)

            Text("AI 분석에 실패했어요")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)

            Text(message)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button("다시 시도") {
                Task { await viewModel.requestRecommendation() }
            }
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.customRed)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.top, 60)
    }

    // MARK: - 답변 뷰

    private var answerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI 답변")
                .font(.title3)
                .bold()
                .padding(.top, 18)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.customBlack)

            ForEach(viewModel.aiResponse.components(separatedBy: "\n"), id: \.self) { line in
                let trimmed = line
                    .replacingOccurrences(of: "*", with: "")
                    .trimmingCharacters(in: .whitespaces)

                if trimmed == "살까말까?" {
                    Text(trimmed)
                        .font(.headline)
                        .bold()
                } else if trimmed.contains("추천–") {
                    Text(trimmed)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.customRed)
                } else if trimmed.range(of: #"^\d+\."#, options: .regularExpression) != nil {
                    Text(trimmed)
                        .font(.body)
                        .foregroundColor(.black)
                } else if trimmed.hasPrefix("2번 상품") || trimmed.hasPrefix("3번 상품") {
                    Text(trimmed)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                } else {
                    Text(trimmed)
                        .font(.body)
                        .foregroundColor(.black)
                }
            }
        }
    }

    // MARK: - 하단 버튼

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("뒤로가기")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.gray)
                    .cornerRadius(10)
                    .fontWeight(.bold)
            }

            Button(action: {
                guard let product = viewModel.recommendedProduct(),
                      let url = viewModel.makeValidURL(from: product.url) else {
                    showInvalidURLAlert = true
                    return
                }

                UIApplication.shared.open(url, options: [:]) { success in
                    if !success {
                        showInvalidURLAlert = true
                    }
                }
            }) {
                Text("구매하기")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.customRed)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .fontWeight(.bold)
            }
            .disabled(viewModel.isLoading || viewModel.errorMessage != nil)
        }
    }
}
