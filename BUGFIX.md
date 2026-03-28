# 特殊果实问题修复报告

## 问题描述
试玩时发现特殊果实没有出现。

## 根本原因

### 1. 生成概率和持续时间太保守
- **原始值：**
  - `SPECIAL_SPAWN_CHANCE = 0.20` (20% 生成概率)
  - `SPECIAL_FOOD_DURATION = 5.0` (5 秒持续时间)

- **问题：** 玩家可能玩很久都没碰到特殊果实，或者即使生成了也因为持续时间太短没注意到

### 2. 音效播放位置错误
- **问题：** 特殊果实出现时没有播放音效提示
- **Bug：** `play_special_appear()` 被错误地放在了 `_eat_special_fruit()` 函数末尾（吃掉果实时播放），而不是 `_try_spawn_special()` 函数中（出现时播放）

### 3. 吃掉特殊果实时无音效
- **问题：** `_eat_special_fruit()` 函数没有播放音效，导致玩家不知道吃到了特殊果实

## 修复内容

### 1. 调整参数（Main.gd 第 10-14 行）
```gdscript
# 修改前
const SPECIAL_SPAWN_CHANCE: float = 0.20
const SPECIAL_FOOD_DURATION: float = 5.0

# 修改后
const SPECIAL_SPAWN_CHANCE: float = 0.50  # 提高到 50%
const SPECIAL_FOOD_DURATION: float = 10.0  # 增加到 10 秒
```

### 2. 修复音效播放（Main.gd 第 1064-1071 行）
```gdscript
func _try_spawn_special() -> void:
    var available: Array[Vector2i] = _get_available_cells()
    if available.is_empty():
        return
    special_pos = available[randi() % available.size()]
    special_type = randi() % SPECIAL_TYPE_COUNT
    special_active = true
    special_timer = SPECIAL_FOOD_DURATION
    if audio_manager:
        audio_manager.play_special_appear()  # 新增：播放出现音效
```

### 3. 移除错误音效调用（Main.gd 第 1017 行）
```gdscript
# 修改前
special_active = false
special_timer = 0.0
if audio_manager:
    audio_manager.play_special_appear()  # 错误：吃掉时播放出现音效

# 修改后
special_active = false
special_timer = 0.0
```

### 4. 添加吃果实音效（Main.gd 第 984-985 行）
```gdscript
func _eat_special_fruit(pos: Vector2i) -> void:
    var bonus: int = SPECIAL_FOOD_SCORE + combo * 5
    score += bonus
    combo += 1
    combo_timer = 8.0

    eating_anim_timer = 0.3
    _spawn_particles(pos, Color(1.0, 0.85, 0.2), 25, 150.0)
    _spawn_floating_text("+%d" % bonus, pos, Color(1.0, 0.85, 0.2), 22)

    if audio_manager:
        audio_manager.play_eat_fruit()  # 新增：播放吃果实音效
```

## 测试建议

1. **重启游戏** - 在 Godot 中按 F5 重新运行
2. **观察 30 秒以上** - 以 50% 的概率，应该很快就能看到特殊果实
3. **听音效** - 特殊果实出现时应该有闪烁音效，吃掉时有吃水果音效
4. **识别外观** - 特殊果实会显示字母（G/S/F/P）或箭头（↑↓），并有闪烁动画

## 特殊果实类型

- **[G] Ghost** (紫色) - 穿过自己身体 20 秒
- **[S] Soft Wall** (金色) - 墙壁免疫 15 秒
- **[F] Rain** (橙色) - 食物雨，生成 4-8 个额外食物
- **[P] Pass** (紫色) - 穿墙 15 秒
- **[↑] Speed Up** (橙色) - 加速
- **[↓] Speed Down** (蓝色) - 减速（速度过低会死亡）

## 后续优化建议

如果觉得 50% 的生成概率太高，可以调整为：
- 保守模式：`SPECIAL_SPAWN_CHANCE = 0.30` (30%)
- 平衡模式：`SPECIAL_SPAWN_CHANCE = 0.40` (40%)
- 激进模式：`SPECIAL_SPAWN_CHANCE = 0.60` (60%)

---

修复时间：2026-03-25
Godot 版本：4.5
