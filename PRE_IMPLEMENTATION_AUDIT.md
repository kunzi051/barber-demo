# PRE_IMPLEMENTATION_AUDIT

## 项目状态（修改前基线）

### 主场景
`res://scenes/main/main_menu.tscn` → `barber_shop.tscn` → `haircut_scene.tscn` → `result_scene.tscn`

### GameState 字段（scripts/autoload/game_state.gd）
- dialogue_understanding_score: int
- customer_trust: int
- revealed_hidden_need: bool
- current_hair_state: Dictionary (bangs/top/left_side/right_side/back + parting/styled)
- target_hair_state: Dictionary
- haircut_action_count: int
- mistake_count: int
- elapsed_haircut_time: float
- final_score: int
- score_breakdown: Dictionary
- customer_feedback: String

### 对话系统（scripts/dialogue/dialogue_controller.gd）
- 使用 _process 逐字显示，非 Tween
- 状态管理不完善（仅 is_type_writing/text_revealed/waiting_for_next/dialogue_complete）
- _gui_input 点击完成逐字后直接调用 _show_options
- 选项按钮无防连点保护
- 输入事件未调用 accept_event()

### 理发场景（scripts/haircut/haircut_controller.gd）
- `selected_tool` 默认 "scissors"，无"未选择"状态
- 反馈仅文字，无动画
- 梳子永远设 parting="left"
- 区域无点击动画
- 操作反馈仅一行文字，无"旧长度→新长度"显示
- 无碎屑效果

### 评分脚本（scripts/haircut/haircut_scoring.gd）
- 权重硬编码（bangs=7, top=11, left=8, right=8, back=6）
- 侧分/定型固定5分
- 反馈硬编码针对李明

### 结果场景（scripts/result/result_controller.gd）
- 无前后发型对比
- 仅一个按钮："重新开始营业"
- 顾客姓名未动态显示

### 角色（scripts/characters/customer_controller.gd）
- 颜色完全硬编码
- 无情绪系统
- 嘴部仅一个静态矩形

### 数据文件
- customers/ 仅 customer_li_ming.json
- dialogues/ 仅 li_ming_dialogue.json
- hairstyles/ 仅 interview_side_part.json
- 无 scoring/ 或 feedback/ 目录

### 已知硬编码位置
1. `dialogue_panel.tscn:37` - "李明"
2. `haircut_scene.tscn:42` - "客人：李明"
3. `haircut_scene.tscn:52` - "需求：稍微剪短，精神一些"
4. `barber_shop.gd:33` - customer 位置硬编码
5. `barber_shop.gd:143` - `"li_ming"` 硬编码
6. `dialogue_controller.gd:27` - "李明"
7. `haircut_controller.gd:44` - "客人：李明"
8. `haircut_controller.gd:219-221` - 需求提示硬编码
9. `haircut_scoring.gd:46-52` - 权重硬编码
10. `haircut_scoring.gd:137-174` - 反馈硬编码

### 当前能正常运行
✅ Godot 4.7 headless 模式无报错
✅ 完整场景切换链路
✅ 对话→理发→评分→重新开始
