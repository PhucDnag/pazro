# PixelDungeon

## PAZRO 0.6 — dungeon hành động và giải đố

Game mặc định đã chuyển sang dungeon **hai tầng, 9–10 phòng mỗi tầng**: khám phá nhánh, phòng chiến đấu khóa cửa, hai câu đố lấy ấn, kho báu nâng súng, suối hồi phục và boss. **E** tương tác / qua cửa, **M** xem bản đồ. Xem [hướng dẫn gameplay hiện tại](docs/adventure.md).

Test mới: `godot --headless --path . -s tests/test_adventure.gd`. Phần Expedition 0.5 dưới đây là lịch sử phiên bản.

## PAZRO — bản chơi Expedition mới

Scene mặc định hiện là `scenes/main/expedition.tscn`: menu tiếng Việt, chọn ba vùng, HUD, chiến đấu theo đợt, boss, rương thưởng, tạm dừng và chơi lại. Mở `project.godot` trong Godot 4.x rồi nhấn **F5**.

- **WASD / mũi tên**: di chuyển; **chuột trái**: bắn; **Q**: đổi súng.
- **Space**: lướt né; **F**: bộc phá; **R**: bình máu; **E**: mở rương; **Esc**: tạm dừng.
- Dùng ảnh tham chiếu của người dùng cho thẻ vùng; bổ sung hình nền, sprite alpha và sàn đấu trường bằng imagegen.
- Xem [chi tiết bản chơi, kiến trúc và giới hạn](docs/expedition.md). Kiểm thử mới: `godot --headless --path . -s tests/test_expedition.gd`.

Phần milestone bên dưới mô tả scene dungeon cũ, vẫn được giữ để kiểm thử hồi quy; không phải danh sách đầy đủ tính năng của Expedition mới.

> **Game hành động Roguelike góc nhìn từ trên xuống (2D Top-Down Roguelike) bằng Godot Engine 4 & GDScript.**  
> Lấy cảm hứng từ vòng lặp cốt lõi của *Soul Knight* và phong cách thiết kế *Pazro*: di chuyển tự do, ngắm bắn 360 độ, phòng kín đóng cửa khi giao tranh, tiêu diệt quái theo đợt (Waves), mở rương báu phần thưởng, bản đồ thu nhỏ Minimap trực quan, thu thập và đổi vũ khí, tiêu diệt Boss.

---

## 1. Trạng thái dự án: Đã hoàn thành Milestone 4
- [x] **Milestone 1**: Foundation & Core Movement Loop (Khởi tạo dự án, Render Pixel Art 640x360 Nearest, Nhân vật WASD 8 hướng normalized, Camera bám theo mượt mà, Đấu trường Test Dungeon có va chạm vật lý, HUD máu thật).
- [x] **Milestone 2**: Weapon System & Shooting (Tài nguyên `WeaponData`, ngắm bắn xoay chuột 360°, bắn đạn `Projectile`, va chạm tường kèm hit spark VFX, quản lý Mana/Energy, đổi 3 vũ khí Pistol / Shotgun / Plasma theo thiết kế Pazro).
- [x] **Milestone 3**: Combat System & Enemies (Tài nguyên `EnemyData` cho Goblin / Skeleton / Mage, AI truy đuổi và bắn xa, Health/Hurtbox/Hitbox Component, giật lùi knockback, chớp trắng trúng đòn, số sát thương nổi FloatingText).
- [x] **Milestone 4**: Room Combat & Locking (Phòng khởi đầu Start Room nối hành lang Corridor đến Đấu trường CombatRoom, tự động sập cửa sắt khóa phòng khi bước vào, sinh quái 2 đợt Waves, mở khóa cửa tự động khi dọn sạch, rương báu rơi với hiệu ứng pop-in và thưởng vàng phím [E], Minimap góc trên bên phải cập nhật trạng thái phòng thời gian thực).
- [ ] **Milestone 5**: Loot, Energy & Inventory (Rơi bình máu, tinh thể năng lượng mana, thỏi vàng, nhặt và quản lý kho 2 vũ khí trên tay).
- [ ] **Milestone 6**: Boss Encounter & Progression (Phòng Boss, thanh máu Boss trên HUD, cơ chế đạn chùm địa ngục, cổng chuyển tầng).
- [ ] **Milestone 7**: Audio, Visual Effects & Windows Release Build.

---

## 2. Thông số kỹ thuật
- **Engine**: Godot Engine 4.x (Đã kiểm thử thực tế trên `v4.7.2.stable.official.ed1daf0bf`).
- **Ngôn ngữ**: GDScript tĩnh (Static Typing đầy đủ, tuân thủ nguyên tắc Single Responsibility).
- **Độ phân giải nội bộ**: `640x360` (tỷ lệ 16:9), cửa sổ phóng to mặc định `1280x720`.
- **Cấu hình Pixel Art**:
  - `stretch/mode = "canvas_items"`
  - `stretch/aspect = "keep"`
  - `textures/canvas_textures/default_texture_filter = 0` (Nearest Neighbor - giữ nguyên độ sắc nét từng pixel).
- **Nguyên tắc kiến trúc**:
  - Tách biệt dữ liệu khỏi logic (Dùng Custom Resources `.tres` cho súng, quái, vật phẩm trong `data/`).
  - Giao tiếp phi ghép nối qua `EventBus` (`scripts/autoload/event_bus.gd`).
  - Quản lý trạng thái chung qua `GameManager` (`scripts/autoload/game_manager.gd`).
  - Tuyệt đối không dồn logic vào `main.gd`.

---

## 3. Cấu trúc thư mục

```
PixelDungeon/
├── project.godot               # Cấu hình dự án, autoload, viewport 640x360, input map
├── AGENTS.md                   # Tiêu chuẩn kiến trúc và quy chuẩn phát triển
├── README.md                   # Tài liệu hướng dẫn chạy, điều khiển, build
├── docs/
│   └── architecture_plan.md   # Thiết kế kiến trúc chi tiết & lộ trình 7 milestones
├── scenes/
│   ├── main/
│   │   ├── main.tscn           # Scene gốc liên kết Dungeon, Player, HUD
│   │   └── dungeon.tscn        # Level layout: StartRoom -> Corridor -> CombatRoom
│   ├── player/
│   │   └── player.tscn         # Nhân vật người chơi (Collision, Sprite, Camera2D, WeaponPivot)
│   ├── enemies/
│   │   └── enemy.tscn          # Kẻ thù với AI đuổi theo/bắn xa, Health/Hurtbox/Hitbox
│   ├── weapons/
│   │   └── weapon.tscn         # Cụm súng xoay quanh pivot
│   ├── projectiles/
│   │   ├── bullet.tscn         # Đạn người chơi (Pistol, Shotgun, Plasma)
│   │   └── enemy_bullet.tscn   # Đạn phép thuật của quái Pháp sư Mage
│   ├── rooms/
│   │   ├── door.tscn           # Cửa ngục tự động đóng khóa và mở với hoạt ảnh nảy
│   │   └── combat_room.tscn    # Phòng đấu trường (tường, cửa, điểm spawn quái, điểm rơi rương)
│   ├── items/
│   │   └── chest.tscn          # Rương báu tương tác phím [E], sinh chữ nổi +100 vàng
│   └── ui/
│       ├── hud.tscn            # Giao diện HUD (HP đỏ, MP cyan, Card súng, Minimap)
│       ├── minimap.tscn        # Bản đồ thu nhỏ góc trên bên phải UI Pazro
│       └── floating_text.tscn  # Hiệu ứng số sát thương / tiền vàng nổi bay lên
├── scripts/
│   ├── autoload/
│   │   ├── event_bus.gd        # Observer toàn cục qua Signals
│   │   └── game_manager.gd     # Quản lý trạng thái game & defensive input mappings
│   ├── player/
│   │   └── player.gd           # Di chuyển 8 hướng, ngắm chuột, bắn, đổi súng, nhận sát thương
│   ├── combat/
│   │   ├── weapon_data.gd      # Custom Resource lưu trữ chỉ số súng
│   │   ├── enemy_data.gd       # Custom Resource lưu trữ chỉ số quái
│   │   ├── projectile.gd       # Quỹ đạo đạn, va chạm tường, gây sát thương
│   │   ├── health_component.gd # Quản lý máu và chết
│   │   ├── hurtbox_component.gd# Tiếp nhận va chạm đòn đánh
│   │   └── hitbox_component.gd # Gây sát thương khi chạm
│   ├── enemies/
│   │   └── enemy.gd            # AI quái cận chiến/tầm xa, knockback, chớp trắng
│   ├── dungeon/
│   │   ├── dungeon.gd          # Quản lý bản đồ ngục và điểm xuất phát
│   │   ├── door.gd             # Logic khóa và mở cửa
│   │   └── room.gd             # Vòng đời phòng chiến đấu: kích hoạt, sinh đợt quái, dọn sạch
│   ├── items/
│   │   └── chest.gd            # Logic tương tác mở rương, sinh phần thưởng
│   └── ui/
│       ├── hud.gd              # Đồng bộ HUD với Player và EventBus
│       ├── minimap.gd          # Vẽ bản đồ phòng (chưa tới / đang giao tranh / đã xong)
│       └── floating_text.gd    # Hoạt cảnh tween số sát thương / thưởng nổi
├── assets/
│   ├── sprites/
│   │   ├── player_hero.png     # Tướng tóc bạc phong cách Pazro
│   │   ├── enemies/            # Sprite Goblin, Skeletor, Mage
│   │   ├── weapons/            # Sprite Pistol, Shotgun, Plasma Blaster
│   │   ├── projectiles/        # Sprite đạn người chơi và đạn ma thuật
│   │   ├── props/              # Sprite cửa đóng/mở, rương đóng/mở, đuốc tường
│   │   └── vfx/                # Hiệu ứng tia lửa va chạm tường
│   ├── tilesets/
│   │   ├── floor_tile.png      # Gạch lát sàn ngục 16x16
│   │   └── wall_tile.png       # Gạch tường đá 16x16
├── data/
│   ├── weapons/                # `pistol.tres`, `shotgun.tres`, `plasma_blaster.tres`
│   └── enemies/                # `goblin.tres`, `skeleton.tres`, `mage.tres`
└── tests/
    ├── test_milestone1.gd      # Bộ test tự động M1 (Movement & Foundation)
    ├── test_milestone2.gd      # Bộ test tự động M2 (Weapons & Shooting)
    ├── test_milestone3.gd      # Bộ test tự động M3 (Combat & Enemies)
    └── test_milestone4.gd      # Bộ test tự động M4 (Room Combat & Locking)
```

---

## 4. Phím điều khiển trong game (Controls)

| Phím | Chức năng | Ghi chú |
|---|---|---|
| **W, A, S, D** | Di chuyển 8 hướng | Tốc độ di chuyển chéo được normalized chuẩn xác (160 px/s). |
| **Mũi tên (↑, ↓, ←, →)** | Di chuyển thay thế | Hỗ trợ bàn phím đầy đủ. |
| **Chuột (Mouse)** | Hướng ngắm 360° | Nhân vật tự lật mặt trái/phải (`flip_h`), trục vũ khí xoay quanh người chơi. |
| **Chuột Trái** | Bắn vũ khí | Bắn đạn theo tốc độ bắn (Fire Rate) và tiêu hao Năng lượng/Mana (MP). |
| **Phím Q** | Đổi vũ khí | Tráo đổi xoay vòng giữa **Pistol -> Shotgun -> Plasma Blaster**. |
| **Phím E** | Tương tác | Đến gần rương báu để mở rương và nhận vàng thưởng. |
| **Phím H** | Nhận sát thương (-15 HP) | *Phím test*: Chớp đỏ nhân vật và cập nhật thanh máu đỏ HUD. |
| **Phím J** | Hồi máu (+15 HP) | *Phím test*: Hồi phục máu và cập nhật thanh máu HUD. |

---

## 5. Hướng dẫn chạy trò chơi & Kiểm thử tự động

### Cách 1: Khởi chạy game trải nghiệm trực tiếp
```powershell
& "C:\Users\phucd\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "d:\Code\pazro"
```
*Cách chơi Milestone 4:*
1. Bạn xuất hiện tại **Start Room** an toàn (Minimap hiển thị chấm sáng tại phòng bắt đầu).
2. Đi sang phải qua hành lang **Corridor** và bước vào **CombatRoom**.
3. Cửa sắt tự động sập xuống khóa kín 2 đầu, Minimap chuyển sang màu đỏ rực cảnh báo giao tranh!
4. Tiêu diệt **Đợt 1 (Wave 1: 2 Goblin)**.
5. Tiêu diệt tiếp **Đợt 2 (Wave 2: 1 Skeletor + 1 Mage bắn phép)**.
6. Khi quái bị quét sạch: Các cánh cửa tự động mở khóa (unlock), rương báu rơi xuống giữa phòng với hiệu ứng nảy!
7. Đi tới gần rương và nhấn **[E]** để nhận 100 vàng, Minimap chuyển sang màu xanh dương báo hiệu phòng đã dọn sạch!

### Cách 2: Chạy toàn bộ Test Suites Headless
- **Milestone 1**:
  ```powershell
  & "C:\Users\phucd\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path "d:\Code\pazro" -s res://tests/test_milestone1.gd
  ```
- **Milestone 2**:
  ```powershell
  & "C:\Users\phucd\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path "d:\Code\pazro" -s res://tests/test_milestone2.gd
  ```
- **Milestone 3**:
  ```powershell
  & "C:\Users\phucd\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path "d:\Code\pazro" -s res://tests/test_milestone3.gd
  ```
- **Milestone 4 (Room Combat & Waves & Minimap)**:
  ```powershell
  & "C:\Users\phucd\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path "d:\Code\pazro" -s res://tests/test_milestone4.gd
  ```
*Tất cả 4 bộ test cases đều đạt 100% PASS.*

---

## 6. Hướng dẫn đóng gói sản phẩm (Build / Export)
1. Trong Godot Editor, chọn **Project -> Export...**
2. Bấm **Add...** -> Chọn **Windows Desktop**.
3. Chọn đường dẫn xuất file (ví dụ: `build/PixelDungeon.exe`).
4. Bấm **Export Project** để tạo file `.exe` chạy offline độc lập trên Windows.
