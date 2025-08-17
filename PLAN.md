# iPlayground iOS App 功能規劃

## 官方消息功能

### 即時資訊
- 活動開始前的倒數計時
- 當前的議程
- 下一個議程

### 議程
- 2 天活動的時間列表
- 展開議程資料與講者個人檔案
- 搜尋功能（純文字）

### 講者與工作人員介紹
- 講者個人檔案（照片、簡介、社群連結）
- 工作人員團隊介紹
- 分類顯示（講者/主辦/志工等）

### 地點
- 主要場地、After Party 場地資訊
- 地點資訊與打開 Apple Maps / Google Maps 的 deep link
- 內建顯示 Apple Maps
  - Look Around

### 重要連結
- 官網
- 電子報
- YouTube 頻道
- Discord server
- App 開源專案網址

### 官方社群帳號

- Twitter
- Threads
- Mastodon
- Facebook

### 贊助商介紹
- 分級顯示（金銀銅等）
- 互動功能（網站連結）

### Flitto 翻譯專屬頁面
- 如果有整合 Flitto SDK 的話

### Bonus: iOS Widget

- 可以把「即時資訊」的資訊放在 Widget

## 個人化功能

### 標記議程

- 我喜歡的議程
- 行前通知

### 自我介紹活動交換資料
- 參與者互動與資料交換
- 隱私設定
- QR code 掃描功能

## 技術考量

- 技術與實現已決定使用 SwiftUI + TCA
- 官方固定資料來源使用 iplayground/SessionData package，支援離線快取與線上更新

## 使用者體驗考量

- 直觀的導航設計
- 即時資訊更新
- 個人化設定
- 社群互動功能

## 資訊架構

以 TabView 為主，分成以下幾個 Tab:

1. 當前即時資訊 + 議程。如何呈現還需要思考
2. 人員 + 贊助商列表
3. Flitto SDK
4. 個人化功能：交換自我介紹名片機制
5. 關於頁面

### 資訊架構圖（View/Feature 命名對應）

iPlayground App 2025
- AppView & AppFeature (主要 App 結構)
  - TabView 主導航
    - 📅 Tab 1: Today & TodayFeature
      - Now Section
        - 即時資訊區塊 
          - ⏰ 倒數計時 (CountdownView)
          - 📍 當前議程 (CurrentSessionView)
          - ⏭️ 下個議程 (NextSessionView)
      - Sessions Section
        - 議程列表
          - 📋 兩天列表 (SessionListView)
          - 📄 詳細頁面 (SessionDetailView & SessionDetailFeature)
          - 🔍 文字搜尋 (SearchView & SearchFeature)
          - ⭐ 標記議程 (FavoriteButton)
    - 👥 Tab 2: Sponsors, Speakers, & Staff
      - PeopleView & PeopleFeature
        - 講者介紹
          - SpeakerListView & SpeakerListFeature
          - SpeakerDetailView & SpeakerDetailFeature
            - 📸 個人檔案
            - 🔗 社群連結
        - 工作人員
          - StaffListView & StaffListFeature
            - 👨‍💻 講者
            - 🎯 主辦
            - 🙋‍♀️ 志工
        - 贊助商
          - SponsorListView & SponsorListFeature
            - 🥇 金級
            - 🥈 銀級
            - 🥉 銅級
            - 🔗 網站連結
    - 🌐 Tab 3: Flitto (Live Translation)
      - FlittoView & FlittoFeature
        - 翻譯頁面 (待確認)
    - 👤 Tab 4: 個人功能
      - ProfileView & ProfileFeature
        - QR 交換
          - QRScannerView & QRScannerFeature
            - 📱 掃描功能
          - QRGeneratorView & QRGeneratorFeature
            - 🏷️ 名片產生
          - PrivacySettingsView & PrivacySettingsFeature
            - 🔒 隱私設定
        - 我的議程
          - MyScheduleView & MyScheduleFeature
            - ❤️ 喜愛議程
            - 🔔 通知設定
    - ℹ️ Tab 5: 關於
      - AboutView & AboutFeature
        - 地點資訊
          - VenueView & VenueFeature
            - 🏢 主要場地
            - 🎉 After Party
            - 🗺️ Apple Maps
            - 👀 Look Around
        - 重要連結
          - LinksView & LinksFeature
            - 🌐 官網
            - 📧 電子報
            - 📺 YouTube
            - 💬 Discord
            - 💻 開源專案
        - 社群帳號
          - SocialLinksView
            - 🐦 Twitter
            - 🧵 Threads
            - 🐘 Mastodon
            - 👥 Facebook

---

**Bonus 功能：**
- 📱 iOS Widget
  - LiveActivityWidget (⏰ 即時資訊)
  - NextSessionWidget (📅 下個議程)
  - CountdownWidget (⏳ 倒數計時)

---

**底層架構：**
- 📦 SessionData Package (官方資料源)
  - 💾 離線快取
  - 🔄 線上更新
  - 🔄 同步機制
- 🏗️ SwiftUI + TCA 架構
  - 🧩 模組化開發 (Features/Views/Models)
  - 🔗 依賴注入 (DependencyClients)
  - 📱 原生體驗 (SwiftUI)