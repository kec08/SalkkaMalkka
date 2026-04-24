# 살까말까 (ShoppingAI)

> **사고 싶은 상품을 등록해 두고, OpenAI에게 "지금 어떤 걸 먼저 사야 할까?"를 물어보는 소비 판단 보조 iOS 앱**

![Image](https://github.com/user-attachments/assets/73dae1cd-8cea-4b25-9d6c-cd9cc7182852)

충동구매가 고민되는 순간, 비교 대상 상품들을 한 화면에 모아 놓고 GPT가 가격·구매 욕구·사용 용도·특징을 종합해 **"추천– [제품명]을 구매하는 것을 추천합니다."** 형식으로 답을 돌려줍니다.

---

## ✨ 주요 기능

| 기능 | 설명 |
|---|---|
| 🛒 상품 등록 | 사진, 카테고리, 이름, 가격, URL, 구매 욕구(0~10), 사용 용도, 특징을 입력 |
| 🖼️ 갤러리 뷰 | 등록한 상품을 카드 형태로 한눈에 확인 |
| ✏️ 편집 모드 | 상품 탭 시 상세 수정, 스와이프로 삭제, 전체 비우기 |
| ✅ AI 비교 대상 선택 | 상품 상세에서 "추가하기" → 우측 하단 Q버튼에 카운트 표시 (2개 이상부터 활성화) |
| 🤖 AI 판단 | OpenAI GPT-4o-mini에게 "살까말까?" 프롬프트를 보내 추천 제품과 이유 3가지를 받음 |
| 🔗 바로 구매 | 추천된 상품의 URL을 Safari에서 바로 열어 구매 페이지 이동 |

---

## 🧱 기술 스택

### 언어 / 플랫폼
- **Swift 5.0**
- **SwiftUI** (선언형 UI)
- **iOS 26.0+** (Deployment Target)
- **iPhone / iPad 지원** (`TARGETED_DEVICE_FAMILY = "1,2"`)

### 주요 프레임워크
- `SwiftUI` — 전체 UI
- `UIKit` — `UIImagePickerController`를 `UIViewControllerRepresentable`로 래핑해 사진 선택 구현 ([ImagePicker.swift](ShoppingAI/Feature/ImagePicker.swift))
- `Foundation` / `URLSession` — OpenAI REST API 호출
- `PropertyListSerialization` — `Secretss.plist`에서 API Key 로드

### 외부 API
- **OpenAI Chat Completions API**
  - 엔드포인트: `https://api.openai.com/v1/chat/completions`
  - 모델: `gpt-4o-mini`
  - `temperature: 0.7`

### 빌드 환경
- **Xcode 16+** (iOS 26 SDK 지원 버전)
- 외부 패키지 매니저 없음 — **순수 Swift Package / CocoaPods 없이** 동작

---

## 📂 프로젝트 구조

```
ShoppingAIApp/
├── ShoppingAI.xcodeproj/          # Xcode 프로젝트
├── ShoppingAI/                    # 앱 소스 루트
│   ├── Info.plist                 # NSPhotoLibraryUsageDescription 포함
│   ├── Feature/
│   │   ├── App/
│   │   │   ├── RootView.swift         # @main 진입 (MainView 로드)
│   │   │   └── ShoppingApp.swift
│   │   ├── Main/
│   │   │   ├── MainView.swift         # 갤러리, 편집/추가, Q버튼, UserDefaults 영속화
│   │   │   ├── MainModel.swift
│   │   │   └── MainViewModel.swift
│   │   ├── AddProduct/
│   │   │   ├── AddProductView.swift   # 상품 추가 폼 + UnderlineTextField
│   │   │   └── AddProductViewModel.swift
│   │   ├── ProductDetail/
│   │   │   ├── ProductDetailView.swift # 상세/수정/삭제/구매링크
│   │   │   └── ProductDetailViewModel.swift
│   │   ├── AIAnswer/
│   │   │   ├── AIanswerView.swift      # 상태 구독 + 렌더링 (얇은 뷰)
│   │   │   └── AIanswerViewModel.swift # OpenAI 요청/파싱/에러 처리
│   │   ├── ImagePicker.swift          # UIImagePickerController 래퍼
│   │   └── Product.swift              # 핵심 도메인 모델 (Codable)
│   ├── Model/
│   │   └── Core/
│   │       └── Extension/
│   │           ├── Bundle+Secrets.swift   # Secretss.plist → OPENAI_API_KEY
│   │           └── Color+Extensions.swift # customRed/customBlack/...
│   └── Assets.xcassets/
│       ├── Color/                     # customRed, customBlack 등 컬러 셋
│       ├── Main_Q_Buttom.imageset     # 우측 하단 Q 버튼 이미지
│       └── AppIcon.appiconset
├── ShoppingAITests/
└── ShoppingAIUITests/
```

---

## 🚀 시작하기

### 1. 요구사항

- macOS (Apple Silicon 권장)
- **Xcode 16 이상** (iOS 26 SDK)
- OpenAI API Key ([platform.openai.com](https://platform.openai.com/api-keys))
- iOS 26.0 이상 실기기 또는 시뮬레이터

### 2. 클론

```bash
git clone <this-repo-url>
cd ShoppingAIApp
open ShoppingAI.xcodeproj
```

### 3. OpenAI API Key 등록 (필수)

앱은 [Bundle+Secrets.swift](ShoppingAI/Model/Core/Extension/Bundle+Secrets.swift)에서 `Secretss.plist` 를 읽어 키를 로드합니다. 파일이 없으면 런타임에 `fatalError`가 발생합니다.

1. Xcode의 `ShoppingAI` 폴더에 새 Property List 파일 생성
   - `File > New > File... > Property List`
   - 이름: **`Secretss.plist`** (s 두 개 주의)
2. 아래 내용을 추가
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <plist version="1.0">
   <dict>
       <key>OPENAI_API_KEY</key>
       <string>sk-xxxxxxxxxxxxxxxxxxxxxxxx</string>
   </dict>
   </plist>
   ```
3. **Target Membership**에서 `ShoppingAI` 체크 확인
4. `.gitignore`에 이미 `Secretss.plist`가 포함되어 있어 커밋 시 자동으로 제외됩니다.

### 4. 빌드 & 실행

Xcode에서 스킴을 `ShoppingAI`로 선택하고 ▶️ Run.
사진 라이브러리 접근 권한(`NSPhotoLibraryUsageDescription`)은 이미 `Info.plist`에 등록되어 있습니다.

---

## 🧭 사용 방법

1. **추가** — 갤러리 우상단 `추가` 버튼 → 사진·이름·가격·URL·구매 욕구·사용 용도·특징 입력 → `추가하기`
2. **상세 확인** — 카드 탭 → 이미지·가격·링크 확인, `추가하기` 버튼으로 AI 비교 대상에 포함
3. **편집/삭제** — 우상단 `편집` → 카드 탭(상세에서 삭제) 또는 스와이프 삭제, `비우기`로 AI 대상 전체 초기화
4. **AI에게 물어보기** — AI 대상이 **2개 이상**이면 우측 하단 **Q 버튼** 활성화 → 탭
5. **결과 확인** — `로딩 중 → AI 답변` 표시. "추천– [제품명]" 줄에서 제품명을 정규식으로 추출
6. **바로 구매** — 하단 `구매하기` → 추천 상품의 URL을 Safari로 오픈 (스킴 없으면 `https://` 자동 추가)

---

## 🔌 AI 요청 흐름

[AIanswerViewModel.swift](ShoppingAI/Feature/AIAnswer/AIanswerViewModel.swift)의 `requestRecommendation()`이 네트워크·파싱·에러 처리를 담당하고, [AIanswerView.swift](ShoppingAI/Feature/AIAnswer/AIanswerView.swift)는 상태만 구독하는 얇은 뷰입니다.

```
사용자 Q버튼 탭
     ↓
View: .task { await viewModel.requestRecommendation() }
     ↓
ViewModel: generatePrompt()
  → "N개의 상품 중 …" + 각 상품의 이름/가격/욕구/용도/특징/URL
     ↓
POST https://api.openai.com/v1/chat/completions   (timeout 30s)
  model: gpt-4o-mini
  messages: [system(정해진 답변 형식), user(프롬프트)]
     ↓
URLSession.shared.data(for:) — async/await
  - HTTP non-2xx      → errorMessage = "OpenAI 오류: …"
  - JSON 파싱 실패    → errorMessage = "AI 응답을 해석할 수 없습니다."
  - 네트워크 throw    → errorMessage = "네트워크 오류: …"
     ↓
aiResponse 에 content 저장 → SwiftUI가 answerView 재렌더
     ↓
"구매하기" 탭 시 viewModel.recommendedProduct() 로 매칭 제품 조회
→ makeValidURL() 로 URL 정규화
→ UIApplication.shared.open()
```

에러 발생 시 전용 `errorView`에서 메시지와 **다시 시도** 버튼을 보여주고, `구매하기` 버튼은 비활성화됩니다.

### 시스템 프롬프트 요약

- 가격·욕구·용도·특징을 **종합적으로** 고려 (욕구 수치만으로 판단 금지)
- 추천 형식 고정: `추천– [제품명]을 구매하는 것을 추천합니다.`
- 앞에 `살까말까?` 헤더 필수
- 이유 3개 이상 + 나머지 상품의 탈락 이유 설명

---

## 📄 라이선스

본 저장소에는 별도 라이선스 파일이 없습니다. 사용/배포 전 작성자에게 문의하세요.

## 🙋 만든 사람

- 김은찬 ([@kimeunchan](https://github.com/kec08))
