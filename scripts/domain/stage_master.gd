extends RefCounted

const StagePlan_ = preload("res://scripts/domain/stage_plan.gd")

static func create_plan(stage_index: int) -> Object:
	return StagePlan_.new(stage_index)
