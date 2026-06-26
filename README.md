# WarmBarber Demo

一个温暖、简单的横屏理发店游戏 Demo，使用 Godot 4.7 制作。

## Godot 版本

- **Godot 4.7 Stable** (Compatibility renderer)
- GDScript（不使用 C# 或 .NET）
- 无第三方插件

## 启动方式

1. 打开 Godot 4.7
2. 点击 "Import"，选择 `project.godot`
3. 点击 "Run" 或按 F5

或通过命令行：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/yukon.jia/Projects/WarmBarberDemo
```

## 操作方式

| 操作 | 鼠标 | 键盘 |
|------|------|------|
| 移动理发师 | 点击地面目标位置 | A/D 或方向键左右 |
| 与客人交谈 | 靠近后点击"与客人交谈" | 靠近后按 Space/Enter |
| 选择对话选项 | 点击选项按钮 | 点击选项按钮 |
| 选择理发工具 | 点击工具按钮 | 点击工具按钮 |
| 理发 | 点击头发区域 | 点击头发区域 |
| 撤销 | 点击"撤销上一步" | 点击"撤销上一步" |
| 完成理发 | 点击"完成理发" | 点击"完成理发" |

## 目录结构

```
WarmBarberDemo/
├── project.godot
├── assets/          # 资源目录（音频、字体、精灵、UI）
├── data/            # 数据文件
│   ├── customers/   # 客人数据
│   ├── dialogues/   # 对话数据
│   └── hairstyles/  # 发型数据
├── scenes/          # Godot 场景
│   ├── main/        # 主菜单
│   ├── shop/        # 理发店
│   ├── haircut/     # 理发操作
│   ├── result/      # 结果展示
│   ├── characters/  # 角色
│   └── ui/          # UI 组件
├── scripts/         # GDScript 脚本
│   ├── autoload/    # 全局状态
│   ├── main/        # 主菜单逻辑
│   ├── shop/        # 理发店逻辑
│   ├── characters/  # 角色控制器
│   ├── dialogue/    # 对话系统
│   ├── haircut/     # 理发工具和评分
│   ├── result/      # 结果展示
│   └── utilities/   # 工具类
└── tests/           # 测试脚本
```

## 完整游戏流程

1. **主菜单** → 点击"开始营业"
2. **理发店** → 移动到客人李明身边
3. **对话** → 通过三轮选项理解客人需求
4. **理发** → 选择剪刀/电推子/梳子修改五个头发区域
5. **完成** → 确认后进入评分
6. **结果** → 查看评分和客人评价，点击"重新开始营业"

## 评分规则

总分 100 分：

| 项目 | 满分 | 说明 |
|------|------|------|
| 发型匹配度 | 50 | 各区域长度与目标发型的匹配程度 |
| 需求理解度 | 25 | 对话中理解客人隐藏需求的程度 |
| 服务舒适度 | 15 | 操作错误和客人舒适度 |
| 操作效率 | 10 | 理发完成时间 |

评分等级：90+ 非常满意 / 75+ 满意 / 60+ 基本满意 / <60 有些遗憾

## 如何新增客人

1. 在 `data/customers/` 创建 `customer_<id>.json`
2. 在 `data/dialogues/` 创建 `<id>_dialogue.json`
3. 在 `data/hairstyles/` 创建对应的发型文件
4. 在 `scenes/characters/` 创建新的客人场景（可选）

## 如何新增发型

1. 在 `data/hairstyles/` 创建 `<id>.json`，包含五个区域的目标长度
2. 在 `data/customers/` 中对应用户配置 `target_hairstyle_id`

## 如何新增对话

1. 在 `data/dialogues/` 创建 `<id>_dialogue.json`
2. 每个 round 包含 id、speaker、text、options（含效果）和 next_round

## 后续 iOS 导出步骤

1. Godot → Export → Add iOS
2. 配置 Bundle ID、证书、描述文件
3. Export → Xcode Project
4. 在 Xcode 中配置安全区域和横屏
5. 连接真机运行或提交 App Store

## 技术实现说明

- 所有美术资源使用 Godot 内置 ColorRect 和 Polygon2D 原创生成
- 对话系统为自定义轻量 JSON 驱动
- 不使用 Dialogue Manager、Dialogic 或任何第三方插件
- 不使用外部音效或字体
- 所有图片、角色、UI 均为项目内原创代码生成
