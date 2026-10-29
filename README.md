# Rise Of The White Sun — Auto Faction Qi & Armory v0.3.0（实验版）

## 版本重点

这是以用户提供的 `ROWS_Mono_Discovery(1).txt`、`ROWS_Targeted_Mono_v0.2.txt` 和既有 v0.2.3 为基础重新设计的自动绑定版。

**正常使用无需输入 Qi 地址、阵营地址或 `SCAN` / `BIND` / `MAINTAIN` 确认词。**

- 从 Mono 静态字段 `GameSetUp.setup` 找到当前 GameSetUp 实例。
- 从 `GameSetUp.PJ + 0x60` 读取当前玩家角色候选 `PnjManager`。
- 从 `PnjManager.faction + 0x50` 找到当前角色阵营 `FactionManager`。
- 自动更新角色属性以及阵营装备的 CE 地址。
- 在 **One-click** 开关启用时，每约 1 秒把当前阵营已验证角色的 Qi 恢复到 99；约每 30 秒重新发现成员。
- 如果角色从阵营退出，在下一轮检查时即停止写入；如果角色加入，在下一次重新扫描后纳入。

**重要：**该 Mono 字段链来自你上传的类结构报告，尚未在实际游戏中验证其切换表现。尤其 `GameSetUp.PJ` 是否随游戏中每次“选中角色”变更，必须通过角色切换测试确认；它可能只代表当前操控的角色，而不是任何界面上预览的 NPC。请勿将离线模拟测试当作游戏实测结果。

## 快速使用（推荐）

1. 进入游戏场景，让 Cheat Engine 附加游戏进程。
2. 用 CE 加载 `ROWs_AUTO_FactionQi_Armory_v0.3.0.CT`，允许表格 Lua 脚本。
3. 展开 `00 - AUTO TRACKING`，**只需勾选 `01. ONE-CLICK ENABLE: auto selected + faction + maintain all faction Qi=99`**。
4. 展开 `01 - AUTO SELECTED PLAYER`。Face、Money、Followers、Qi、Guns 应显示当前玩家的数值；切换当前玩家角色，观察地址/数值是否跟随变化。
5. 展开 `02 - FACTION EQUIPMENT`，检查金钱、步枪、火炮、机枪、装甲汽车、装甲列车、卡车等是否与当前阵营吻合。
6. `Show AUTO status / diagnostics` 可查看自动定位的角色与阵营、成员数、扫描状态和错误，不需要输入任何参数。
7. 取消勾选 One-click 开关，会立即停止 Qi 维护；其他自动追踪可能继续（如果另一个自动追踪开关仍处于启用状态）。

如果只想让选中角色和阵营装备自动更新、但不希望更改 Qi，请勾选 `02. Auto selected character + faction ONLY (no Qi modification)`。不要将两个开关混用；测试时先关闭所有相关开关再切换模式。

## 现有资产

### 选中角色属性

读取 `PnjManager` 真实数据：

| 属性 | 相对 PnjManager 对象偏移 | 类型 |
|---|---|---|
| Face / Influence | `+0x164` | 4 Bytes |
| Money / Argent | `+0x16C` | 4 Bytes |
| Followers / Partisans | `+0x170` | 4 Bytes |
| Qi / Energie | `+0x174` | 4 Bytes |
| Personal Guns / Armes | `+0x178` | 4 Bytes |

### 阵营装备

绑定到当前的 `FactionManager`：

| 项目 | 偏移 |
|---|---|
| Money | `+0x22C` |
| Rifles | `+0x230` |
| Artillery | `+0x234` |
| Machine Guns | `+0x238` |
| Armored Cars | `+0x23C` |
| Armored Trains | `+0x240` |
| Trucks | `+0x244` |

普通列车没有在阵营库存类里识别出独立字段；本版不猜测其偏移，也不会伪装成可编辑装备。

## 自动 Qi 逻辑与局限

1. 启用 One-click 后，首先验证当前游戏实例、玩家角色及阵营都是预期 Mono 类型，并核对字段结构。
2. 优先合并 `FactionManager.factionMembers`（如果非空）与已通过可写内存 vtable 扫描识别的同类 `PnjManager`。若游戏实际把阵营成员列表留空，脚本仍可采用 vtable 扫描。
3. 每次写入前重新检查角色是否仍属于当前阵营，并跳过已死亡角色。
4. 一次扫描使用 CE 的 `AOBScan`，可能短暂阻塞主界面。它不会扫描无匹配的子类或尚未加载的对象；因此不保证覆盖游戏中所有潜在角色。
5. 如果玩家角色所属阵营随场景/角色切换改变，本版会自动清空旧阵营扫描名单，重新识别新阵营，不继续对原阵营批量写 Qi。**如果你不希望切换阵营时自动跟随，请关闭 One-click。**
6. 游戏切换、对象销毁、静态指针暂不可用时，会暂停写入并重试。
7. 本表不会在加载时执行游戏内存写入。只有显式勾选 Qi 维持，或在 Cheat Engine 里直接编辑某项资源，才会修改游戏内存。

## 关于作弊码和存档

本表不会调用 `CheatCodes`、`SaveManager`、内置作弊码或存档作弊标志，也不会直接编辑存档文件。正常游戏保存时，游戏**可能会把已经修改的运行时角色数值和阵营库存一并保存**；如果不想影响原存档，请使用测试存档备份。

## 问题诊断与期望回报

如果自动角色无法读取：

- 运行 `03. Show AUTO status / diagnostics`，查看 GameSetUp、Active PJ、Active faction 以及 Error。
- 确认已经进入实际游戏场景，而不是游戏菜单。
- 在游戏中分别切换两个己方角色，观察 `Selected Player` 下的数值是否自动变化；不要只更换当前查看的 NPC 面板。
- 如果 `GameSetUp.PJ` 未随切换变化，我们需要进一步定位 `SwitchPJ_Hub` / 游戏中真正的当前 UI 选中角色指针，而不能猜测指针链。

## 离线测试与版本状态

已完成 `.CT` XML 检查、全部 Auto Assembler 嵌入 Lua 脚本语法解析（Lua 5.4 语法解析器）、以及模拟 CE/Mono 环境下的行为测试。模拟项目包括初始绑定、无自动写入、不同阵营排除、角色退出、角色加入、玩家角色切换、阵营切换及等待场景加载。

**游戏实测：待验证。**之前 v0.2.3 的运行成功并不能证明 v0.3.0 自动单例绑定在当前游戏版本可靠。
