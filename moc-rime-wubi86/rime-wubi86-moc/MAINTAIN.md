# 维护说明

当前交付版本2026.10.15.1；字典仍为2026.10.09，数据记录未改。Capslox兼容默认关闭，配置和限制见README。原生CapsLock路径保持独立。

本轮修正ZIP与仓库目录不一致：授权个人词典随两种包放入optional根目录，data仍用空模板；主题分别位于optional/macos/blue-reverie和optional/macos/rose-maple。31项检查通过，包括个人词典缺包的失败回归及主题路径检查；以下原生引擎和前端实测记录保留原范围。

## 数据组织

`data/` 内18个文件是可部署源数据，包含注册模板、集中设置和默认蓝色外观。基础72241条，扩展63254条（补充词组53911条＋英文9343条），合计135495条；反查6817条，主词库含6455个规范单字。个人表为空三列模板。基础与扩展各存一份，没有第二份完整词库、编译缓存或安装程序。

纯净加载“个人表、基础”；全功能加载“个人表、基础、扩展”，个人表优先。纯净通过Rime原生 `__include` 复用全功能配置，仅覆盖方案身份、描述和字典引用。两种模式共用反查依赖与六个Lua，保留补全及按键习惯。先前已去掉空末列Tab，六个有效stem保留。

| 文件 | 作用 |
| --- | --- |
| `moc_settings.yaml` | 快捷键、候选数量、默认英文应用及可选Capslox兼容的唯一值来源 |
| `squirrel.custom.yaml` | macOS默认蓝色副本，通用包不含此文件 |
| `default.custom.yaml` | 首次使用的双模式注册模板，纯净排在首位，Control＋Shift＋0打开菜单；已有同名配置时保留并合并 |
| `moc_wubi86_core.dict.yaml` | 共用基础字词 |
| `moc_wubi86_extra.dict.yaml` | 全功能补充词组和英文 |
| `moc_wubi86_user.dict.yaml` | 共用个人表模板 |
| 两个主dict与schema | 词库组合与模式切换入口 |
| `moc_reverse.dict.yaml` / `moc_reverse.schema.yaml` | 共用拼音找字数据及依赖 |
| `lua/` 内六个文件 | 共用辅助功能，含CapsLock大写提交 |

## 冷门清理原则

用户已授权按普通内地用户、本科工科用途审核。本轮删除1234条主词库记录：978条中文词组、21个冷僻单字的35条编码记录、221条英文记录；同步删除21条反查。规范名单内精确单字排除合计45个，含字词组不连带删除。日常词、常见成语及有明确用途的低频工程词保留，不以原编码首选作为无条件保护理由。一二级简码记录未删。

不同来源的词频原数值不可相加、取最大或使用相同次数门槛；Rime排序权重也不是实际频率。知乎、维基各在同一交集词条集内，按1/2/3/4及以上词长分组，独立计算带并列中点的稀有分位；来源数值独立缩放不改变结果。缺失为unknown，不当作0。英文排名独立保护，不混入中文尺度。领域、分词粒度、词形覆盖差异仍然存在，分位只是待审线索，不代表个人输入概率。

删除必须有明确用途理由，频数低或缺失不能单独作为删除理由。保留记录的编码、权重、stem、顺序不变，本轮没有重新校准全词库排序。详见reports/cleanup.md、frequency_sources.json与removed.tsv。60MB语料只在临时目录审核，不加入仓库或部署包；维护算法tools/review_frequency.py只用标准库。

## 维护和发布

```sh
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/pack.py
```

输出通用 `releases/moc-wubi86-data-2026.10.15.1.zip`、鼠须管 `releases/moc-wubi86-macos-2026.10.15.1.zip` 与SHA256SUMS。通用ZIP含17数据、optional授权个人词典和6说明许可，共24文件；macOS ZIP含18个data文件、同一份optional个人词典、两套外观和6说明许可，共27文件。两套皮肤不复制主词库，不含tests、tools和报告，Python不是部署依赖。首次使用将data内容放入自己的Rime资料夹并重新部署，注册文件随包提供；optional词典按需选用，不自动启用。已有default.custom.yaml保留并合并两个模式；希望沿用本套快捷键时引用moc_settings。已有squirrel.custom.yaml先备份、按需合并；空个人模板不可覆盖已有个人词。

源文件上传GitHub，ZIP与校验作为Release附件；不制作重复源码ZIP，不上传缓存、原语料、私人备份。通用包无皮肤，数据三平台共用。macOS包默认蓝色；optional保留原玫枫和蓝色完整配置。两套均引用moc_settings中的默认英文应用：PyCharm、Terminal、electerm、SecurityAgent及通行密钥流程的LocalAuthenticationRemoteService、AuthenticationServices.Helper。后两组件来自本机窗口元信息，尚未实测安全密码框的默认输入状态；后台authorizationhost已移除。

## 验证与留痕

31项自动检查覆盖词频尺度、缺失、词长、并列、英文隔离、数据摘要、字符范围、精确规避、个人表、配置复用、Lua和打包。CapsLock的26项原生Lua边界及Capslox状态用例需维护机已有Lua解释器，缺少时明确跳过；普通部署不需要解释器。tests/expected.json固定当前规范化摘要，cleanup_summary.json固定清理前摘要；将removed.tsv按原位置插回可还原全部修改前记录。不要仅更新摘要掩盖误删。主字典摘要规范化格式为文本、编码、权重、stem四列加换行，缺失stem补空。

## CapsLock大写提交 · 2026-10-15

方案版本2026.10.15，词表版本仍为2026.10.09。新增moc_capslock放在ascii_composer之前，只对中文状态、CapsLock按下且无Shift/Control/Alt/Command组合的纯ASCII字母编码提交大写。返回kNoop保留原生CapsLock处理；不能返回kAccepted吞掉切换，也不能放在ascii_composer之后，否则clear已清掉编码。空输入、英文状态、释放事件、数字及工具前缀不转换。纯净继承相同处理，不复制脚本或完整方案。

回归先用旧数据复现两个模式共10个大写提交失败，再修改脚本与注册顺序。29项自动检查、26项Lua边界用例、Squirrel 1.1.2所带librime 1.16.0隔离环境的26项用例通过，包括有/无候选、英文候选、混合大小写、空输入、英文编辑、释放事件、工具及反查，关闭CapsLock后继续五笔选词正常。候选及词表记录未修改。当前证据tests/native-capslock-20261015.json；Windows/Linux物理键事件与macOS实际键盘交互尚未实测，不把引擎模拟当成前端实测。

## Capslox事件兼容核验 · 2026-10-15

通用实现依赖标准CapsLock事件，不要求安装Capslox。只在使用者运行Capslox或其他重映射工具时核对事件链；不要为本机环境改变所有用户的默认按键。此次本机版本为Capslox 3.1.1.0、Squirrel 1.1.2、librime 1.16.0，不能据此断言其他版本都有同样行为。

实际按键的只读检测观察到：CapsLock经HID映射成F17，F17按下/释放只出现在Capslox处理前；处理后为系统大写标志变化，键码曾为255、12、51，未出现标准CapsLock的57。鼠须管按事件键码转换：255成为VoidSymbol，其他键码可能成为字母或退格，因而到不了Lua的Caps_Lock分支。对本机Capslox二进制的只读检查确认toggleCapslock调用KeyboardHelper.capslockState，后者用IOHIDGetModifierLockState/IOHIDSetModifierLockState切换状态。该结论同时依据本机事件和版本对应的前端实现，不仅依据配置文件或F17映射猜测。

对照仅在不接收文字的临时窗口执行，未使用真实个人词库：原动作改变系统状态但不发标准CapsLock；只发`caps`得到键码57却没有大写标志变化，鼠须管会忽略未变化的flagsChanged；“切换状态后发caps”仍未得到正确的开启事件。F18能作为独立通知，按住Capslox+S仍发送左方向键；但“发F18后切换状态”的组合未通过系统锁定核验，不能称为完整兼容修复。失败试验当时均恢复原配置，不进入默认使用步骤。

后续使用者明确接受只管理Rime内部的大写输出，不要求系统锁定、键盘灯或其他输入法。现有moc_capslock.lua增加默认关闭的兼容开关，由moc_settings通过原生include供两个模式共用；没有新运行文件。开启后F18在中文提交纯字母，在英文开关持续大写；ascii_mode改变即清除内部状态。英文大写时重新交原生处理链再按处理结果提交，确保按住Shift打字后不会因处理器吞字母而误触发中英文切换。Ctrl、Alt、Command及非字母沿用原处理。状态属于当前Rime上下文，不保证跨应用窗口保持。

回归先出现两项预期失败，随后30项项目检查通过；原生路径26项及兼容路径24项隔离引擎用例通过，两个ZIP各自全新部署后分别通过上述26/24项。切换开关的夹具必须全新目录或确保修改时间跨秒，不能在同一秒改配置后把部署缓存当成最新行为。Lua摘要只在审查变更和行为检查后更新，词表及其他Lua不变。本机已备份部署并将Capslox短按改为f18；自动HID探针确认通知送达、原按住组合键保留，系统锁定仍关闭。使用者已确认物理键盘下Rime中英文与CapsLock配合符合预期；其他输入法具体响应未核验，不能算入验收。此次交付版本2026.10.15.1，不扩大兼容范围；普通用户不必安装Capslox或额外桥接工具。原始证据与本轮新证据在同一JSON中分开保存。

依据：[Capslox动作与自定义修饰键](https://capslox.com/cn/docs/configuration/#custom-modifiers)、[鼠须管1.1.2状态事件处理](https://github.com/rime/squirrel/blob/1.1.2/sources/SquirrelInputController.swift#L58-L75)、[同版本键码转换](https://github.com/rime/squirrel/blob/1.1.2/sources/MacOSKeyCodes.swift#L33-L70)。物理事件捕获不等于实际大写上屏；本轮另由使用者确认Rime中英文的实际输入效果，其他输入法未纳入验收。

本机更新仅写新Lua及共用方案，先备份后检查两个编译方案的处理顺序，再重新加载。个人词表等15个受保护源文件摘要未变。维护者使用rime_deployer --build时，共享目录参数须指向鼠须管Contents/SharedSupport，不能用只有个性化数据的用户资料夹；--reload属于Squirrel主程序，不属于rime_deployer。

真实鼠须管（librime 1.16.0）隔离验证：纯净3500组、全功能3822组输入，包括全部637/638个现有一二级简码、各1000个固定随机种子的四码、删除影响编码及补全/反查/辅助用例。短码首选不变，保留词完整编码候选相对顺序通过，删除词不再出现；各4组人造个人词优先检查通过。删除会改变宽前缀补全队列，不能宣称所有补全尾页顺序不变。最终ZIP在临时目录直接复制data内容后部署；已有配置的合并路径另外验证，结果在tests/native-result.json。

Windows/Linux前端尚未实测；用户补丁与Lua版本可能影响效果。本轮修正金额Lua零值及不完整输入处理。语义筛选不是所有保留词的逐项审核，也不保证每个词都适合所有用户。

## 当前配置 · 2026-10-09

当前版本2026.10.09。集中设置采用Rime原生__include；顿号映射在导入标点预设后用__patch替换，避免直接合并列表与commit映射导致部署错误。中文半角、全角按反斜杠直接提交顿号，有完整词组时一起上屏。英文半角由前端处理普通反斜杠，全角按Rime约定输出全角反斜杠。

金额只有两个大写候选；取消/fh。个人模板三列，助手新写入三列、兼容旧四列；基础和扩展的有效stem不动。默认蓝色与optional蓝色副本同时间，玫枫相差2秒，支持反复换色部署。

本轮证据在tests/native-20261009.json。历史native-result.json及以下带日期记录保留原测试事实，不代表当前包的文件数或默认皮肤。补全研究见reports/completion-ranking.md；已定位原因并验证临时原型，正式方案未加入重排Lua或修改词库权重。

## 复盘

保留有效流程：独立来源尺度、用途复核、精确删除清单、低频工程词保护、主词库与反查同步、真实候选对比、下载包重新部署。去掉无效流程：混用原始词频、缺失即删除、盲目保护所有旧首选、为缩小体积取消功能、自动安装器、重复词库与全量语料打包。

原完整补全队列不变的验证假设过严，删除后候选队列重填可能改变尾页；现验证短码首选、完整匹配相对顺序与个人词优先，并如实记录前缀变化。原有14个数据文件保留，补充方案注册模板；没有添加运行时依赖。验证只使用隔离目录，不修改真实Rime用户配置。

## 同仓库整理 · 2026-10-07

本模块位于moc-rime-wubi86/rime-wubi86-moc，兄弟目录wubi-code-assistant提供独立编码助手。原有14个数据文件不变，新增方案注册模板后共15文件；更新复制部署说明，重打ZIP并隔离验证。助手单字表与本模块词库精简解耦，不复制完整词库到App。

## 外观与快捷键回归 · 2026-10-07

恢复注册模板的Control＋Shift＋0；两套皮肤都包含五笔补全注释和同一组默认英文规则。蓝色遐想采用固定上游提交，补全注释对比度和参数写法的修改见NOTICE。原玫枫preset颜色块保持字节一致。

打包时给两套皮肤不同的ZIP修改时间（相差2秒，符合ZIP精度）。librime按源文件时间判定是否更新配置；不能把两套同名皮肤固定成同一时间，否则替换后可能仍沿用缓存。自动检查断言不同时间，原生验证按ZIP时间解压、复制保留元数据，并在同一临时目录完成玫枫→蓝色→玫枫，确认每次部署后的亮暗选择与五项应用规则一致。

26项自动检查通过；原生librime验证快捷键实际打开双模式菜单，两个模式的补全、分号／单引号选词、方括号翻页和Shift切中英通过。配置使用本机Squirrel 1.1.2的librime 1.16.0部署，结果记录在tests/native-result.json。四类英文场景完成部署配置核验，PyCharm、Terminal和electerm应用标识与本机安装核对；未自动操作真实密码弹窗或逐个应用交互，不将这些核验写成全部前端场景实测。真实用户配置和个人词库均未写入。

来源依据：[Squirrel部署入口](https://github.com/rime/squirrel/blob/master/sources/SquirrelApplicationDelegate.swift)、[librime配置变化检测](https://github.com/rime/librime/blob/master/src/rime/lever/deployment_tasks.cc)。

## 项目目录与发布入口 · 2026-10-08

唯一现役项目为moc-rime-wubi86，输入法与编码助手仍是两个独立模块。当时Release为moc-rime-wubi86-2026.10.08，数据包2026.10.08，词库2026.10.06，助手1.2/build3。本次更新目录名称、说明和下载入口；data、两套皮肤、助手源码及App字节不变，沿用原日期的运行证据并重新检查打包内容。不能将本次字节核验冒充新的前端交互实测。schema_id、字典名及个人表名保持不变；两套皮肤ZIP时间须不同。不写真实个人词库，不恢复退役材料。当前卡点无，后续等待使用反馈。
