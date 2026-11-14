extends RefCounted
## v24: данные без зависимостей (их читает items_db.gd): новые постройки и предметы.

## постройка: [название, картинка, вес набора, преграда [x, y, w, h], вкладка верстака, {материалы}]
const BUILD: Dictionary = {
	"chest_small": ["Маленький сундук", "chest_small24", 2.0, [-8, -6, 16, 6], "home", {"log": 2}],
	"chest_mid": ["Средний сундук", "chest_mid24", 4.0, [-11, -8, 22, 8], "home", {"log": 4, "nail": 2}],
	"chest_big": ["Огромный сундук", "chest_big24", 7.0, [-15, -9, 30, 9], "home", {"log": 6, "@plank": 4, "nail": 4}],
	"warehouse": ["Склад", "warehouse24", 30.0, [-60, -30, 120, 28], "home", {"log": 30, "@plank": 24, "stone_m": 16, "nail": 10}],
}

## простые предметы: [название, вес, картинка]
const ITEMS: Dictionary = {
	"branch_long": ["Длинная ветка", 1.2, "icon_branch_long"],
}
