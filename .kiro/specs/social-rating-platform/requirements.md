# Requirements Document

## Introduction

數位頂尖社交評價平台是一個 iOS 應用程式，讓用戶通過互相評分照片來獲得個人風格分析報告。該平台採用遊戲化設計，通過強制性的評分階段來確保用戶參與度，並提供個性化的風格分析作為激勵機制。

## Requirements

### Requirement 1

**User Story:** 作為新用戶，我想要通過第三方服務快速登入，這樣我就不需要創建新的帳戶。

#### Acceptance Criteria

1. WHEN 用戶打開應用程式 THEN 系統 SHALL 顯示 Google 和 Apple 登入選項
2. WHEN 用戶選擇 Google 登入 THEN 系統 SHALL 使用 Google OAuth 進行身份驗證
3. WHEN 用戶選擇 Apple 登入 THEN 系統 SHALL 使用 Sign in with Apple 進行身份驗證
4. WHEN 登入成功 THEN 系統 SHALL 獲取用戶基本資訊（姓名、頭像、性別）
5. WHEN 獲取用戶資訊後 THEN 系統 SHALL 創建用戶檔案並導向滑圖評分模式

### Requirement 2

**User Story:** 作為新用戶，我想要先評分其他人的照片，這樣我就能了解平台的運作方式並解鎖上傳功能。

#### Acceptance Criteria

1. WHEN 用戶完成登入 THEN 系統 SHALL 顯示滑圖評分介面
2. WHEN 用戶進入評分模式 THEN 系統 SHALL 顯示進度條「還需評分 X 張照片解鎖上傳功能」
3. WHEN 用戶評分一張照片 THEN 系統 SHALL 更新進度條並記錄用戶偏好數據
4. WHEN 用戶完成少於 20 張照片評分 THEN 系統 SHALL 阻止用戶訪問上傳功能
5. WHEN 用戶完成 20 張照片評分 THEN 系統 SHALL 解鎖上傳功能並顯示 CTA

### Requirement 3

**User Story:** 作為完成評分的用戶，我想要被引導上傳自己的照片，這樣我就能獲得個人風格分析。

#### Acceptance Criteria

1. WHEN 用戶完成 20 張照片評分 THEN 系統 SHALL 顯示個性化 CTA 訊息
2. WHEN 顯示 CTA THEN 系統 SHALL 包含用戶最喜歡的風格類型資訊
3. WHEN 用戶點擊「上傳你的照片」按鈕 THEN 系統 SHALL 導向照片上傳介面
4. IF 用戶嘗試跳過上傳 THEN 系統 SHALL 提供激勵訊息鼓勵上傳

### Requirement 4

**User Story:** 作為用戶，我想要上傳我的照片並追蹤評分進度，這樣我就能知道何時可以查看我的分析報告。

#### Acceptance Criteria

1. WHEN 用戶選擇上傳照片 THEN 系統 SHALL 提供相機和相簿選項
2. WHEN 用戶選擇照片 THEN 系統 SHALL 讀取 EXIF 資料驗證照片新鮮度
3. WHEN 照片拍攝時間超過 24 小時 THEN 系統 SHALL 提示用戶上傳更近期的照片
4. WHEN 檢測到螢幕截圖或無 EXIF 資料 THEN 系統 SHALL 拒絕上傳並提示使用相機拍攝
5. WHEN 照片驗證通過並上傳成功 THEN 系統 SHALL 進入「等待評分」狀態
6. WHEN 在等待狀態 THEN 系統 SHALL 實時顯示已獲得評分數量
7. WHEN 評分數量少於 50 個 THEN 系統 SHALL 顯示「需要 X 個評分解鎖完整報告」
8. WHEN 獲得 50 個評分 THEN 系統 SHALL 解鎖個人風格報告

### Requirement 5

**User Story:** 作為獲得足夠評分的用戶，我想要查看詳細的個人風格報告，這樣我就能了解別人如何看待我的風格。

#### Acceptance Criteria

1. WHEN 用戶達到 50 個評分門檻 THEN 系統 SHALL 解鎖完整風格報告
2. WHEN 顯示報告 THEN 系統 SHALL 包含風格分析、排名和改進建議
3. WHEN 用戶查看報告 THEN 系統 SHALL 提供視覺化的風格數據展示
4. WHEN 報告生成 THEN 系統 SHALL 保存報告供用戶隨時查看

### Requirement 6

**User Story:** 作為活躍用戶，我想要通過持續參與獲得額外獎勵，這樣我就有動機繼續使用平台。

#### Acceptance Criteria

1. WHEN 用戶評分 10 張照片 THEN 系統 SHALL 提供 1 次「加速評分」機會
2. WHEN 用戶上傳多張照片 THEN 系統 SHALL 解鎖「風格演變」分析功能
3. WHEN 用戶分享成績 THEN 系統 SHALL 解鎖額外功能
4. WHEN 用戶完成激勵任務 THEN 系統 SHALL 更新用戶等級或徽章
5. WHEN 用戶查看激勵進度 THEN 系統 SHALL 顯示下一個獎勵的要求

### Requirement 7

**User Story:** 作為用戶，我想要有簡單直觀的照片評分體驗，這樣我就能快速完成評分任務。

#### Acceptance Criteria

1. WHEN 用戶在評分模式 THEN 系統 SHALL 顯示單張照片和兩個評分選項："Hot" 和 "Not"
2. WHEN 用戶點擊 "Hot" 按鈕 THEN 系統 SHALL 記錄正面評分並立即載入下一張照片
3. WHEN 用戶點擊 "Not" 按鈕 THEN 系統 SHALL 記錄負面評分並立即載入下一張照片
4. WHEN 用戶滑動照片向右 THEN 系統 SHALL 等同於點擊 "Hot" 按鈕
5. WHEN 用戶滑動照片向左 THEN 系統 SHALL 等同於點擊 "Not" 按鈕
6. WHEN 網路連接不穩定 THEN 系統 SHALL 預載照片以確保流暢體驗
7. WHEN 用戶評分 THEN 系統 SHALL 提供視覺反饋（如按鈕動畫或滑動效果）確認評分已記錄
8. IF 載入照片失敗 THEN 系統 SHALL 顯示錯誤訊息並提供重試選項

### Requirement 8

**User Story:** 作為用戶，我想要我的個人資料和照片得到適當保護，這樣我就能安心使用平台。

#### Acceptance Criteria

1. WHEN 用戶上傳照片 THEN 系統 SHALL 加密存儲照片數據
2. WHEN 處理用戶資料 THEN 系統 SHALL 遵循 GDPR 和相關隱私法規
3. WHEN 用戶要求刪除帳戶 THEN 系統 SHALL 完全移除用戶數據
4. WHEN 顯示照片給其他用戶 THEN 系統 SHALL 移除 EXIF 數據保護隱私
5. IF 檢測到不當內容 THEN 系統 SHALL 自動標記並移除違規照片
