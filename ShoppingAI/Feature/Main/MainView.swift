import SwiftUI

struct MainView: View {
    private static let storageKey = "savedProducts"

    @State private var products: [Product] = MainView.loadProducts()
    @State private var isShowingAddProduct = false
    @State private var productForAdd: Product? = nil
    @State private var productForEdit: Product? = nil
    @State private var aiTargetProducts: [Product] = []
    @State private var isShowingAIAnswer = false
    @State private var isShowingClearAlert = false
    @State private var editMode: EditMode = .inactive

    private static func loadProducts() -> [Product] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([Product].self, from: data)) ?? []
    }

    private static func saveProducts(_ products: [Product]) {
        if let data = try? JSONEncoder().encode(products) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    headerView

                    if products.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(products) { product in
                                    productCard(product)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if editMode == .active {
                                                productForEdit = product
                                            } else {
                                                productForAdd = product
                                            }
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            if editMode == .active {
                                                Button(role: .destructive) {
                                                    products.removeAll { $0.id == product.id }
                                                    aiTargetProducts.removeAll { $0.id == product.id }
                                                } label: {
                                                    Label("삭제", systemImage: "trash")
                                                }
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 120)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .background(Color.white.ignoresSafeArea())
                .environment(\.editMode, $editMode)

                qButtonView
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
            }
            .sheet(isPresented: $isShowingAddProduct) {
                AddProductView(addProduct: { newProduct in
                    if !products.contains(where: { $0.id == newProduct.id }) {
                        products.append(newProduct)
                    }
                }, onDismiss: {
                    isShowingAddProduct = false
                })
            }
            .sheet(item: $productForAdd) { product in
                ProductDetailView(
                    product: product,
                    isEditing: false,
                    onAdd: {
                        if !aiTargetProducts.contains(where: { $0.id == product.id }) {
                            aiTargetProducts.append(product)
                        }
                        productForAdd = nil
                    }
                )
            }
            .sheet(item: $productForEdit) { product in
                ProductDetailView(
                    product: product,
                    isEditing: true,
                    onDelete: {
                        products.removeAll { $0.id == product.id }
                        aiTargetProducts.removeAll { $0.id == product.id }
                        productForEdit = nil
                        editMode = .inactive
                    }
                )
            }
            .alert("선택한 AI 대상 상품을 모두 비우시겠습니까?", isPresented: $isShowingClearAlert) {
                Button("취소", role: .cancel) {}
                Button("비우기", role: .destructive) {
                    aiTargetProducts.removeAll()
                }
            }
            .onChange(of: products) { _, newValue in
                MainView.saveProducts(newValue)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("갤러리")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)

            Spacer()

            HStack(spacing: 24) {
                Button("비우기") {
                    isShowingClearAlert = true
                }
                .foregroundColor(.red)

                Button(editMode == .active ? "완료" : "편집") {
                    withAnimation {
                        editMode = (editMode == .active ? .inactive : .active)
                    }
                }
                .foregroundColor(.gray)

                Button("추가") {
                    isShowingAddProduct = true
                }
                .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    private var emptyStateView: some View {
        VStack {
            Spacer().frame(height: 200)

            VStack {
                Image(systemName: "cart")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
                    .padding(.bottom, 15)

                Text("아직 상품이 없습니다\n상품을 추가 해보세요!")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    private var qButtonView: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                isShowingAIAnswer = true
            }) {
                Image("Main_Q_Buttom")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .shadow(radius: 4)
                    .opacity(aiTargetProducts.count >= 2 ? 1.0 : 0.5)
            }
            .disabled(aiTargetProducts.count < 2)
            .sheet(isPresented: $isShowingAIAnswer) {
                AIanswerView(products: aiTargetProducts)
            }

            if aiTargetProducts.count > 0 {
                Text("\(aiTargetProducts.count)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black)
                    .clipShape(Circle())
                    .offset(x: 10, y: -10)
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        HStack(spacing: 15) {
            if let image = product.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(product.category)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                Text(product.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(2)

                Text("₩ \(product.price)")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .fontWeight(.bold)

                Text("욕구: \(product.purchaseDesire) / 10")
                    .font(.system(size: 14))
                    .foregroundColor(.customRed)
                    .fontWeight(.bold)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

