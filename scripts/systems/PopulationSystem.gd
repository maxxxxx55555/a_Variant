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
		# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
		@warning_ignore("return_value_discarded")
		TimeSystem.day_passed.connect(_on_day_passed)

func update_worker_assignments(new_jobs: Dictionary) -> void:
	var assigned:int= 0
	for j:Variant in new_jobs:
		if not jobs.has(j) or not (new_jobs[j] is int or new_jobs[j] is float) or new_jobs[j] < 0 :
			return
		var workers:float=new_jobs[j]
		if not is_finite(workers) or workers!=floorf(workers):return
		assigned += int(workers)
	if assigned <= total_population - sick_citizens - _soldiers():
		for job:Variant in jobs:
			var workers:float=new_jobs.get(job,0)
			jobs[job]=int(workers)
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
			var leavers:int= ceili(total_population * randf_range(0.03, 0.08))
			total_population = max(5, total_population - leavers)
			reconcile_workers()
			EventBus.notification_posted.emit(LocalizationManager.get_string("msg.emigration", {"count": leavers}), true)
	else:
		low_happiness_days = 0

func reconcile_workers() -> void:
	var remaining:int= maxi(0, total_population - sick_citizens - _soldiers())
	for job:Variant in jobs:
		var assigned:int=jobs[job]
		jobs[job]=clampi(assigned,0,remaining)
		remaining -= jobs[job]
	available_workers = remaining

func _soldiers() -> int:
	var army:Node= get_node_or_null("/root/ArmySystem")
	# ArmyRuntime is created later in autoload order; the availability guard is required.
	@warning_ignore("unsafe_method_access")
	return army.get_total_soldiers() if army and army.has_method("get_total_soldiers") else 0
