class_name FactionData
extends Resource

@export var id: String = ""
@export var name_key: String = ""
@export var desc_key: String = ""
@export var leader_name: String = ""
@export var personality_type: String = "cautious" # defensive, ambitious, cautious, martial, mercantile
@export var military_power: float = 50.0
@export var relationship_to_player: float = 0.0 # -100 to +100
@export var threat_perception: float = 0.0
@export var mobilization_level: int = 0 # 0: Peaceful, 1: Alarm, 2: Mobilized, 3: Escalated, 4: Incident, 5: War
