import SwiftUI

struct AddProductView: View {
    @State private var productName = ""
    @State private var productPrice = ""
    @State private var productURL = ""
    @State private var purchaseDesire: Double = 5.0
    @State private var usageContext = ""
    @State private var productFeatures = ""
    @State private var category = ""
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false

    @FocusState private var focusedField: Field?

    var addProduct: (Product) -> Void
    var onDismiss: () -> Void

    enum Field {
        case name, category, price, url, usage, features
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    imagePickerSection

                    textFieldsSection1

                    purchaseDesireSlider

                    textFieldsSection2

                    actionButtons
                }
                .padding()
                .background(Color.white)
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("상품 추가")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.customBlack)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        onDismiss()
                    }
                }
            }
        }
    }

    private var imagePickerSection: some View {
        ZStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 240)
                    .clipped()
                    .cornerRadius(10)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)

                    Text("사진 추가")
                        .foregroundColor(.customRed)
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(.top, -10)
        .padding(.bottom, 20)
        .onTapGesture {
            isImagePickerPresented = true
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage, isPresented: $isImagePickerPresented)
        }
    }

    private var textFieldsSection1: some View {
        VStack(spacing: 16) {
            UnderlineTextField(title: "카테고리", text: $category, isFocused: focusedField == .category)
                .focused($focusedField, equals: .category)

            UnderlineTextField(title: "상품 이름", text: $productName, isFocused: focusedField == .name)
                .focused($focusedField, equals: .name)

            UnderlineTextField(title: "가격 (원)", text: $productPrice, isFocused: focusedField == .price, keyboardType: .numberPad)
                .focused($focusedField, equals: .price)

            UnderlineTextField(title: "URL", text: $productURL, isFocused: focusedField == .url, keyboardType: .URL)
                .focused($focusedField, equals: .url)
        }
    }

    private var purchaseDesireSlider: some View {
        VStack(spacing: 5) {
            HStack {
                Spacer()
                Text("구매 욕구: \(Int(purchaseDesire)) / 10")
                    .font(.system(size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(.customBlack)
                Spacer()
            }

            Slider(value: $purchaseDesire, in: 0...10, step: 1)
                .accentColor(.customRed)
        }
        .padding(.top, 10)
    }

    private var textFieldsSection2: some View {
        VStack(spacing: 16) {
            UnderlineTextField(title: "사용 용도 및 상황", text: $usageContext, isFocused: focusedField == .usage)
                .focused($focusedField, equals: .usage)

            UnderlineTextField(title: "상품 특징", text: $productFeatures, isFocused: focusedField == .features)
                .focused($focusedField, equals: .features)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button("취소하기") {
                onDismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .foregroundColor(.gray)
            .fontWeight(.bold)

            Button("추가하기") {
                guard !productName.isEmpty, !productPrice.isEmpty else { return }

                let trimmedURL = productURL.trimmingCharacters(in: .whitespacesAndNewlines)

                let newProduct = Product(
                    id: UUID(),
                    imageData: selectedImage?.jpegData(compressionQuality: 0.8),
                    name: productName,
                    price: productPrice,
                    url: trimmedURL,
                    purchaseDesire: Int(purchaseDesire),
                    usageContext: usageContext,
                    features: productFeatures,
                    category: category
                )
                addProduct(newProduct)
                onDismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.customRed)
            .foregroundColor(.white)
            .cornerRadius(10)
            .fontWeight(.bold)
        }
        .padding(.top, 20)
    }
}

struct UnderlineTextField: View {
    var title: String
    @Binding var text: String
    var isFocused: Bool
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .foregroundColor(.gray)
                .font(.system(size: 16))

            TextField("", text: $text)
                .keyboardType(keyboardType)
                .font(.system(size: 18))
                .foregroundColor(.customBlack)
                .padding(.vertical, 4)

            Rectangle()
                .frame(height: isFocused ? 2 : 1)
                .foregroundColor(isFocused ? .customRed : .gray.opacity(0.5))
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

