# AGENTS.md - Quy Chuẩn Phát Triển PixelDungeon

## 1. Giới thiệu & Triết lý dự án
Dự án **PixelDungeon** là game 2D Top-Down Roguelike phát triển bằng Godot Engine 4.x và GDScript có định kiểu chặt chẽ (static typing).
Game hướng đến trải nghiệm hành động phòng kín tốc độ cao, điều khiển nhạy bén và phong cách đồ họa Pixel Art sắc nét.

## 2. Quy tắc kiến trúc bất di bất dịch
1. **Tuyệt đối không nhồi nhét logic vào `main.gd`**:
   - `main.gd` chỉ có nhiệm vụ điều phối cấp cao (khởi tạo dungeon, kết nối HUD, quản lý chuyển scene).
   - Mỗi thực thể (Player, Enemy, Weapon, Room) sở hữu script riêng với trách nhiệm đơn lẻ (Single Responsibility Principle).
2. **Tách biệt Dữ liệu (Data) khỏi Logic**:
   - Mọi chỉ số (damage, health, fire_rate, drop_rates, textures) phải lưu trữ dưới dạng Custom Resource (`WeaponData`, `EnemyData`, `ItemData`) trong thư mục `data/`.
   - Logic chỉ đọc dữ liệu từ Resource để thi hành, không hardcode chỉ số trong script gameplay.
3. **Giao tiếp phi ghép nối (Decoupled Communication)**:
   - Dùng Tín hiệu (Signals) đi lên, Gọi hàm (Functions) đi xuống: Cha gọi con qua hàm, con báo cho cha qua signal.
   - Giao tiếp giữa các hệ thống không cùng cây phân cấp (Player -> HUD, Room -> GameManager) phải sử dụng `EventBus` (`scripts/autoload/event_bus.gd`).
4. **Quy chuẩn GDScript**:
   - Luôn sử dụng Static Typing: `var speed: float = 160.0`, `func take_damage(amount: int) -> void:`.
   - Đặt tên file và thư mục dạng `snake_case`.
   - Đặt tên Class dạng `PascalCase` (`class_name Player`).
   - Đặt tên hằng số dạng `UPPER_SNAKE_CASE`.

## 3. Cấu hình Pixel Art chuẩn mực
- Độ phân giải gốc: `640x360` (16:9).
- Stretch Mode: `canvas_items`, Aspect: `keep`.
- Texture Filter mặc định: `Nearest` (không để bilinear làm nhòe pixel).
- Tọa độ di chuyển và camera cần hỗ trợ pixel snap để tránh hiện tượng subpixel jitter.

## 4. Quy trình kiểm thử
- Mỗi tính năng mới hoặc mỗi milestone cần có script kiểm thử tự động tại `tests/` để có thể chạy headless:
  ```bash
  godot --headless --path . -s tests/<test_script>.gd
  ```
- Không đẩy code chưa vượt qua kiểm tra cú pháp và kiểm thử headless.
