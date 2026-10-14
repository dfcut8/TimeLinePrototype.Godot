@tool
extends Node3D
## Resolved model-fit interfaces in local metres; transform these with the root.
## These bounds reserve space and do not add collision or navigation behavior.

func get_opening_bounds() -> AABB:
	return AABB(Vector3(-1.5, 0.0, -0.123), Vector3(3.0, 3.4, 0.246))

func get_approach_bounds() -> AABB:
	return AABB(Vector3(-1.5, 0.0, -1.0), Vector3(3.0, 3.4, 6.0))
