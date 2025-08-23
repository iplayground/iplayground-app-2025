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
- TabView 主導航
 - 📅 Tab 1: 議程
   - Now Section
     - [x] 即時資訊區塊：⏰ 倒數計時、📍 當前議程、⏭️ 下個議程
   - Sessions Section
     - [x] 兩天分頁 Picker
     - [x] 議程列表
     - [x] 🔍 文字搜尋
     - ⭐ 標記議程功能
 - 👥 Tab 2: 社群：贊助商、講者、工作人員
   - [x] 分頁 Picker
   - Sponsor List: 🥇 金級、🥈 銀級、🥉 銅級、個人贊助
   - [x] Speaker List -> SpeakerView
   - [x] Staff List
 - 🌐 Tab 3: Flitto（即時翻譯）
   - 翻譯頁面
 - 👤 Tab 4: 個人功能
   - 編輯個人資料頁面
   - 產生 QR Code 頁面（個人名片，有「我在參加 iPlayground 2025」字樣，適合截圖上傳，也適合合照時使用）
   - 我喜愛的議程
 - ℹ️ Tab 5: 關於
   - 地點資訊
     - [x] 🗺️ 地址：用 Apple Maps 開啟、用 Google Maps 開啟
     - [x] 👀 MapKit + Look Around
     - [ ] 🏢 主要場地平面圖
     - [ ] 🎉 After Party 平面圖
   - [x] 重要連結
     - 🌐 官網
     - 📝 HackMD
     - 📧 電子報
     - 📺 YouTube
     - 💬 Discord
     - 💻 App 開源專案網址
     - SessionData 開源專案網址
     - [ ] 問卷網址
     - 🐦 Twitter
     - 🧵 Threads
     - 🐘 Mastodon
     - 👥 Facebook
     - 使用到的開源套件
     - App Store 連結
     - App 版本資訊

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