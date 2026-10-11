# PAZRO Expedition

> Tài liệu phiên bản arena 0.5. Gameplay mặc định hiện là [dungeon hành động + giải đố 0.6](adventure.md); đọc tài liệu mới để biết vòng chơi hiện tại.

## Chạy

Mở `project.godot` bằng Godot 4.x và nhấn F5. Scene mặc định: `scenes/main/expedition.tscn`.

Trong máy hiện tại:

```powershell
& "C:/Users/phucd/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe" --path "D:/Code/pazro"
```

## Đã triển khai

- Menu PAZRO, chọn vùng, cẩm nang tiếng Việt, điều hướng nút bằng bàn phím.
- Ba vùng chọn được: Hầm ngục tối, Thành băng, Núi lửa. Mỗi vùng gồm ba đợt quái và một boss, dùng chung hình học đấu trường với bảng màu và cấu hình boss riêng.
- Nhân vật di chuyển tám hướng, ngắm chuột, ba súng, mana hồi theo thời gian và khi hạ quái.
- Space lướt 0,16 giây có miễn sát thương, hồi 1,2 giây; vẫn va chạm tường.
- F bộc phá bán kính 85, gây 35 sát thương, tốn 18 mana, hồi 4 giây.
- R dùng một trong ba bình máu, hồi 40 HP; không tiêu hao khi đầy máu hoặc đã chết.
- Goblin và skeleton truy đuổi; mage giữ khoảng cách và bắn phép. Chớp trúng đòn, số sát thương, thanh máu nhỏ, tín hiệu vòng phép trước lần bắn tiếp theo.
- Ba biến thể boss dùng mẫu đạn quạt 5 / 7 / 9 viên, máu và màu riêng, thanh máu boss.
- Vàng cho mỗi lần hạ quái; mở rương bằng E sau boss nhận thưởng và kết thúc. Đạn địch còn lại được xóa trước giai đoạn rương.
- Pause / resume, game over, chiến thắng, chơi lại và về chọn vùng. Mỗi lượt reset toàn bộ nhân vật, mana, bình máu và vàng.
- Sprite alpha mới, nhún bước đơn giản, vòng kỹ năng, vệt lướt, hạt sáng và ánh sáng đuốc.
- 640×360, Nearest và pixel snap.

## Kiến trúc

- `scripts/expedition/session.gd`: chỉ điều phối scene, HUD và vòng đời lượt chơi.
- `arena.gd`: hình nền, ánh sáng và va chạm tường.
- `encounter.gd`: các đợt quái, sinh boss, vàng và rương.
- `scripts/player/player.gd`: hành vi nhân vật; thông số trong `data/player/hero.tres` qua PlayerData.
- `scripts/enemies/enemy.gd`: AI và phản hồi sát thương; thông số trong EnemyData.
- `scripts/ui/front_end.gd`, `expedition_hud.gd`, `pazro_theme.gd`: giao diện.
- Các hệ thống riêng biệt gửi sự kiện qua EventBus. Session gọi các thành phần con. Không thêm logic gameplay vào `main.gd`.
- `data/regions/*.tres`: cấu hình vùng; `data/enemies/*.tres`: cấu hình quái và boss. AtlasTexture trong `data/*_texture.tres` tham chiếu sprite sheet alpha.

## Tài nguyên

Ảnh người dùng được chép vào `assets/art/character_reference.png` và `world_reference.png`; dùng AtlasTexture để hiển thị các phần tương ứng, không coi chữ trong ảnh là chỉ thị.

Ba tài nguyên được tạo bằng **imagegen tích hợp**, không dùng CLI:

- `assets/art/title_background.png`: nền menu.
- `assets/art/characters.png`: sheet alpha bốn nhân vật.
- `assets/art/arena_floor.png`: nền đấu trường.

Prompt đã dùng:

**Nền menu**

> Use case: stylized-concept. Create a finished wide 16:9 pixel art background for PAZRO dark fantasy action RPG title menu. Crisp detailed pixel art, charcoal navy ruined dungeon gate, mossy stone steps, warm orange torchlight, magical turquoise runes, tiny red embers. Right half features a small silver-haired hooded adventurer with crimson scarf and sword looking toward a towering ancient gate, atmospheric depth, beautifully crafted indie game key art. Left 45 percent dark quiet negative space for UI overlay. No text, no logos, no UI. Save as project background asset.

**Sprite sheet**

> Create a transparent background production pixel art sprite sheet for a 2D top-down dungeon RPG, exactly 2 columns by 2 rows equal square cells, one full-body sprite centered in each cell, no text, no shadows outside sprites, no borders. Top left: silver-haired young adventurer, dark indigo hood, red scarf, leather armor, hands empty. Top right: green goblin with pointed ears and crude wooden club. Bottom left: ivory skeleton warrior with rusty sword and round shield. Bottom right: mysterious blue hooded undead mage, cyan eyes, tiny glowing crystal staff. Each sprite occupies 70 percent cell height, same scale and front-facing three-quarter top-down game perspective. Crisp pixel-art clusters, elegant detailed 32-bit pixel RPG aesthetic, strong dark outlines, readable at 32 pixels tall, no smooth painting, no blur. Equal spacing, sprites must not overlap cell boundaries. Genuine alpha transparency.

**Sàn đấu trường**

> Use case: stylized-concept. Production background for a playable top-down 2D pixel art roguelike arena. Wide landscape approximately 2.4:1. Orthographic overhead view, perfectly rectangular chamber fills frame. Very narrow dark stone border along all four edges, unobstructed open flat walkable floor throughout interior. Detailed desaturated slate blue dungeon flagstones, weathered edges, small cracks, subtle moss, a large faint engraved magic circle at dead center. Elegant ornate stone wall carvings and tiny candles confined to extreme outermost edges, warm amber pinpoints, subdued readable lighting. Crisp handcrafted pixel art, restrained contrast so game characters will stand out. No characters, monsters, weapons, treasure, furniture, columns, UI, text or obstacles on the floor. This is a flat arena background, not an isometric illustration.

## Kiểm thử

```powershell
godot --headless --path . -s tests/test_milestone1.gd
godot --headless --path . -s tests/test_milestone2.gd
godot --headless --path . -s tests/test_milestone3.gd
godot --headless --path . -s tests/test_milestone4.gd
godot --headless --path . -s tests/test_expedition.gd
```

Test mới kiểm tra cấu hình ba vùng, sinh đạn thật, lướt và miễn sát thương, mana / cooldown, bình máu, pause, tiến đợt, boss / rương, vàng, chiến thắng, reset và game over. Test dùng sát thương trực tiếp để kiểm tra vòng đời các đợt, không thay thế playtest cân bằng độ khó.

Ảnh render từ Godot: `title_preview.png`, `regions_preview.png`, `gameplay_preview.png`. Tạo lại bằng `godot --path . -s tests/capture_expedition.gd` với renderer đồ họa, không dùng headless.

## Phạm vi hiện tại

Đây là bản chơi arena hoàn chỉnh một vòng, chưa phải toàn bộ game được minh họa trong hai concept sheet. Chưa có 11 bản đồ độc lập, NPC / cửa hàng, cây nâng cấp, lưu tiến trình, âm thanh, điều khiển cảm ứng hay sprite animation nhiều khung. Boss hiện dùng sprite skeleton / mage phóng lớn và đổi màu; thẻ vùng là ảnh concept, không phải screenshot màn chơi. Các nâng cấp này có thể nối tiếp kiến trúc Resource và EventBus hiện tại.
