extends Node

var total_population: int = 25
var available_workers: int = 20
var sick_citizens: int = 0
var happiness: float = 70.0 # 0 to 100
var health: float = 85.0 # 0 to 100
var low_happiness_days: int = 0

var jobs: Dictionary = {
	"farmers": 8,
	"woodcutters": 5,
	"miners": 3,
	"guards": 2,
	"blacksmiths": 2
}

func _ready() -> void:
	if TimeSystem:
		TimeSystem.day_passed.connect(_on_day_passed)

func update_worker_assignments(new_jobs: Dictionary) -> void:
	var assigned = 0
	for j in new_jobs:
		assigned += new_jobs[j]
	if assigned <= total_population:
		jobs = new_jobs.duplicate()
		available_workers = total_population - assigned

func _on_day_passed(_day: int) -> void:
	# Happiness & Crisis calculations
	happiness = clamp(happiness + randf_range(-2.0, 2.0), 0.0, 100.0)
	health = clamp(health + randf_range(-1.0, 1.0), 0.0, 100.0)

	if happiness < 20.0:
		low_happiness_days += 1
		EventBus.notification_posted.emit("WARNING: Settlement happiness is critically low! Risk of emigration!", true)
		if low_happiness_days >= 3:
			var leavers = int(ceil(total_population * randf_range(0.03, 0.08)))
			total_population = max(5, total_population - leavers)
			EventBus.notification_posted.emit("Emigration! " + str(leavers) + " citizens left the settlement.", true)
	else:
		low_happiness_days = 0
