class_name AudioCatalog
extends Resource

@export var effects: Dictionary[String, AudioStream] = {}
@export var music: Dictionary[String, AudioStream] = {}
@export var voice_limit: int = 12
@export var effect_db: float = -9.0
@export var music_db: float = -8.0
@export var crossfade_seconds: float = 0.6
@export var repeat_interval: float = 0.045
@export var default_master: float = 0.8
@export var default_music: float = 0.55
@export var default_sfx: float = 0.8
