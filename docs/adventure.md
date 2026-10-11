# PAZRO 0.6 — khám phá, hành động và giải đố

Scene mặc định vẫn là `scenes/main/expedition.tscn`. Mở project bằng Godot và nhấn F5, chọn vùng để bắt đầu một lượt mới.

## Vòng chơi

1. Xuất phát ở nơi trú chân. Đi gần cửa sáng và nhấn **E** để sang phòng kế tiếp.
2. Chọn nhánh qua minimap hoặc bản đồ lớn **M**. Bản đồ chỉ lộ phòng đã đến và các phòng kề bên.
3. Phòng canh gác khóa cửa khi giao tranh; dọn hai đợt quái để mở cửa. Các trụ đá chặn người và đạn, cho phép dùng làm chỗ nấp.
4. Tìm hai phòng cơ quan để lấy **hai ấn phong**. Không thể vào boss khi còn thiếu ấn.
5. Có thể ghé kho báu để nâng sát thương cả ba súng trong lượt chơi, hoặc suối hồi phục để hồi HP, mana và nhận thêm bình máu. Phần thưởng mỗi phòng chỉ nhận một lần.
6. Hạ boss, đến cổng giữa phòng rồi nhấn **E** để xuống tầng hai. Nhân vật giữ vũ khí nâng cấp, vàng và bình máu; tầng mới có sơ đồ và câu đố mới, ấn phong đặt lại về 0.
7. Hạ boss tầng hai và dùng cổng để hoàn thành lượt chơi. Chết hoặc chơi lại bắt đầu lượt mới.

## Hai câu đố

**Mật ngữ tinh thạch**

Bia đá ghi thứ tự ba ký hiệu I, II, III, xáo trộn theo seed. Đứng gần từng trụ và nhấn E theo đúng thứ tự. Hai tháp bắn đạn ngắm vào người chơi theo nhịp, có vòng báo nạp đạn. Sai thứ tự đặt lại tiến độ và gọi một goblin; tiếp tục nhập sai không sinh thêm vô hạn. Sau khi nhập đúng vẫn phải hạ lính canh còn sống mới nhận ấn. Cơ quan giải xong ngừng bắn, và trạng thái được giữ khi quay lại phòng.

**Cơ quan cân bằng**

Đẩy hai khối lên hai đĩa sáng. Đứng phía đối diện hướng cần đẩy, đến gần khối và nhấn E; mỗi lần đẩy dịch một ô. Khối có va chạm, không đẩy chồng lên nhau hoặc ra ngoài vùng cho phép. Dải đỏ báo trước nhịp bẫy; rời hàng nguy hiểm hoặc lướt qua để tránh sát thương. Nếu đẩy sai, đến bệ RESET phía trái và nhấn E. Đặt đúng cả hai khối để tắt bẫy, nhận ấn và lưu trạng thái phòng.

## Điều khiển

| Phím | Tác dụng |
| --- | --- |
| WASD / mũi tên | Di chuyển |
| Chuột trái | Ngắm và bắn |
| Q | Đổi súng |
| Space | Lướt né, miễn sát thương trong lúc lướt |
| F | Bộc phá quanh nhân vật |
| R | Uống bình máu |
| E | Cửa, trụ, khối, reset, rương, suối, cổng |
| M | Mở / đóng bản đồ; thời gian trong game vẫn chạy |
| Esc | Tạm dừng |

## Kiến trúc và dữ liệu

- `adventure_layout.gd`: sơ đồ liên thông theo seed, xoay / phản chiếu mẫu nhánh, tráo vị trí hai câu đố, tùy chọn thêm nhánh vòng. Có 9–10 phòng mỗi tầng; không phải thuật toán tạo mê cung hoàn toàn tự do.
- `adventure_room_state.gd`: lưu trạng thái thăm, hoàn thành, nhận thưởng, thứ tự rune và vị trí khối trong lượt chơi.
- `adventure_run.gd`: chuyển phòng / tầng, giữ nhân vật, phát thông tin HUD qua EventBus, cộng thưởng và nâng cấp bản sao Resource.
- `adventure_chamber.gd`: cửa, sóng quái, vật cản và các tương tác của phòng.
- `room_puzzle.gd`: luật câu đố, reset, tháp đạn và nhịp bẫy.
- `adventure_map.gd`: minimap và bản đồ lớn từ sự kiện dungeon_changed.
- `data/adventure.tres` / AdventureData: số tầng, số quái, sóng quái, sát thương / nhịp bẫy, mana / HP thưởng và nâng cấp vũ khí.

Giao diện giữ nền và sprite hiện có. Các phòng dùng chung bộ sàn nhưng khác bố trí cửa, vật cản, cơ quan, địch và phần thưởng. Ba vùng vẫn là ba chủ đề dùng cùng hệ dungeon; chưa có cửa hàng, NPC, lưu lượt chơi hoặc hệ trang bị ngẫu nhiên đầy đủ như một game thương mại.

## Kiểm thử

```powershell
godot --headless --path . -s tests/test_adventure.gd
godot --headless --path . -s tests/test_expedition.gd
```

Giữ cả bốn bộ test milestone cũ. Test adventure kiểm tra 100 seed liên thông, di chuyển qua sự kiện E, khóa cửa, sai / đúng câu đố, bẫy, reset, hai ấn, trạng thái khi quay lại, phần thưởng không lặp, không sửa Resource gốc, quái theo đợt, cổng xuống tầng và chiến thắng cuối. Một số phần kiểm thử luật dùng gọi hàm trực tiếp để độc lập với thời gian chiến đấu; vẫn cần playtest để tinh chỉnh độ khó.

Ảnh render từ game: `runes_preview.png`, `blocks_preview.png`, `combat_preview.png`; tạo lại bằng `tests/capture_expedition.gd` với renderer đồ họa.
