extends Node
## Временный замер лагов (запуск с --perfk=<слот>). Ничего не меняет в игре, только печатает PERF: строки.

var main: Node2D


func start(m: Node2D, slot: int) -> void:
	main = m
	await get_tree().process_frame
	if not bool(Saves.get("lt_started")):
		Saves.set("lt_started", true)
		print("PERF: грузим слот %d" % slot)
		if not Saves.load_game(slot):
			print("PERF: нет слота")
			get_tree().quit(1)
		return
	await get_tree().create_timer(4.0).timeout
	print("PERF: работниц %d, королевство %s, узлов в дереве %d" % [Game.workers.size(), str(Game.kingdom.get("name", "-")), _count(get_tree().root)])
	print("PERF: позиция героини %s" % str((main.get("player") as Node2D).global_position))
	await _measure("база")
	var tests: Array = [
		["без Kingdom23", main.get_node("V23/Kingdom23")],
		["без Workers24", get_tree().get_first_node_in_group("workers24")],
		["без World", main.get("world")],
		["без Homestead", main.get("homestead")],
	]
	for tst in tests:
		var nd: Node = tst[1]
		if nd == null:
			continue
		nd.set_process(false)
		await _measure(String(tst[0]))
		nd.set_process(true)
	# без всех кошкодевочек
	var cg: Array = get_tree().get_nodes_in_group("catgirls")
	for c in cg:
		(c as Node).set_process(false)
	await _measure("без catgirl._process (%d шт)" % cg.size())
	for c in cg:
		(c as Node).set_process(true)
	# все сразу кроме main
	for nm in ["main"]:
		main.set_process(false)
		await _measure("без main._process")
		main.set_process(true)
	# события: что подвисает
	var k23: Node = main.get_node("V23/Kingdom23")
	var t0: int = Time.get_ticks_usec()
	for i in range(Game.workers.size()):
		k23.call("give_order", i, "wood")
	print("PERF: приказ 'рубить' всем: %.0f мс" % (float(Time.get_ticks_usec() - t0) / 1000.0))
	await _measure("все рубят лес (30 сек игры)")
	t0 = Time.get_ticks_usec()
	for i in range(Game.workers.size()):
		k23.call("give_order", i, "rest")
	print("PERF: приказ 'отдых' всем: %.0f мс" % (float(Time.get_ticks_usec() - t0) / 1000.0))
	t0 = Time.get_ticks_usec()
	k23.call("open_window")
	print("PERF: открыть окно O: %.0f мс" % (float(Time.get_ticks_usec() - t0) / 1000.0))
	await _measure("окно O открыто")
	k23.call("close_window")
	t0 = Time.get_ticks_usec()
	k23.call("_on_day")
	print("PERF: _on_day: %.0f мс" % (float(Time.get_ticks_usec() - t0) / 1000.0))
	t0 = Time.get_ticks_usec()
	k23.call("_respawn_all")
	print("PERF: _respawn_all: %.0f мс" % (float(Time.get_ticks_usec() - t0) / 1000.0))
	t0 = Time.get_ticks_usec()
	for i in range(3):
		k23.call("_work_hour")
	print("PERF: 3 x _work_hour: %.0f мс" % (float(Time.get_ticks_usec() - t0) / 1000.0))
	# вечер -> ночь -> утро: быстро крутим время
	for hh in [20.5, 5.5, 6.8]:
		Game.minutes = hh * 60.0
		await _measure("время %.1f ч" % hh)
	for hh in [20.9]:
		Game.minutes = hh * 60.0
		var worst: float = 0.0
		var last: int = Time.get_ticks_usec()
		for f in range(240):
			await get_tree().process_frame
			var now: int = Time.get_ticks_usec()
			worst = maxf(worst, float(now - last) / 1000.0)
			last = now
			if f % 30 == 0:
				Game.minutes += 12.0
		print("PERF: вечер->ночь (быстро), худший кадр %.0f мс" % worst)
	# по группам: сколько узлов вообще процессят
	var cnt: Dictionary = {}
	_scan(get_tree().root, cnt)
	var arr: Array = []
	for k in cnt.keys():
		arr.append([int(cnt[k]), String(k)])
	arr.sort_custom(func(a, b): return a[0] > b[0])
	for i in range(mini(15, arr.size())):
		print("PERF: скриптов %s — %d" % [arr[i][1], arr[i][0]])
	get_tree().quit(0)


func _count(n: Node) -> int:
	var c: int = 1
	for ch in n.get_children():
		c += _count(ch)
	return c


func _scan(n: Node, cnt: Dictionary) -> void:
	var s: Variant = n.get_script()
	if s != null and n.is_processing():
		var p: String = String((s as Script).resource_path).get_file()
		cnt[p] = int(cnt.get(p, 0)) + 1
	for ch in n.get_children():
		_scan(ch, cnt)


func _measure(label: String) -> void:
	await get_tree().create_timer(0.3).timeout
	var t0: int = Time.get_ticks_usec()
	var frames: int = 0
	var worst: float = 0.0
	var proc: float = 0.0
	var phys: float = 0.0
	var last: int = t0
	while Time.get_ticks_usec() - t0 < 3000000:
		await get_tree().process_frame
		var now: int = Time.get_ticks_usec()
		worst = maxf(worst, float(now - last) / 1000.0)
		last = now
		frames += 1
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var el: float = float(Time.get_ticks_usec() - t0) / 1000.0
	print("PERF: %-32s кадр %.1f мс (%.0f fps), худший %.0f мс, process %.2f мс, physics %.2f мс" % [label, el / float(frames), 1000.0 * float(frames) / el, worst, proc / float(frames), phys / float(frames)])
