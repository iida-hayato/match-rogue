class_name StageMaster
extends RefCounted

static func create_plan(stage_index: int) -> StagePlan:
	return StagePlan.new(stage_index)
