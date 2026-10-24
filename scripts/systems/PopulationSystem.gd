extends Node

var total_population: int = 25
var available_workers: int = 5
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
		if not jobs.has(j) or not (new_jobs[j] is int or new_jobs[j] is float) or new_jobs[j] < 0 or new_jobs[j] != int(new_jobs[j]):
			return
		assigned += new_jobs[j]
	if assigned <= total_population - sick_citizens - _soldiers():
		for job in jobs:
			jobs[job] = int(new_jobs.get(job, 0))
		available_workers = total_population - sick_citizens - _soldiers() - assigned
		EventBus.settlement_updated.emit()

func _on_day_passed(_day: int) -> void:
	var laws: Dictionary = SettlementSystem.current_laws
	if laws.taxes == "high":
		happiness -= 2
	elif laws.taxes == "low":
		happiness += 1
	if laws.rations == "half":
		happiness -= 3
	if laws.conscription == "forced":
		happiness -= 2
	# Happiness & Crisis calculations
	happiness = clamp(happiness + randf_range(-2.0, 2.0), 0.0, 100.0)
	health = clamp(health + randf_range(-1.0, 1.0), 0.0, 100.0)

	if happiness < 20.0:
		low_happiness_days += 1
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.low_happiness"), true)
		if low_happiness_days >= 3:
			var leavers = int(ceil(total_population * randf_range(0.03, 0.08)))
			total_population = max(5, total_population - leavers)
			reconcile_workers()
			EventBus.notification_posted.emit(LocalizationManager.get_string("msg.emigration", {"count": leavers}), true)
	else:
		low_happiness_days = 0

func reconcile_workers() -> void:
	var remaining := maxi(0, total_population - sick_citizens - _soldiers())
	for job in jobs:
		jobs[job] = clampi(int(jobs[job]), 0, remaining)
		remaining -= jobs[job]
	available_workers = remaining

func _soldiers() -> int:
	var army := get_node_or_null("/root/ArmySystem")
	return army.get_total_soldiers() if army and army.has_method("get_total_soldiers") else 0
