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
    
    print("=" * 60)
    print("美术资源替换工具")
    print("=" * 60)
    print()
    
    for filename, dest_path in ASSET_MAPPING.items():
        src_file = source / filename
        dst_file = project / dest_path
        
        if src_file.exists():
            dst_file.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_file, dst_file)
            replaced.append(filename)
            print(f"✓ {filename}")
        else:
            missing.append(filename)
    
    print()
    print("=" * 60)
    print(f"替换完成: {len(replaced)}/{len(ASSET_MAPPING)}")
    
    if missing:
        print(f"缺失文件: {len(missing)}个")
        with open("missing_assets.txt", "w", encoding="utf-8") as f:
            f.write("缺失的美术资源列表:\n")
            f.write("=" * 40 + "\n\n")
            for m in missing:
                f.write(m + "\n")
                print(f"  ✗ {m}")
        print()
        print("已保存缺失列表到 missing_assets.txt")
    else:
        print("✓ 所有资源已就位！")
    
    print("=" * 60)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="替换游戏美术资源")
    parser.add_argument("--source", "-s", required=True, help="新资源目录路径")
    parser.add_argument("--project", "-p", default=".", help="项目目录路径(默认当前目录)")
    args = parser.parse_args()
    
    replace_assets(args.source, args.project)
