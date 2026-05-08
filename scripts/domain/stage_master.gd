class_name StageMaster
extends RefCounted

const StagePlan = preload("res://scripts/domain/stage_plan.gd")

static func create_plan(stage_index: int) -> StagePlan:
	return StagePlan.new(stage_index)
