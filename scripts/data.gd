class_name Data
const LEVELS := [["intro", 30, "level_intro", ""], ["shop", 100, "level_shop", "shop"], ["joints", 150, "level_joints", "btn_rollajoint"], ["gangsters", 200, "level_gangsters", "photo_jesus_jhamal"], ["fertilizers", 300, "level_fertilizers", "fertilizer_0"], ["safe", 400, "level_safe", "btn_buyasafe"], ["vinyl", 500, "level_vinyl", "btn_buyaplayer"], ["bong", 1000, "level_bong", "btn_buyabong"], ["police", 1500, "level_police", "photo_mr_malone"], ["sofa", 2000, "level_alien", "photo_alien"], ["shotgun", 2500, "level_sofa", "photo_nancy"], ["alien", 3000, "level_shotgun", "btn_buyashotgun"], ["jane", 3500, "level_jane", "btn_lapdance"], ["vaporize", 4000, "level_vaporize", "btn_buyavaporizer"], ["lion", 4500, "level_lion", "customize_3"], ["panties", 5000, "level_panties", "photo_sandy"], ["phone", 9000, "level_phone", "btn_buyaphone"], ["end", 1000000, "level_end", "c_intro_0_logo"]]
const YIELD := [10, 15, 20, 25, 30]
const GROW_MS := [30000, 40000, 50000, 60000, 70000]
const WATERING := [["watering_0", 10, "intro"], ["watering_1", 20, "gangsters"], ["watering_2", 100, "fertilizers"], ["watering_3", 50, "bong"]]
const SEEDS := [["seeds_0", 50, "intro"], ["seeds_1", 80, "joints"], ["seeds_2", 110, "vinyl"], ["seeds_3", 150, "shotgun"], ["seeds_4", 180, "lion"]]
const POTS := [["pots_0", 500, "intro"], ["pots_1", 1000, "safe"], ["pots_2", 4000, "alien"]]
const FERTS := [["fertilizer_0", 70, "fertilizers"], ["fertilizer_1", 120, "bong"], ["fertilizer_2", 200, "jane"], ["fertilizer_3", 300, "panties"]]
const CUSTOM := [["customize_0", 5000, "gangsters"], ["customize_1", 7000, "police"], ["customize_2", 20000, "bong"], ["customize_3", 50000, "lion"]]
const VINYL := [["vinyl_0", 200, "vinyl"], ["vinyl_1", 350, "police"], ["vinyl_2", 500, "shotgun"], ["vinyl_3", 750, "lion"], ["vinyl_4", 1000, "phone"]]
const TABS := ["watering", "seeds", "pots", "fertilizers", "customize", "vinyl"]
const TASKS := [["grow", 10, "intro"], ["sell", 20, "intro"], ["seed", 15, "shop"], ["pot", 20, "shop"], ["joints", 80, "joints"], ["gangsters", 70, "gangsters"], ["lee", 90, "safe"], ["safe", 50, "safe"], ["player", 70, "vinyl"], ["vinyl", 50, "vinyl"], ["bong", 50, "bong"], ["bong_all", 200, "bong"], ["malone", 300, "police"], ["sofa", 200, "sofa"], ["shotgun", 500, "shotgun"], ["shoot", 300, "shotgun"], ["alien", 400, "alien"], ["painting", 500, "alien"], ["lapdance", 500, "jane"], ["vaporizer", 1000, "vaporize"], ["vaporize_all", 2000, "vaporize"], ["get_panties", 900, "panties"], ["use_panties", 1500, "panties"], ["phone_buy", 1000, "phone"], ["phone_answer", 1200, "phone"], ["phone_deal", 2000, "phone"], ["phone_discount", 2700, "phone"], ["watering_1", 20, "gangsters"], ["watering_2", 40, "fertilizers"], ["watering_3", 120, "bong"], ["seeds_1", 100, "joints"], ["seeds_2", 200, "vinyl"], ["seeds_3", 300, "shotgun"], ["seeds_4", 400, "lion"], ["pots_1", 250, "safe"], ["pots_2", 500, "alien"], ["fertilizer_0", 80, "fertilizers"], ["fertilizer_1", 120, "bong"], ["fertilizer_2", 170, "jane"], ["fertilizer_3", 180, "panties"], ["customize_0", 40, "gangsters"], ["customize_1", 200, "police"], ["customize_2", 300, "bong"], ["customize_3", 500, "lion"], ["vinyl_0", 90, "vinyl"], ["vinyl_1", 180, "police"], ["vinyl_2", 270, "shotgun"], ["vinyl_3", 360, "lion"], ["vinyl_4", 450, "phone"], ["usd_1000", 30, "shop"], ["weed_100", 30, "joints"], ["usd_5000", 50, "gangsters"], ["weed_200", 50, "fertilizers"], ["usd_10000", 100, "safe"], ["weed_500", 100, "vinyl"], ["usd_50000", 200, "sofa"], ["weed_1000", 200, "police"], ["usd_100000", 300, "jane"], ["weed_2500", 300, "alien"], ["usd_500000", 400, "panties"], ["weed_5000", 500, "lion"], ["usd_1000000", 500, "end"], ["weed_10000", 1000, "phone"]]
const CLIENTS := ["ryan", "mike", "ian", "jane", "mary", "lee", "lucy", "bob", "nancy", "sandy", "ultimator", "naomi", "aaron", "oldlady", "maid", "goth", "ex", "cupid", "santa", "alien", "mr_malone", "jesus_jhamal", "zombie"]
const OWN_ITEMS := ["player", "box", "safe", "bong", "vaporizer", "sofa", "panties", "shotgun", "painting", "phone"]
static func level_idx(name: String) -> int:
	for i in LEVELS.size():
		if LEVELS[i][0] == name: return i
	return 0
static func task_info(key: String) -> Array:
	for t in TASKS:
		if t[0] == key: return t
	return []
static func task_index(key: String) -> int:
	for i in TASKS.size():
		if TASKS[i][0] == key: return i
	return -1
static func shop_list(tab: String) -> Array:
	match tab:
		"watering": return WATERING
		"seeds": return SEEDS
		"pots": return POTS
		"fertilizers": return FERTS
		"customize": return CUSTOM
		"vinyl": return VINYL
	return []
static func shop_item(id: String) -> Array:
	for tab in TABS:
		for it in shop_list(tab):
			if it[0] == id: return it
	return []
