# 數位頂尖社交評價平台 (VibeRanking)

## 項目概述

這是一個基於 SwiftUI 的 iOS 應用程序，實現了一個社交評價平台，用戶可以上傳照片並獲得其他用戶的評分和風格分析報告。

## 當前狀態

✅ **已完成的任務 1: 設置項目基礎架構和核心模型**

### 已實現的功能

1. **MVVM 架構目錄結構**

   - Models: 核心數據模型
   - Views: UI 組件（按功能組織）
   - ViewModels: 業務邏輯層
   - Services: 外部服務集成
   - Repositories: 數據訪問層
   - Utils: 工具類和幫助程序

2. **核心數據模型**

   - `User`: 用戶資料和評分進度
   - `Photo`: 照片數據和元數據
   - `Rating`: 評分系統（Hot/Not）
   - `StyleReport`: 風格分析報告

3. **服務層架構**

   - Firebase 服務配置（佔位符實現）
   - 分析服務
   - 錯誤處理系統
   - 應用配置管理

4. **存儲庫層**
   - 所有核心模型的存儲庫實現
   - 統一的 CRUD 操作接口
   - 特定於模型的查詢方法

## 待辦事項

### 添加 Firebase 依賴項

當前實現使用佔位符來避免編譯錯誤。要啟用完整的 Firebase 功能：

1. 在 Xcode 中添加 Firebase SDK：

   - File → Add Package Dependencies
   - 添加 `https://github.com/firebase/firebase-ios-sdk`
   - 選擇所需的產品：
     - FirebaseAuth
     - FirebaseFirestore
     - FirebaseStorage
     - FirebaseAnalytics

2. 更新 GoogleService-Info.plist 文件，使用您的實際 Firebase 項目配置

3. 替換佔位符實現：
   - `FirebaseService.swift`
   - `AnalyticsService.swift`
   - 所有存儲庫文件

### 下一步任務

根據任務列表，接下來需要實現：

- 用戶認證系統
- 照片評分功能
- 照片上傳功能
- 風格分析和報告生成

## 項目結構

```
viberanking/
├── Models/                 # 數據模型
│   ├── User.swift
│   ├── Photo.swift
│   ├── Rating.swift
│   ├── StyleReport.swift
│   ├── AppError.swift
│   └── AppConfiguration.swift
├── Views/                  # UI 組件
│   ├── Authentication/
│   ├── PhotoRating/
│   ├── PhotoUpload/
│   ├── StyleReport/
│   └── Common/
├── ViewModels/            # 視圖模型
│   ├── BaseViewModel.swift
│   ├── Authentication/
│   ├── PhotoRating/
│   ├── PhotoUpload/
│   └── StyleReport/
├── Services/              # 服務層
│   ├── FirebaseService.swift
│   ├── AnalyticsService.swift
│   ├── ServiceProtocols.swift
│   └── RepositoryProtocols.swift
├── Repositories/          # 數據訪問層
│   ├── UserRepository.swift
│   ├── PhotoRepository.swift
│   ├── RatingRepository.swift
│   └── StyleReportRepository.swift
└── Utils/                 # 工具類
    └── WebPConverter.swift
```

## 技術棧

- **框架**: SwiftUI
- **架構**: MVVM
- **後端**: Firebase (Firestore, Auth, Storage)
- **圖像處理**: WebP 轉換
- **狀態管理**: Combine
- **錯誤處理**: 自定義錯誤系統

## 開發說明

- 每個文件都保持在 500 行以下
- 使用 async/await 進行異步操作
- 實現了完整的錯誤處理和用戶反饋
- 支持離線持久化（通過 Firebase）
- 包含性能監控和分析跟踪
