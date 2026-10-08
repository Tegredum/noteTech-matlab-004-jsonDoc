# 用 `functionSignatures.json` 为 MATLAB 函数添加代码提示

encoding: utf-8
author: Codex (GPT-5.6 Sol xhigh, GPT-6.1 Sol max)

MATLAB 桌面版可以从一个约定名称和位置的 JSON 文件中读取自定义函数签名，并据此在编辑器、实时编辑器和命令行中给出参数提示与 Tab 补全。本仓库给出一个可运行的 `formatTemperature` 示例，覆盖必选参数、可选位置参数、名称-值参数、候选值、参数用途和输出参数。

> 这里的 JSON 是“提示元数据”，不是普通的任意文件名。文件必须命名为 `functionSignatures.json`，并放在函数同级目录下的 `resources` 子目录中。

## 本次采用的理解

“利用 JSON 为 MATLAB 程序编写代码提示”可能也指第三方编辑器的语言服务器配置。本次按最可能且由 MathWorks 正式支持的含义处理：为用户自定义 MATLAB 函数编写 `functionSignatures.json`，让 MATLAB 自己的编辑器和命令行提供调用参数提示。它不修改 VS Code 等外部编辑器的补全系统，也不是 MATLAB Production Server 所使用的部署函数签名文件。

## 目录结构

```text
.
├── formatTemperature.m
├── resources/
│   └── functionSignatures.json
├── examples/
│   └── demoCodeSuggestions.m
├── tests/
│   └── runTests.m
└── README.md
```

`formatTemperature.m` 特意使用经典的 `inputParser`，而没有使用 `arguments` 块。较新的 MATLAB 能直接从 `arguments` 块推导一部分提示；本例这样写，是为了单独、清楚地展示 JSON 机制。

## 操作方法

### 1. 编写可调用函数

函数应位于一个 MATLAB 能找到的目录中，即当前工作目录或 MATLAB 搜索路径上的目录。本例的调用形式为：

```matlab
text = formatTemperature(values, unit)
text = formatTemperature(values, unit, digits)
text = formatTemperature(___, 'Style', style)
text = formatTemperature(___, 'ShowUnit', tf)
text = formatTemperature(___, 'Prefix', prefix)
```

如果 MATLAB 当前目录不是本仓库根目录，先运行：

```matlab
addpath('此仓库的绝对路径')
```

### 2. 在固定位置创建 JSON

在 `formatTemperature.m` 的同级目录下创建 `resources` 文件夹，并在其中创建 `functionSignatures.json`：

```text
<函数所在目录>/resources/functionSignatures.json
```

本例 JSON 的基本形状如下：

```json
{
  "_schemaVersion": "1.0.0",
  "formatTemperature": {
    "inputs": [
      {
        "name": "values",
        "kind": "required",
        "type": ["numeric", "real", "vector"],
        "purpose": "Temperatures to format"
      }
    ],
    "outputs": [
      {
        "name": "formattedText",
        "type": ["string"]
      }
    ]
  }
}
```

顶层属性名必须与函数名一致。类构造函数、类方法和命名空间（旧称包）函数则使用完整名称，例如 `myClass.myMethod` 或 `myNamespace.myFunction`；这种情况下，JSON 要放在最外层类/命名空间目录的父目录所含的 `resources` 中。

### 3. 描述参数

每个 `inputs` 元素都可使用以下常见属性：

| 属性 | 作用 | 本例 |
| --- | --- | --- |
| `name` | 提示中显示的参数名；必需 | `values`、`unit` |
| `kind` | 参数出现方式 | `required`、`ordered`、`namevalue` |
| `type` | 类、形状、范围或候选值 | `numeric`、`scalar`、`choices=...` |
| `purpose` | 提示中显示的简短说明 | `Temperature unit` |

常用的 `kind` 值：

- `required`：必选位置参数；
- `ordered`：可选且按顺序出现；
- `positional`：位于末尾时可省略，但若要填写后续位置参数就必须填写它；
- `flag`：可选的常量文本开关；
- `namevalue`：可选名称-值参数，应排在位置参数之后；
- `properties`：将另一个类的公开可设置属性作为名称-值建议。

`type` 数组的同一层表示“同时满足”（AND），嵌套数组的外层表示“满足任一组”（OR）。例如，`Prefix` 的以下定义表示字符向量或者 string 标量：

```json
"type": [
  ["char"],
  ["string", "scalar"]
]
```

对于 `unit`、`Style` 这种有限候选值参数，本例只描述一份 `choices`：

```json
"type": ["choices={'fixed','scientific'}"]
```

`choices` 可以作为独立的类型属性使用；本机 MATLAB 自带的签名文件也采用这种写法。函数内部的 `inputParser` 和 `validatestring` 仍负责同时接受字符向量与 string 标量。不应把类型写成 `["char", "string"]`：这是 AND，表示同时属于两种类，并不表示二选一。有关 `type` 和 `choices` 的正式语义，参见 [MathWorks 官方文档](https://www.mathworks.com/help/matlab/matlab_prog/customize-code-suggestions-and-completions.html)。

还可以使用 `file=*.m,*.mlx`、`folder`、`matlabpathfile=*.mat`、`size=2,:`、`numel=3`、`positive` 以及不等式等类型限定。完整支持项应以当前 MATLAB 版本的官方文档为准。

### 4. 校验 JSON

仅用通用 JSON 解析器还不够，因为它不能检查 MATLAB 的函数签名规则。请在 MATLAB 中运行：

```matlab
signatureFile = fullfile(pwd, 'resources', 'functionSignatures.json');
messages = validateFunctionSignaturesJSON(signatureFile)
```

`messages` 应是空表。也可以不接收输出，让 MATLAB 直接显示定位到行、列的诊断信息。该函数会同时检查 JSON 语法和 MATLAB 函数签名 schema，例如参数排列顺序是否合法。

### 5. 在编辑器中观察提示

1. 使用桌面版 MATLAB，将本仓库根目录设为当前目录或加入搜索路径。
2. 打开普通 `.m` 脚本或实时脚本 `.mlx`。
3. 输入 `formatTemperature(`，观察当前参数名和 `purpose` 文本。
4. 输入 `formatTemperature(23,`，应出现 `Celsius`、`Fahrenheit`、`Kelvin` 候选值，每个单引号候选项应仅出现一次。
5. 输入 `formatTemperature(23, 'Celsius',`，应看到可选的 `digits` 以及名称-值参数。
6. 选取或键入 `'Style'` 后，应出现 `fixed`、`scientific`，各仅一次；`'ShowUnit'` 应出现 `true`、`false`。可按 Tab 接受当前补全项。

如果刚修改过文件但提示尚未刷新，可确认函数路径解析正确：

```matlab
which formatTemperature -all
rehash path
```

然后重新打开脚本或重启 MATLAB。还应检查“主页 > 设置 > 编辑器/调试器 > 建议和自动完成”中的自动完成是否已启用。

### 6. 候选值出现两次时如何排查

阶段 2 的人工验收发现，旧版签名把 `unit` 的 `choices={'Celsius','Fahrenheit','Kelvin'}` 同时写在 `char` 与 `string` 两个 OR 分支中；`Style` 也重复声明了同一份候选值。结合这份配置和实际重复现象，原因判断为两个分支分别提供了同一批补全文本，而该编辑器没有将它们合并去重。

修正后的 `unit` 定义为：

```json
{
  "name": "unit",
  "kind": "required",
  "type": ["choices={'Celsius','Fahrenheit','Kelvin'}"],
  "purpose": "Temperature unit"
}
```

`Style` 同样只保留一份 `choices={'fixed','scientific'}`。`Prefix` 没有固定候选值列表，保留原来的类型 OR 描述。

重新验收时，先保存 JSON，再在一个新的脚本中分别输入以下片段，将光标放在末尾按 Tab；若仍使用旧候选列表，重新打开脚本或重启 MATLAB 后再试。`rehash path` 刷新的是函数路径缓存，不能保证编辑器的 JSON 提示缓存立即刷新。

| 输入片段（不要运行这些未完成的调用） | 预期固定候选项 |
| --- | --- |
| `formatTemperature(23,` | `'Celsius'`、`'Fahrenheit'`、`'Kelvin'`，各 1 次 |
| `formatTemperature(23, 'Celsius', 'Style',` | `'fixed'`、`'scientific'`，各 1 次 |
| `formatTemperature(23, 'Celsius', 'ShowUnit',` | `true`、`false`，各 1 次 |

这里只统计固定候选项；菜单还可能包含工作区变量等其他建议。`'Celsius'` 与 `"Celsius"` 是两种不同文本字面量，不应把它们计作“同一个单引号候选项出现两次”。若同一个单引号条目仍重复，运行 `which formatTemperature -all`，确认正在使用本仓库的函数，并检查其附近是否还存在旧的同名签名文件。

`validateFunctionSignaturesJSON` 检查的是语法和 schema，不会验证补全菜单是否去重。这次修改已通过本机 MATLAB schema 校验和函数回归测试；最终菜单条目数仍须在当前桌面编辑器中人工确认。

## 运行示例与自动检查

运行示例：

```matlab
run('examples/demoCodeSuggestions.m')
```

运行全部自动检查：

```matlab
addpath('tests')
runTests
```

命令行批处理方式：

```shell
matlab -batch "addpath('tests'); runTests"
```

若 MATLAB 启动器无法以包含非 ASCII 字符的目录作为进程工作目录启动，可先从一个纯 ASCII 目录启动，再在 `-batch` 表达式中用绝对路径 `addpath` 本仓库的 `tests` 目录。本仓库已用这种方式在 Windows 上完成验证；这只是在规避启动器/本机环境问题，不影响 MATLAB 搜索路径中的函数和 JSON。

自动检查会验证函数的正常输出、无效单位的拒绝行为、所有单位/样式使用字符向量与 string 标量时的行为一致性、JSON 可解析性，以及 `validateFunctionSignaturesJSON` schema 校验结果。代码提示本身是编辑器 UI 行为，仍需按上面的步骤进行一次人工验收。

## 提示与运行时校验的边界

JSON 中的 `type`、`choices` 等内容用于筛选和生成建议，不应当被当作运行时契约。用户仍可手工输入不在候选列表中的值，因此函数自身必须校验输入。本例使用 `inputParser` 和 `validatestring` 实施实际约束，并让这些约束与 JSON 保持一致。

如果函数已经采用 `arguments` 块，MATLAB 可直接从该块生成代码建议，通常无需再创建 JSON；只有在需要补充或定制签名表现时，才值得维护单独的 JSON。

## 版本与限制

- `validateFunctionSignaturesJSON` 自 R2018b 引入；
- R2021b 之前，来自 `functionSignatures.json` 的提示只适用于实时脚本。若希望在普通编辑器和命令行中获得完整体验，建议使用 R2021b 或更高版本；
- 当前官方文档明确说明 MATLAB Online 不支持这种自定义提示；
- 命令行可以使用 Tab 补全 JSON 提供的内容，但不会像编辑器那样在键入时持续显示匹配语法；
- schema 当前版本仍为 `1.0.0`。省略 `_schemaVersion` 时 MATLAB 也按 `1.0.0` 处理，但显式写出更利于审查。

## 官方资料

- [Customize Code Suggestions and Completions](https://www.mathworks.com/help/matlab/matlab_prog/customize-code-suggestions-and-completions.html)
- [`validateFunctionSignaturesJSON`](https://www.mathworks.com/help/matlab/ref/validatefunctionsignaturesjson.html)
- [`arguments`](https://www.mathworks.com/help/matlab/ref/arguments.html)
- [`inputParser`](https://www.mathworks.com/help/matlab/ref/inputparser.html)
- [R2021b 以前编辑器支持范围的 MathWorks Support 说明](https://www.mathworks.com/matlabcentral/answers/705548-why-do-my-custom-function-signatures-specified-in-the-functionsignatures-json-file-not-show-up-in)
