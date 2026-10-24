class_name VillageAds
extends RefCounted

signal reward_granted(kind: String)
signal unavailable

# Deliberately ad-free until a native plugin and consent flow are verified.
# Only a verified native callback may consume an issued request token.
var native_ready := false
var consent := false
var pending: Dictionary = {}
var consumed: Dictionary = {}
var last_interstitial := -1000000.0

func request_reward(kind: String) -> String:
	if not native_ready or not consent:
		unavailable.emit()
		return ""
	var token := str(Time.get_ticks_usec())+"_"+str(pending.size())
	pending[token] = kind
	return token

func complete_reward(token: String, verified: bool) -> bool:
	if not verified or not native_ready or not consent or not pending.has(token) or consumed.has(token): return false
	var kind: String = pending[token]
	pending.erase(token)
	consumed[token] = true
	reward_granted.emit(kind)
	return true

func can_interstitial(now: float, natural_break: bool) -> bool:
	return native_ready and consent and natural_break and now-last_interstitial>=300.0
