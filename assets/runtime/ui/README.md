# 运行时 UI 资源目录规范

更新日期：`2026-08-20`

本目录只保存 Godot 当前运行所需的正式 UI 资源。效果图、母版、切图过程文件、QA 图片和历史版本分别保存在 `art/production/`、`art/ai_generated/`、`art/ui_slices/` 或其他历史归档目录，不得混入运行目录。

运行状态以当前可达的代码、场景、TRES 和项目配置引用为准；历史清单或 Manifest 与实际引用冲突时，以当前运行引用为准，并更新清单。

## 1. 标准目录结构

```text
assets/runtime/ui/
├─ interfaces/                 独立界面专属资源
│  └─ <interface_id>/
│     ├─ backplates/           面板、底板、标题底板
│     ├─ buttons/              该界面专属按钮及状态
│     ├─ icons/                该界面专属图标
│     ├─ decorations/          该界面专属装饰
│     ├─ states/               选中、锁定、禁用等状态图
│     ├─ standalone/           不进入普通图集的大图或特殊纹理
│     ├─ atlases/              该界面生成的图集图片
│     └─ atlas_regions/        指向图集区域的 AtlasTexture TRES
├─ components/                 可跨界面复用的玩法组件资源
│  └─ <component_id>/
│     ├─ atlases/
│     └─ atlas_regions/
└─ shared/                     全局通用 UI 视觉语言
   ├─ buttons/
   ├─ controls/
   ├─ icons/
   ├─ decorations/
   ├─ atlases/
   └─ atlas_regions/
```

不要求为每个模块创建全部子目录；只建立实际需要的目录。目录名称使用稳定的功能 ID，不带 `v01`、`v02` 等版本号，版本写在资源文件名中。

建议的独立界面 ID 包括：

```text
loading
main_hub
battle
settlement
pause
confirm
settings
daily_program
benefits
first_purchase
piggy_bank
shop
imprint_choice
crystal_card_choice
level_complete
```

## 2. 三类资源的职责

### `interfaces/`：独立界面专属

满足以下条件时归入对应界面目录：

- 只服务一个可独立打开、关闭或切换的界面；
- 其构图、尺寸、状态或交互语义与该界面绑定；
- 修改它时，预期只影响该界面。

全屏背景、界面外壳和大尺寸图片仍属于对应界面，但应放入该界面的 `standalone/`，不因为无法入图集而放进 `shared/`。

### `components/`：玩法功能组件

组件资源会被多个界面或战斗逻辑复用，但它们表达的是具体玩法对象，而不是通用 UI 皮肤。例如：

- 卡牌图标、卡背和星级；
- 棋盘块、棋盘数字和字母；
- 水晶塔等级外观；
- 其他具有固定玩法身份的可复用组件。

组件不得为了某个界面的图集方便而复制进该界面目录。界面应直接引用组件的唯一正式资源或对应 AtlasTexture。

### `shared/`：全局通用

只有满足以下任一条件的资源才进入 `shared/`：

- 被两个或以上独立界面共同使用，并且修改时应同步影响这些界面；
- 属于已确认的通用设计系统，如通用按钮、开关、页签、进度条、关闭图标或通用装饰。

“被两个脚本引用”不等于“跨两个界面共用”。同一界面的多个脚本仍按界面专属资源处理。应用图标、整屏背景、结算专属面板和带有明确业务语义的图标，也不能仅因放置方便而归为通用资源。

## 3. 文件归属判断顺序

新增或迁移资源时按以下顺序判断：

1. 先确认资源是否被当前可达的代码、场景、TRES、材质或项目配置引用。
2. 若只属于一个独立界面，放入 `interfaces/<interface_id>/`。
3. 若跨界面复用但表达固定玩法对象，放入 `components/<component_id>/`。
4. 若跨界面复用且属于通用 UI 视觉语言，放入 `shared/`。
5. 若属于某界面但不适合打普通图集，仍放在该界面的 `standalone/`。
6. 无法确认归属时先保留原位并标记待审核，不得随意复制到多个候选目录。

同一视觉资源只保留一个运行时物理源。如果某个界面以后需要不同效果，应在该界面目录创建语义明确的新版本，并只替换该界面的引用；不得直接修改共享资源造成其他界面被动变化。

## 4. 图集分组与打包边界

目录表示资源归属，图集表示加载生命周期；两者相关，但不能简单地把整个目录无条件打成一张图集。

### 推荐分组

- 独立界面使用 `atlas_ui_<interface_id>`；
- 通用 UI 使用 `atlas_ui_shared`，必要时按 controls、icons 等拆分；
- 玩法组件使用 `atlas_ui_component_<component_id>`；
- 同一图集内的资源应具有相近的使用时机、过滤方式、压缩设置和生命周期。

### 普通 UI 图集候选

- 小型静态图标；
- 同组按钮和状态图；
- 小型装饰、角标和固定槽位；
- 不会独立改变采样、压缩或加载策略的静态 UI 图片。

### 默认不进入普通 UI 图集

- 全屏背景、超大面板和其他大尺寸独立纹理；
- Shader 或 VFX 采样纹理；
- 动画序列帧、序列帧拼图和循环特效；
- 怪物动画及其他角色图片；
- 已经作为图集成品的 sheet；
- 需要独立流式加载、独立压缩或特殊采样设置的纹理。

NinePatch 资源只有在以下条件全部通过后才可进入图集：

- AtlasTexture 区域具有足够的 padding 或 extrusion；
- patch margin 与 content margin 已记录；
- 拉伸后边框、圆角和装饰不串色、不裁切；
- Godot 实机尺寸验证通过。

生成的图集图片只放在 `atlases/`，对应 AtlasTexture `.tres` 只放在 `atlas_regions/`。图集表必须以当前活动资源重新生成；历史 `docs/assets/atlas_groups.csv` 只用于追溯，不能直接作为当前打包输入。

## 5. 原子迁移规则

一次迁移必须作为一个完整事务处理。以下内容属于同一依赖闭包，不能拆开提交或只移动其中一部分：

- 原始 PNG；
- 与 PNG 对应的 Godot `.import` 导入元数据；
- 引用 PNG 或图集 sheet 的 AtlasTexture `.tres`；
- 图集 sheet 与它的全部 `atlas_regions/*.tres`；
- 脚本中的 `res://`、`preload/load` 和动态根目录；
- 场景中的 `ext_resource`；
- TRES、材质、Shader 和项目配置中的相关路径。

迁移要求：

1. 迁移前记录旧路径、新路径、SHA-256 和全部消费者。
2. 同一次变更中完成文件移动和全部引用更新。
3. 不手工篡改 `.import` 内部生成字段；移动后由 Godot 完成重导入并检查错误。
4. 图集 sheet、AtlasTexture TRES 和代码引用必须同时指向新路径。
5. 迁移后扫描旧路径；当前可达引用必须为零。
6. 完成 Godot 导入、场景解析、主场景 Headless 和目标平台冒烟验证。

禁止先复制新文件、长期保留两个运行时副本再“以后切换”。确需过渡时，必须在迁移清单中标明唯一当前版本、过渡截止条件和替代关系。

## 6. 命名与版本规则

- 文件和目录统一使用小写英文、数字、下划线或短横线；禁止中文、空格、大写字母和无语义名称。
- 禁止继续使用 `layer_001.png`、`x-1.png`、`diban.png`、拼音缩写等无法判断功能的命名。
- 推荐文件格式：`<module>_<asset>_<state>_vNN.<ext>`。
- 状态词统一使用：`default`、`pressed`、`disabled`、`locked`、`selected`、`active`、`inactive`、`ad`、`new`、`upgrade`。
- 版本从 `v01` 递增，不覆盖来源不明或上一版本文件。
- 运行目录使用稳定功能名，不能因资源升级而把目录从 `*_v01` 改为 `*_v02`；只更新文件版本和引用。
- 同组状态必须保持相同画布尺寸、中心、锚点和基线。
- 序列帧使用补零编号，如 `frame_00.png`、`frame_01.png`。

正式 UI 底板不得烘焙可变文字、数字、百分比、次数、红点数量、动态星级或可替换图标；这些内容由程序绘制。

## 7. 禁止重复副本

- 不得为方便某个界面打图集而复制 shared 或 component 原图。
- 不得让同一 SHA-256 的资源以不同名称同时作为运行时正式资源。
- 不得同时引用独立小图和由它生成的 AtlasTexture；接入图集后应明确唯一运行入口。
- 不得在 `interfaces/`、`components/` 和 `shared/` 之间保留意义相同但来源不明的副本。
- 对共享资源做界面专属修改时，必须创建新的界面专属文件名和来源记录，不能无声覆盖共享文件。

## 8. 未引用资源和历史版本

新目录只接收当前状态为 `ACTIVE_RUNTIME` 或 `ACTIVE_REVIEW_PENDING` 的资源。

以下资源不得进入新的 `interfaces/`、`components/` 或 `shared/`：

- `RUNTIME_UNREFERENCED`；
- 已被新版替代的运行资源；
- 旧效果图、生产中间件和 QA 图；
- 仅存在于旧代码、失效 Manifest 或历史清单中的资源；
- 来源和用途尚未确认的文件。

未引用旧资源保持原状，等待单独的审核、隔离或删除授权。本次目录归整不得顺带删除、恢复或伪装成当前资源。

## 9. 归整验收

- 迁移前后的活动资源集合和文件哈希一致；
- 所有活动资源均有明确的 interface、component 或 shared 归属；
- 不存在旧路径的当前可达引用；
- 不存在同哈希运行时重复副本；
- AtlasTexture TRES、图集 sheet 和消费者引用全部有效；
- NinePatch 边距、文本安全区和锚点有记录；
- Godot 导入无错误，界面默认、按下、禁用、锁定和选中状态正常；
- 实机截图、Headless 和目标平台冒烟验证通过；
- 资源总账、目录对照和当前图集计划已同步更新。
