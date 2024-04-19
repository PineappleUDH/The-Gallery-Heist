extends Node


func soft_clamp(value : float, increment : float, bound : float) -> float:
	# applies an increment to the value without exceeding the bound. similar to move_towards
	# except it will not clamp the value if it's already beyond the bound.
	# this is so for example velocity is limited to some max speed, but that max speed doesn't affect
	# other velocity modifiers like an external push
	# if value is already out of bound, but we're incrementing back towards bound allow it for deceleration etc..
	assert(bound >= 0.0, "Bound must be positive so it's applied in both directions")
	
	var value_abs : float = abs(value)
	var new_value : float = value + increment
	if value_abs < bound && abs(new_value) >= bound:
		# old value lower than the bound, new value exceeds it. stop at bound
		return bound * sign(new_value)
	elif value_abs >= bound:
		# old value already exceeded the bound...
		var same_sign : bool = sign(new_value) == sign(value)
		if same_sign && abs(new_value) > value_abs:
			# and we're not going back don't increment
			return value
		else:
			# but we're going back, decelerate
			if same_sign == false:
				# prevent sign change, otherwise we will have a never ending swing between positive and negative value
				return 0.0
			else:
				return new_value
	else:
		# both old and new value are lower than the bound
		return new_value
