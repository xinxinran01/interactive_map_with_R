# JSON 配置
必填：project（根目录）、source（相对根目录的地图路径）、code（地图代码字段）、name（地图名称字段）、value（数值字段）。
可选 table：相对路径 CSV，UTF-8；table_code/table_name 指定其键和名称。无 table 时 value 取地图字段。
title 默认 Spatial indicator；unit 默认空；output 默认 map。static 默认 false；overwrite 默认 false。layer 可指定 GPKG 图层；codes 可筛选代码列表。
breaks 为升序数值列表，须覆盖非缺失值全范围，labels 数量等于区间数。重复键、名称冲突、关联失败均停止。
points 可为对象：source（CSV）、lon、lat、name、epsg（已知 EPSG 必填）；category 可按类别分色。非法或缺失坐标停止；GCJ-02 需单独转换。
将单位和已知统计时段写入 title/unit。运行：Rscript map.R config.json。复杂点大小与弹窗字段在项目脚本副本中扩展并测试。
