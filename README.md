# 交互式空间数据可视化（R）
版本：0.1.0

供支持文件型 Skill 的 AI 助手使用。输入项目路径、地图文件和指标字段，
生成可运行 R 代码及交互式 HTML；PNG 为可选输出。需要本机 R，不是云端制图服务。

## 安装
将本仓库的 `r-interactive-spatial-map` 文件夹完整复制到
`~/.codex/skills/`（或目标助手支持的技能目录），重新打开任务后调用：
`$r-interactive-spatial-map`。
也可以让支持 GitHub 技能安装的助手从本仓库该子目录安装。

## 使用
“使用这个 Skill，在我的项目里读取 raw 下的行政区地图，
按病例数字段着色，输出交互式地图和静态 PNG；缺少标准目录就补齐。”
提供文件后，助手先检查字段、坐标系、关联代码与名称，再创建配置并执行。
不会自动更改冲突的行政区代码，不会凭空生成真实病例或人口。

## 环境
R 4.5.2 已用于本次验证；需要 sf、leaflet、htmlwidgets、ggplot2、jsonlite。
安装依赖：`install.packages(c("sf","leaflet","htmlwidgets","ggplot2","jsonlite"))`。
Linux 的 sf 可能需要系统 GDAL/GEOS/PROJ。
联网底图不是离线数据；HTML 与同名 _files 资源目录应一起分享。

## 自带示例
示例使用程序生成的三个矩形与虚构数值，不包含真实地图或私人文件。
在仓库根目录运行：
`Rscript r-interactive-spatial-map/scripts/demo.R demo-project`
输出位于 demo-project/03_output。重复运行示例会停止，保护已有数据。

## 范围
包含面地图、表格按代码关联、名称一致性检查、连续/固定断点着色、
可选 WGS84/已知 EPSG 点图层、弹窗、比例尺、PNG。
图表联动尚未实现。GCJ-02 不可直接当作 EPSG:4326；
需在单独确认并转换后再输入。R 不可用时应报告，不应偷偷更换语言。

