extends Node
class_name LocalizationManager

## Global localization singleton. Autoloaded as "Loc".
## Usage:  Loc.t("key")  → returns translated string for current language.

var current_language: String = "en"

signal language_changed(new_language: String)

# =========================================================
# Translation Table
# =========================================================
var _translations: Dictionary = {
	# ---- Main Menu ----
	"menu_title":           {"en": "SNAKE",               "zh": "贪吃蛇"},
	"menu_tagline":         {"en": "A Classic Snake Game","zh": "经典贪吃蛇游戏"},
	"menu_start":           {"en": "Start Game",          "zh": "开始游戏"},
	"menu_highscore":       {"en": "High Score",          "zh": "最高分"},
	"menu_help":            {"en": "Help",                "zh": "帮助"},
	"menu_quit":            {"en": "Quit",                "zh": "退出"},
	"menu_navigate":        {"en": "↑↓  Navigate     Enter  Select",  "zh": "↑↓  导航     回车  选择"},
	"menu_version":         {"en": "v2.0  ·  Godot 4.5", "zh": "v2.0  ·  Godot 4.5"},

	# ---- Help Screen ----
	"help_title":           {"en": "HELP",                "zh": "帮助"},
	"help_controls":        {"en": "CONTROLS",            "zh": "操控"},
	"help_key_move":        {"en": "WASD / Arrow Keys",   "zh": "WASD / 方向键"},
	"help_val_move":        {"en": "Move",                "zh": "移动"},
	"help_key_boost":       {"en": "Hold Direction 0.5s", "zh": "按住方向0.5秒"},
	"help_val_boost":       {"en": "BOOST x2 speed",      "zh": "加速x2"},
	"help_key_pause":       {"en": "ESC",                 "zh": "ESC"},
	"help_val_pause":       {"en": "Pause / Back",        "zh": "暂停 / 返回"},
	"help_key_restart":     {"en": "SPACE",               "zh": "空格"},
	"help_key_mobile":      {"en": "Touch Screen",        "zh": "触屏"},
	"help_val_restart":     {"en": "Restart (Game Over)", "zh": "重新开始（游戏结束时）"},
	"help_timed_fruits":    {"en": "TIMED FRUITS",        "zh": "限时果实"},
	"help_ghost_key":       {"en": "[G] Ghost",           "zh": "[G] 穿身"},
	"help_ghost_val":       {"en": "Pass through self  (%ds)", "zh": "穿透自身 (%d秒)"},
	"help_shield_key":      {"en": "[S] Soft Wall",       "zh": "[S] 软墙"},
	"help_shield_val":      {"en": "Wall immunity  (%ds)","zh": "墙壁免疫 (%d秒)"},
	"help_rain_key":        {"en": "[F] Rain",            "zh": "[F] 食物雨"},
	"help_rain_val":        {"en": "Spawn 4~8 extra foods","zh": "生成4~8个额外食物"},
	"help_pass_key":        {"en": "[P] Pass",            "zh": "[P] 穿墙"},
	"help_pass_val":        {"en": "Wrap through walls  (%ds)","zh": "穿越墙壁 (%d秒)"},
	"help_instant_fruits":  {"en": "INSTANT FRUITS",      "zh": "即时果实"},
	"help_speedup_key":     {"en": "[U] Speed Up",        "zh": "[U] 加速"},
	"help_speedup_val":     {"en": "Move faster  (+%.3f)","zh": "移动更快 (+%.3f)"},
	"help_speeddown_key":   {"en": "[D] Speed Down",      "zh": "[D] 减速"},
	"help_speeddown_val":   {"en": "Move slower  (0 = death)","zh": "移动更慢 (0=死亡)"},
	"help_danger":          {"en": "DANGER",              "zh": "危险"},
	"help_bomb_key":        {"en": "Bomb Traps",          "zh": "炸弹陷阱"},
	"help_bomb_val":        {"en": "Disguised as food, -%d pts","zh": "伪装成食物，-%d分"},
	"help_reveal_key":      {"en": "Reveal",              "zh": "揭示"},
	"help_reveal_val":      {"en": "Within 3 cells (Chebyshev)","zh": "3格范围内（切比雪夫距离）"},
	"help_fullshrink_key":  {"en": "Full Shrink",         "zh": "完全缩小"},
	"help_fullshrink_val":  {"en": "Snake fully shrunk = death","zh": "蛇完全缩小=死亡"},
	"help_scoring":         {"en": "SCORING",             "zh": "计分"},
	"help_normal_food_key": {"en": "Normal Food",         "zh": "普通食物"},
	"help_normal_food_val": {"en": "+10 pts",             "zh": "+10分"},
	"help_special_food_key":{"en": "Special Fruit",       "zh": "特殊果实"},
	"help_special_food_val":{"en": "+%d pts + combo bonus","zh": "+%d分 + 连击奖励"},
	"help_combo_key":       {"en": "Combo x3+",           "zh": "连击 x3+"},
	"help_combo_val":       {"en": "Extra bonus (within 3s)","zh": "额外奖励（3秒内）"},
	"help_back":            {"en": "Press  ESC / Enter  to go back","zh": "按 ESC / 回车 返回"},
	"help_wormhole":       {"en": "Wormholes",           "zh": "虫洞"},
	"help_wormhole_val":   {"en": "Enter one, exit the pair","zh": "进入一个，从配对出来"},

	# ---- High Score Screen ----
	"hs_title":             {"en": "HIGH SCORE",          "zh": "最高分"},
	"hs_best":              {"en": "BEST",                "zh": "最佳"},
	"hs_no_scores":         {"en": "No scores yet. Start playing!","zh": "暂无分数，开始游戏吧！"},
	"hs_total_food":        {"en": "Total Food Eaten: %d","zh": "总共吃掉食物: %d"},

	# ---- Game HUD ----
	"ui_score":             {"en": "Score: %d",           "zh": "分数: %d"},
	"ui_total":             {"en": "Total: %d",           "zh": "总计: %d"},
	"ui_best":              {"en": "Best: %d",            "zh": "最高: %d"},
	"ui_speed":             {"en": "Speed: %.3fs",         "zh": "速度: %.3fs"},
	"ui_level":             {"en": "Lv.%d",                 "zh": "第%d关"},
	"ui_gate_closed":       {"en": "Gate %d/%d",             "zh": "大门 %d/%d"},
	"ui_gate_open":         {"en": "Gate OPEN!",            "zh": "大门已开!"},
	"gameover_level":       {"en": "Level: %d",             "zh": "关卡: %d"},
	"gameover_level_score": {"en": "This Level: %d",         "zh": "本关分数: %d"},
	"float_levelup":        {"en": "LEVEL %d!",             "zh": "第%d关!"},
	"ui_combo":             {"en": "Combo x%d!",          "zh": "连击 x%d！"},

	# ---- Effect bars ----
	"effect_ghost":         {"en": "Ghost",               "zh": "穿身"},
	"effect_shield":        {"en": "Soft Wall",           "zh": "软墙"},
	"effect_pass":          {"en": "Pass",                "zh": "穿墙"},
	"effect_bomb":          {"en": "Bomb",                "zh": "炸弹"},
	"effect_bar_format":    {"en": "%s %s %ds",           "zh": "%s %s %d秒"},

	# ---- Boost indicator ----
	"boost_charging":       {"en": "CHARGING... %.1fs",   "zh": "蓄力中... %.1f秒"},
	"boost_active":         {"en": ">> BOOST x2 <<",      "zh": ">> 加速 x2 <<"},

	# ---- Pause screen ----
	"paused_title":         {"en": "PAUSED",              "zh": "已暂停"},
	"paused_continue":      {"en": "Continue",            "zh": "继续游戏"},
	"paused_return_menu":   {"en": "Return to Menu",      "zh": "返回主菜单"},

	# ---- Game Over screen ----
	"gameover_title":       {"en": "GAME OVER",           "zh": "游戏结束"},
	"gameover_boom":        {"en": "BOOM!",               "zh": "爆炸！"},
	"gameover_frozen":      {"en": "FROZEN!",             "zh": "冻结！"},
	"gameover_bomb_sub":    {"en": "You got fully shrunk!","zh": "你的蛇完全缩小了！"},
	"gameover_wall_sub":    {"en": "You hit the wall!",   "zh": "你撞墙了！"},
	"gameover_self_sub":    {"en": "You bit yourself!",   "zh": "你咬到自己了！"},
	"gameover_frozen_sub":  {"en": "Your speed reached zero!","zh": "你的速度降到了零！"},
	"gameover_mountain":    {"en": "CRASHED!",            "zh": "撞山！"},
	"gameover_mountain_sub":{"en": "You hit a mountain!", "zh": "你撞到山体了！"},
	"gameover_score":       {"en": "Score: %d",           "zh": "分数: %d"},
	"gameover_stats":       {"en": "Length: %d  |  Food: %d","zh": "长度: %d  |  食物: %d"},
	"gameover_new_high":    {"en": "NEW HIGH SCORE!",     "zh": "新最高分！"},
	"gameover_best":        {"en": "Best: %d",            "zh": "最高: %d"},
	"gameover_combo":       {"en": "Max Combo: x%d",      "zh": "最高连击: x%d"},
	"gameover_restart":     {"en": "SPACE  Restart    ESC  Menu","zh": "空格  重新开始    ESC  菜单"},
	"gameover_new_game":    {"en": "New Game",              "zh": "新游戏"},
	"gameover_quit":        {"en": "Quit",                  "zh": "退出"},
	"mobile_swipe":        {"en": "Swipe to control direction","zh": "滑动控制方向"},

	# ---- Floating texts ----
	"float_ghost":          {"en": "GHOST!",              "zh": "穿身！"},
	"float_shield":         {"en": "SOFT WALL!",          "zh": "软墙！"},
	"float_rain":           {"en": "RAIN!",               "zh": "食物雨！"},
	"float_wallpass":       {"en": "WALL PASS!",          "zh": "穿墙！"},
	"float_speedup":        {"en": "SPEED +",             "zh": "加速 +"},
	"float_speeddown":      {"en": "SPEED -",             "zh": "减速 -"},
	"float_seg":            {"en": "-%d seg",             "zh": "-%d 节"},
	"float_wormhole":       {"en": "WARP!",               "zh": "穿越！"},
}

# =========================================================
# Lifecycle
# =========================================================

func _ready() -> void:
	var file = FileAccess.open("user://snake_language.txt", FileAccess.READ)
	if file:
		var lang = file.get_as_text().strip_edges()
		if lang == "zh" or lang == "en":
			current_language = lang
		file.close()

# =========================================================
# Public API
# =========================================================

## Switch between English and Chinese.
func switch_language() -> void:
	current_language = "zh" if current_language == "en" else "en"
	var file = FileAccess.open("user://snake_language.txt", FileAccess.WRITE)
	if file:
		file.store_string(current_language)
		file.close()
	language_changed.emit(current_language)

## Translate a key to current language.
func t(key: String) -> String:
	var dict: Dictionary = _translations.get(key, {})
	return dict.get(current_language, dict.get("en", key))
