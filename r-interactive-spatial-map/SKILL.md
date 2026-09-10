---
name: r-interactive-spatial-map
description: 用 R 创建交互式空间地图，支持行政区分级设色、指标表关联、点位弹窗与可选静态 PNG。适用于 GPKG、SHP、GeoJSON 地图和人口、病例、机构等空间展示需求。
---

# 交互式空间数据可视化

优先使用本机 R、sf、leaflet。先读取文件识别字段和 CRS，不依赖先前对话或特定电脑路径。

## 项目规则
默认根目录含 Project.Rproj、00_admin、01_data/raw、01_data/derived、02_code、03_output。缺少时补齐；尊重已有结构，不移动或覆盖原始文件。代码及配置放 02_code，派生数据放 derived，地图放 output。所有路径基于指定项目根。

## 环境
检查 Rscript 的 PATH；Windows 再检查 HKCU/HKLM 的 SOFTWARE/R-core/R InstallPath 及 bin/Rscript.exe。用 --version 验证并检查包。未找到时询问路径，不声称未安装，不静默换用 Python。安装缺失依赖前说明。实际运行与只生成代码分别报告。Windows 出现 C.UTF-8 警告及中文路径损坏时，可在当前进程验证 LC_ALL=English_United States.utf8、LANG=en_US.UTF-8，不修改全局配置。

## 数据与参数
读取 references/config.md，按实际字段生成配置，使用 scripts/map.R。代码关联时同时核对名称；冲突请用户确定依据并保存审计记录。不推断年份、疾病、人口单位或坐标系。默认连续色标；指定分组时核对范围和标签。明确数量或率；率仅在用户要求且分母和时段明确时计算。衍生变量在项目 R 脚本计算并记录公式与单位。

## 输出与核验
复制脚本到 02_code 后执行，不覆盖已有版本。核对行数、名称、数值与文件，浏览器检查弹窗和缩放，静态图检查中文与标签。无法视觉检查时报告。HTML 默认带资源目录，分享须一起携带，底图需联网。单文件要求需检查 Pandoc 并设置 selfcontained=TRUE。发布只用合成示例。图表联动尚未实现。
