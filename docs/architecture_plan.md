# PixelDungeon - Kiến Trúc Hệ Thống & Kế Hoạch Triển Khai (Godot 4)

## 1. Giới thiệu tổng quan
**PixelDungeon** là trò chơi hành động roguelike góc nhìn từ trên xuống (top-down 2D action roguelike) lấy cảm hứng từ vòng lặp gameplay của Soul Knight:
- Di chuyển tự do 8 hướng, ngắm bắn bằng chuột 360 độ.
- Hệ thống phòng kín (enclosed battle rooms): bước vào phòng -> khóa cửa -> tiêu diệt đợt quái -> mở cửa & thưởng rương.
- Nhặt và đổi vũ khí trên mặt đất, thanh năng lượng, bình hồi máu.
- Trận đánh Boss ở cuối tầng và chuyển sang tầng tiếp theo.
- Toàn bộ nội dung sử dụng assets và ý tưởng thiết kế độc lập, không vi phạm bản quyền hay tài sản độc quyền của Soul Knight.

---

## 2. Thông số kỹ thuật cốt lõi
- **Game Engine**: Godot Engine 4.x (Thực tế: `v4.7.2.stable.official.ed1daf0bf`).
- **Ngôn ngữ**: GDScript với Static Typing nghiêm ngặt (`var speed: float = 180.0`).
- **Nền tảng mục tiêu**: Windows Desktop (chạy offline hoàn toàn, không phụ thuộc backend/database).
- **Độ phân giải nội bộ**: `640x360` (tỷ lệ 16:9), hiển thị cửa sổ mặc định `1280x720`.
- **Cấu hình Pixel Art**:
  - `stretch/mode = "canvas_items"`
  - `stretch/aspect = "keep"`
  - `textures/canvas_textures/default_texture_filter = 0` (Nearest Neighbor - đảm bảo từng pixel hiển thị sắc nét, không bị nhòe).
- **Điều khiển**: Bàn phím (WASD / Mũi tên) và Chuột (Ngắm bắn 360 độ, Chuột trái bắn, E tương tác).

---

## 3. Kiến trúc Scene & Component (Component-Based Design)

### 3.1. Phân tách Dữ liệu và Logic (Data-Driven Design)
Để đảm bảo dễ cân bằng thông số và bổ sung nội dung mà không can thiệp code logic:
- **Tài nguyên vũ khí (`WeaponData` extends `Resource`)**: Lưu tên, loại đạn, sát thương, tốc độ bắn, độ giật, năng lượng tiêu hao, sprite icon. Lưu tại `data/weapons/*.tres`.
- **Tài nguyên quái (`EnemyData` extends `Resource`)**: Lưu máu tối đa, tốc độ di chuyển, tầm phát hiện, đòn đánh, bảng rơi đồ (loot table). Lưu tại `data/enemies/*.tres`.
- **Tài nguyên vật phẩm (`ItemData` extends `Resource`)**: Lưu loại vật phẩm (máu, năng lượng, tiền, vũ khí), giá trị hồi phục, sprite. Lưu tại `data/items/*.tres`.

### 3.2. Cấu trúc Thực thể (Entities)
```
[Player (CharacterBody2D)]
 ├── CollisionShape2D
 ├── Visual (AnimatedSprite2D / Sprite2D)
 ├── Camera2D (Position Smoothing, Pixel Snap)
 ├── WeaponPivot (Node2D - xoay theo chuột)
 │    └── WeaponSlot (Marker2D)
 └── HealthComponent (Node / Script xử lý máu & giáp)

[EnemyBase (CharacterBody2D)]
 ├── CollisionShape2D
 ├── Visual (Sprite2D / AnimatedSprite2D)
 ├── HitboxComponent (Gây sát thương khi chạm)
 ├── HurtboxComponent (Nhận sát thương từ đạn)
 └── AIController / NavigationAgent2D

[Projectile (Area2D)]
 ├── CollisionShape2D
 ├── Sprite2D
 └── ProjectileLogic (Bay theo hướng, va chạm tường / Hurtbox)
```

### 3.3. Quản lý trạng thái & Giao tiếp (State Management & Decoupling)
- **`EventBus` (Autoload `res://scripts/autoload/event_bus.gd`)**: Hệ thống Observer toàn cục thông qua tín hiệu (Signals), loại bỏ phụ thuộc cứng (tight coupling):
  - `player_health_changed(current: int, max: int)`
  - `player_energy_changed(current: int, max: int)`
  - `player_died`
  - `room_entered(room_node)`
  - `room_cleared(room_node)`
  - `weapon_equipped(weapon_data)`
- **`GameManager` (Autoload `res://scripts/autoload/game_manager.gd`)**: Quản lý vòng đời trò chơi:
  - Trạng thái: `PLAYING`, `PAUSED`, `ROOM_CLEAR`, `BOSS_FIGHT`, `GAME_OVER`, `VICTORY`.
  - Khởi tạo màn chơi, reset vòng chạy (run).

---

## 4. Kế hoạch triển khai theo từng Milestone

| Milestone | Tên gọi | Nội dung triển khai | Tiêu chí nghiệm thu |
|---|---|---|---|
| **M1** (Hoàn thành) | **Foundation & Movement** | - Khởi tạo project chuẩn 640x360 & nearest pixel.<br>- Player di chuyển 8 hướng WASD, normalized vector.<br>- Test dungeon có tường va chạm vật lý.<br>- Camera theo nhân vật.<br>- HUD máu cơ bản kết nối tín hiệu thật.<br>- Headless test script tự động. | ĐÃ ĐẠT: Kiểm thử headless 5/5 test cases pass 100%. |
| **M2** (Hoàn thành) | **Weapon & Aiming** | - Resource `WeaponData` (Pistol, Shotgun, Plasma theo concept Pazro).<br>- Cơ chế xoay vũ khí 360 độ theo chuột, lật Y thông minh.<br>- Bắn đạn `Projectile` va chạm tường sinh hiệu ứng tia lửa.<br>- Quản lý Năng lượng/Mana (MP), tự hồi phục, HUD MP bar & đổi súng phím Q. | ĐÃ ĐẠT: Kiểm thử headless 5/5 test cases pass 100%. |
| **M3** (Hoàn thành) | **Combat & Enemies** | - Hệ thống Hurtbox/Hitbox component.<br>- Quái vật AI cơ bản (Goblin, Skeleton, Mage bắn đạn).<br>- Nhận sát thương, chớp trắng khi trúng đòn, giật lùi knockback, tan biến khi chết.<br>- Hiển thị số sát thương nổi (Floating Damage Numbers). | ĐÃ ĐẠT: Kiểm thử headless 6/6 test cases pass 100%. |
| **M4** (Hoàn thành) | **Room Combat & Lock** | - Hệ thống phòng kín (Battle Room), bản đồ liên kết StartRoom -> Corridor -> CombatRoom.<br>- Cửa tự động đóng khi vào phòng, sinh quái theo 2 đợt Waves.<br>- Tiêu diệt hết quái -> Mở cửa, xuất hiện rương thưởng phím [E].<br>- Bản đồ thu nhỏ Minimap góc trên bên phải UI Pazro cập nhật trạng thái thời gian thực. | ĐÃ ĐẠT: Kiểm thử headless 6/6 test cases pass 100%. |
| **M5** | **Loot, Energy & Inventory** | - Rương thưởng, bình máu, tinh thể năng lượng, tiền.<br>- Hệ thống nhặt & tráo đổi 2 vũ khí trên tay (Slot 1 & Slot 2). | Tương tác phím E nhặt vũ khí, đổi súng mượt mà. |
| **M6** | **Boss Encounter** | - Phòng Boss lớn.<br>- Boss có thanh máu to trên đỉnh màn hình, nhiều pha xả đạn (Bullet Hell nhẹ).<br>- Màn hình chiến thắng khi hạ Boss. | Đánh bại Boss kết thúc màn chơi hoặc sang tầng tiếp theo. |
| **M7** | **Audio, VFX & Export Build** | - Hiệu ứng rung màn hình (Screen Shake), hạt bụi khi chạy.<br>- Âm thanh bắn, nổ, nhạc nền retro.<br>- Đóng gói file chạy Windows offline (`.exe`). | Game chạy mượt mà độc lập không cần mở Godot Editor. |
