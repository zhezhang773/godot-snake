# 贪吃蛇游戏美术资源规格说明书

## 一、项目概述

本项目为 Godot 4 开发的贪吃蛇游戏，计划将所有代码绘制的图形改为可替换的图片素材。

## 二、美术资源总表

### 2.1 蛇身素材 (Snake)

| 序号 | 资源名称 | 文件路径 | 格式 | 类型 | 尺寸(px) | 描述 | 帧数 | 备注 |
|:---:|:---|:---|:---:|:---:|:---:|:---|:---:|:---|
| 1 | snake_head_normal | assets/snake/head_normal.png | PNG | 静态 | 40x40 | 蛇头-正常状态 | 1 | 朝向右，其他方向由代码旋转 |
| 2 | snake_head_eating | assets/snake/head_eating.png | PNG | 静态 | 40x40 | 蛇头-吃食物状态（张嘴） | 1 | 朝向右 |
| 3 | snake_head_ghost | assets/snake/head_ghost.png | PNG | 静态 | 40x40 | 蛇头-幽灵状态（半透明） | 1 | 带透明度 |
| 4 | snake_head_boost | assets/snake/head_boost.png | PNG | 静态 | 40x40 | 蛇头-加速状态（带光晕） | 1 | 发光效果 |
| 5 | snake_body_straight | assets/snake/body_straight.png | PNG | 静态 | 40x40 | 蛇身-直线段 | 1 | 水平方向，代码旋转 |
| 6 | snake_body_curve | assets/snake/body_curve.png | PNG | 静态 | 40x40 | 蛇身-转弯段 | 1 | 左上到右下弯，代码翻转 |
| 7 | snake_tail | assets/snake/tail.png | PNG | 静态 | 40x40 | 蛇尾 | 1 | 朝向右，代码旋转 |
| 8 | snake_body_burning | assets/snake/body_burning.png | PNG | 动画 | 40x40 | 蛇身-燃烧状态 | 4 | 逐帧动画，循环播放 |

### 2.2 食物素材 (Food)

| 序号 | 资源名称 | 文件路径 | 格式 | 类型 | 尺寸(px) | 描述 | 帧数 | 备注 |
|:---:|:---|:---|:---:|:---:|:---:|:---|:---:|:---|
| 9 | food_normal | assets/food/normal.png | PNG | 动画 | 40x40 | 普通食物 | 8 | 呼吸动画，循环 |
| 10 | food_normal_blink | assets/food/normal_blink.png | PNG | 动画 | 40x40 | 普通食物-即将过期 | 4 | 闪烁动画 |
| 11 | food_trap | assets/food/trap.png | PNG | 动画 | 40x40 | 炸弹陷阱食物 | 8 | 带倒计时数字闪烁 |
| 12 | food_trap_revealed | assets/food/trap_revealed.png | PNG | 动画 | 40x40 | 炸弹陷阱-已揭示 | 4 | 红色警告闪烁 |
| 13 | food_special_ghost | assets/food/special_ghost.png | PNG | 动画 | 40x40 | 特殊果实-幽灵 | 8 | 带"G"字，紫色光晕 |
| 14 | food_special_shield | assets/food/special_shield.png | PNG | 动画 | 40x40 | 特殊果实-护盾 | 8 | 带"S"字，金色光晕 |
| 15 | food_special_rain | assets/food/special_rain.png | PNG | 动画 | 40x40 | 特殊果实-食物雨 | 8 | 带"F"字，橙色光晕 |
| 16 | food_special_pass | assets/food/special_pass.png | PNG | 动画 | 40x40 | 特殊果实-穿墙 | 8 | 带"P"字，紫色光晕 |
| 17 | food_special_speedup | assets/food/special_speedup.png | PNG | 动画 | 40x40 | 特殊果实-加速 | 8 | 双箭头图标，红色 |
| 18 | food_special_speeddown | assets/food/special_speeddown.png | PNG | 动画 | 40x40 | 特殊果实-减速 | 8 | 双箭头图标，蓝色 |
| 19 | food_special_magma | assets/food/special_magma.png | PNG | 动画 | 40x40 | 特殊果实-岩浆 | 8 | 火焰图标，金黄色 |

### 2.3 地形素材 (Terrain)

| 序号 | 资源名称 | 文件路径 | 格式 | 类型 | 尺寸(px) | 描述 | 帧数 | 备注 |
|:---:|:---|:---|:---:|:---:|:---:|:---|:---:|:---|
| 20 | terrain_ground | assets/terrain/ground.png | PNG | 静态 | 40x40 | 普通地面 | 1 | 棋盘格纹理 |
| 21 | terrain_forest_01 | assets/terrain/forest_01.png | PNG | 静态 | 40x40 | 森林-变体1 | 1 | 密林风格 |
| 22 | terrain_forest_02 | assets/terrain/forest_02.png | PNG | 静态 | 40x40 | 森林-变体2 | 1 | 大树冠风格 |
| 23 | terrain_forest_03 | assets/terrain/forest_03.png | PNG | 静态 | 40x40 | 森林-变体3 | 1 | 灌木风格 |
| 24 | terrain_forest_04 | assets/terrain/forest_04.png | PNG | 静态 | 40x40 | 森林-变体4 | 1 | 深色丛林 |
| 25 | terrain_river_01 | assets/terrain/river_01.png | PNG | 动画 | 40x40 | 河流-水平流动 | 8 | 波浪动画 |
| 26 | terrain_river_02 | assets/terrain/river_02.png | PNG | 动画 | 40x40 | 河流-垂直流动 | 8 | 波浪动画 |
| 27 | terrain_river_03 | assets/terrain/river_03.png | PNG | 动画 | 40x40 | 河流-波纹 | 8 | 水波纹效果 |
| 28 | terrain_river_04 | assets/terrain/river_04.png | PNG | 动画 | 40x40 | 河流-湍流 | 8 | 快速流动 |
| 29 | terrain_river_05 | assets/terrain/river_05.png | PNG | 动画 | 40x40 | 河流-涟漪 | 8 | 慢速流动 |
| 30 | terrain_mountain | assets/terrain/mountain.png | PNG | 静态 | 40x40 | 山体 | 1 | 棕褐色山丘 |
| 31 | terrain_volcano | assets/terrain/volcano.png | PNG | 动画 | 40x40 | 火山 | 8 | 带流动岩浆 |
| 32 | terrain_magma | assets/terrain/magma.png | PNG | 动画 | 40x40 | 岩浆 | 8 | 火红流动效果 |

### 2.4 虫洞素材 (Wormhole)

| 序号 | 资源名称 | 文件路径 | 格式 | 类型 | 尺寸(px) | 描述 | 帧数 | 备注 |
|:---:|:---|:---|:---:|:---:|:---:|:---|:---:|:---|
| 33 | wormhole_blue | assets/wormhole/blue.png | PNG | 动画 | 40x40 | 蓝色虫洞 | 12 | 漩涡动画，循环 |
| 34 | wormhole_pink | assets/wormhole/pink.png | PNG | 动画 | 40x40 | 粉色虫洞 | 12 | 漩涡动画，循环 |

### 2.5 大门素材 (Gate)

| 序号 | 资源名称 | 文件路径 | 格式 | 类型 | 尺寸(px) | 描述 | 帧数 | 备注 |
|:---:|:---|:---|:---:|:---:|:---:|:---|:---:|:---|
| 35 | gate_closed | assets/gate/closed.png | PNG | 静态 | 40x40 | 关闭的大门 | 1 | 灰色石质 |
| 36 | gate_open | assets/gate/open.png | PNG | 动画 | 40x40 | 打开的大门 | 8 | 金色拱门，脉冲发光 |
| 37 | gate_arrow | assets/gate/arrow.png | PNG | 动画 | 40x40 | 向上箭头指示 | 4 | 上下浮动 |

### 2.6 粒子特效素材 (Effects)

| 序号 | 资源名称 | 文件路径 | 格式 | 类型 | 尺寸(px) | 描述 | 帧数 | 备注 |
|:---:|:---|:---|:---:|:---:|:---:|:---|:---:|:---|
| 38 | effect_particle_food | assets/effects/particle_food.png | PNG | 静态 | 8x8 | 吃食物的粒子 | 1 | 小圆点 |
| 39 | effect_particle_boost | assets/effects/particle_boost.png | PNG | 静态 | 8x8 | 加速粒子 | 1 | 星形 |
| 40 | effect_particle_burn | assets/effects/particle_burn.png | PNG | 动画 | 16x16 | 燃烧火花 | 6 | 火焰粒子 |
| 41 | effect_particle_wormhole | assets/effects/particle_wormhole.png | PNG | 静态 | 12x12 | 虫洞传送粒子 | 1 | 蓝色光点 |
| 42 | effect_floating_text_bg | assets/effects/text_bg.png | PNG | 静态 | 64x32 | 浮动文字背景 | 1 | 半透明底板 |

### 2.7 UI界面素材 (UI)

| 序号 | 资源名称 | 文件路径 | 格式 | 类型 | 尺寸(px) | 描述 | 帧数 | 备注 |
|:---:|:---|:---|:---:|:---:|:---:|:---|:---:|:---|
| 43 | ui_panel_bg | assets/ui/panel_bg.png | PNG | 静态 | 200x150 | 面板背景 | 1 | 半透明深色 |
| 44 | ui_button_normal | assets/ui/button_normal.png | PNG | 静态 | 120x40 | 按钮-正常 | 1 | 圆角矩形 |
| 45 | ui_button_hover | assets/ui/button_hover.png | PNG | 静态 | 120x40 | 按钮-悬停 | 1 | 高亮效果 |
| 46 | ui_button_pressed | assets/ui/button_pressed.png | PNG | 静态 | 120x40 | 按钮-按下 | 1 | 凹陷效果 |
| 47 | ui_combo_segment_1 | assets/ui/combo_1.png | PNG | 静态 | 24x24 | 连击计数器-1格 | 1 | 蓝色 |
| 48 | ui_combo_segment_2 | assets/ui/combo_2.png | PNG | 静态 | 24x24 | 连击计数器-2格 | 1 | 绿色 |
| 49 | ui_combo_segment_3 | assets/ui/combo_3.png | PNG | 静态 | 24x24 | 连击计数器-3格 | 1 | 黄色 |
| 50 | ui_combo_segment_4 | assets/ui/combo_4.png | PNG | 静态 | 24x24 | 连击计数器-4格 | 1 | 橙色 |
| 51 | ui_combo_segment_5 | assets/ui/combo_5.png | PNG | 静态 | 24x24 | 连击计数器-5格 | 1 | 红色，发光 |
| 52 | ui_effect_ghost | assets/ui/effect_ghost.png | PNG | 静态 | 100x24 | 状态条-幽灵 | 1 | 紫色条 |
| 53 | ui_effect_shield | assets/ui/effect_shield.png | PNG | 静态 | 100x24 | 状态条-护盾 | 1 | 黄色条 |
| 54 | ui_effect_pass | assets/ui/effect_pass.png | PNG | 静态 | 100x24 | 状态条-穿墙 | 1 | 紫色条 |
| 55 | ui_effect_magma | assets/ui/effect_magma.png | PNG | 静态 | 100x24 | 状态条-岩浆果实 | 1 | 橙红条 |

### 2.8 背景素材 (Background)

| 序号 | 资源名称 | 文件路径 | 格式 | 类型 | 尺寸(px) | 描述 | 帧数 | 备注 |
|:---:|:---|:---|:---:|:---:|:---:|:---|:---:|:---|
| 56 | bg_pattern | assets/background/pattern.png | PNG | 静态 | 400x400 | 背景图案 | 1 | 可平铺 |
| 57 | bg_menu | assets/background/menu.png | PNG | 静态 | 860x860 | 菜单背景 | 1 | 主菜单 |
| 58 | bg_gameover | assets/background/gameover.png | PNG | 静态 | 860x860 | 游戏结束背景 | 1 | 暗色调 |

### 2.9 图标素材 (Icon)

| 序号 | 资源名称 | 文件路径 | 格式 | 类型 | 尺寸(px) | 描述 | 帧数 | 备注 |
|:---:|:---|:---|:---:|:---:|:---:|:---|:---:|:---|
| 59 | icon_app | assets/icon.png | PNG | 静态 | 256x256 | 应用图标 | 1 | 游戏启动图标 |
| 60 | icon_pause | assets/ui/icon_pause.png | PNG | 静态 | 32x32 | 暂停图标 | 1 | 暂停菜单用 |

---

## 三、一键替换方案

### 3.1 目录结构

```
assets/
├── snake/          # 蛇身素材
├── food/           # 食物素材
├── terrain/        # 地形素材
├── wormhole/       # 虫洞素材
├── gate/           # 大门素材
├── effects/        # 特效素材
├── ui/             # UI素材
└── background/     # 背景素材
```

### 3.2 替换脚本

创建 `tools/replace_assets.py`：

```python
#!/usr/bin/env python3
"""
美术资源一键替换工具
用法: python replace_assets.py --source <新资源目录>
"""

import shutil
import argparse
from pathlib import Path

# 资源映射表
ASSET_MAPPING = {
    # 蛇身
    "snake_head_normal.png": "assets/snake/head_normal.png",
    "snake_head_eating.png": "assets/snake/head_eating.png",
    "snake_head_ghost.png": "assets/snake/head_ghost.png",
    "snake_head_boost.png": "assets/snake/head_boost.png",
    "snake_body_straight.png": "assets/snake/body_straight.png",
    "snake_body_curve.png": "assets/snake/body_curve.png",
    "snake_tail.png": "assets/snake/tail.png",
    "snake_body_burning.png": "assets/snake/body_burning.png",
    
    # 食物
    "food_normal.png": "assets/food/normal.png",
    "food_normal_blink.png": "assets/food/normal_blink.png",
    "food_trap.png": "assets/food/trap.png",
    "food_trap_revealed.png": "assets/food/trap_revealed.png",
    "food_special_ghost.png": "assets/food/special_ghost.png",
    "food_special_shield.png": "assets/food/special_shield.png",
    "food_special_rain.png": "assets/food/special_rain.png",
    "food_special_pass.png": "assets/food/special_pass.png",
    "food_special_speedup.png": "assets/food/special_speedup.png",
    "food_special_speeddown.png": "assets/food/special_speeddown.png",
    "food_special_magma.png": "assets/food/special_magma.png",
    
    # 地形
    "terrain_ground.png": "assets/terrain/ground.png",
    "terrain_forest_01.png": "assets/terrain/forest_01.png",
    "terrain_forest_02.png": "assets/terrain/forest_02.png",
    "terrain_forest_03.png": "assets/terrain/forest_03.png",
    "terrain_forest_04.png": "assets/terrain/forest_04.png",
    "terrain_river_01.png": "assets/terrain/river_01.png",
    "terrain_river_02.png": "assets/terrain/river_02.png",
    "terrain_river_03.png": "assets/terrain/river_03.png",
    "terrain_river_04.png": "assets/terrain/river_04.png",
    "terrain_river_05.png": "assets/terrain/river_05.png",
    "terrain_mountain.png": "assets/terrain/mountain.png",
    "terrain_volcano.png": "assets/terrain/volcano.png",
    "terrain_magma.png": "assets/terrain/magma.png",
    
    # 虫洞
    "wormhole_blue.png": "assets/wormhole/blue.png",
    "wormhole_pink.png": "assets/wormhole/pink.png",
    
    # 大门
    "gate_closed.png": "assets/gate/closed.png",
    "gate_open.png": "assets/gate/open.png",
    "gate_arrow.png": "assets/gate/arrow.png",
    
    # 特效
    "effect_particle_food.png": "assets/effects/particle_food.png",
    "effect_particle_boost.png": "assets/effects/particle_boost.png",
    "effect_particle_burn.png": "assets/effects/particle_burn.png",
    "effect_particle_wormhole.png": "assets/effects/particle_wormhole.png",
    "effect_floating_text_bg.png": "assets/effects/text_bg.png",
    
    # UI
    "ui_panel_bg.png": "assets/ui/panel_bg.png",
    "ui_button_normal.png": "assets/ui/button_normal.png",
    "ui_button_hover.png": "assets/ui/button_hover.png",
    "ui_button_pressed.png": "assets/ui/button_pressed.png",
    "ui_combo_segment_1.png": "assets/ui/combo_1.png",
    "ui_combo_segment_2.png": "assets/ui/combo_2.png",
    "ui_combo_segment_3.png": "assets/ui/combo_3.png",
    "ui_combo_segment_4.png": "assets/ui/combo_4.png",
    "ui_combo_segment_5.png": "assets/ui/combo_5.png",
    "ui_effect_ghost.png": "assets/ui/effect_ghost.png",
    "ui_effect_shield.png": "assets/ui/effect_shield.png",
    "ui_effect_pass.png": "assets/ui/effect_pass.png",
    "ui_effect_magma.png": "assets/ui/effect_magma.png",
    
    # 背景
    "bg_pattern.png": "assets/background/pattern.png",
    "bg_menu.png": "assets/background/menu.png",
    "bg_gameover.png": "assets/background/gameover.png",
    
    # 图标
    "icon_app.png": "assets/icon.png",
    "icon_pause.png": "assets/ui/icon_pause.png",
}

def replace_assets(source_dir: str, project_dir: str = "."):
    """替换美术资源"""
    source = Path(source_dir)
    project = Path(project_dir)
    
    replaced = []
    missing = []
    
    for filename, dest_path in ASSET_MAPPING.items():
        src_file = source / filename
        dst_file = project / dest_path
        
        if src_file.exists():
            dst_file.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_file, dst_file)
            replaced.append(filename)
            print(f"✓ {filename} -> {dest_path}")
        else:
            missing.append(filename)
            print(f"✗ 缺失: {filename}")
    
    print(f"\n替换完成: {len(replaced)}/{len(ASSET_MAPPING)}")
    if missing:
        print(f"缺失文件: {len(missing)}个")
        with open("missing_assets.txt", "w") as f:
            for m in missing:
                f.write(m + "\n")
        print("已保存缺失列表到 missing_assets.txt")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="替换游戏美术资源")
    parser.add_argument("--source", "-s", required=True, help="新资源目录路径")
    parser.add_argument("--project", "-p", default=".", help="项目目录路径")
    args = parser.parse_args()
    
    replace_assets(args.source, args.project)
```

### 3.3 使用方法

1. 准备新资源，按表格命名放入一个目录（如 `new_assets/`）
2. 运行替换脚本：
   ```bash
   python tools/replace_assets.py --source new_assets/
   ```
3. 检查 `missing_assets.txt` 查看缺失文件

---

## 四、技术注意事项

### 4.1 图片格式要求
- **静态图片**: PNG，支持透明度
- **动画图片**: PNG 序列帧 或 带通道的 PNG 精灵表
- **建议**: 所有图片使用 2 的幂次方尺寸（便于 GPU 优化）

### 4.2 颜色空间
- 使用 sRGB 颜色空间
- 避免使用纯黑 (#000000) 和纯白 (#FFFFFF) 作为透明色

### 4.3 性能建议
- 动画帧率：游戏内使用 12 FPS
- 建议合并小图到精灵表（Sprite Sheet）以减少 Draw Call

---

*文档版本: 1.0*
*创建日期: 2026-03-28*
