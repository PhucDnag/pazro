extends Node

## EventBus: Hệ thống tín hiệu (Signals) toàn cục cho PixelDungeon.
## Cho phép các hệ thống (Player, HUD, Combat, Rooms) giao tiếp phi ghép nối.

# Tín hiệu người chơi
signal player_health_changed(current_hp: int, max_hp: int)
signal player_damaged(amount: int)
signal player_healed(amount: int)
signal player_energy_changed(current_energy: int, max_energy: int)
signal weapon_switched(weapon_data: WeaponData)
signal player_died
signal sound_requested(id: String)
signal music_requested(id: String)
signal audio_level_requested(bus: String, value: float)
signal audio_settings_requested
signal audio_levels_changed(levels: Dictionary[String, float])

# Tín hiệu phòng và ngục
signal room_entered(room_name: String)
signal room_cleared(room_name: String)

# Tín hiệu hệ thống & tương tác
signal interaction_triggered(action_name: String)
signal game_state_changed(new_state: String)
signal expedition_changed(wave: int, total: int, enemies: int, gold: int)
signal boss_health_changed(current: int, maximum: int, title: String)
signal expedition_finished(victory: bool, gold: int)
signal reward_collected(amount: int)
signal hero_abilities_changed(dash: float, skill: float, potions: int)
signal dungeon_changed(floor_index: int, room_title: String, seals: int, gold: int, current_cell: Vector2i, map: Array[Dictionary])
