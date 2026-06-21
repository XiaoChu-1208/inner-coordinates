#!/usr/bin/env bash
# meituan-order.sh <店名> <商品> [份量:标杯|大杯] [温度:热|冰|少冰|去冰]
#
# 把美团下单的【稳定链路】打包成【一条命令】——agent 跑这一条工具就走完整段,
# 不会"一步一截图"(模型的逐步观察反射被绕开了:一条命令里没有"中间"可截)。
# 走到结算页停(不扣款);红包/餐具/支付宝/密码 见 profile,密码盘必须停下问用户。
#
# 前提:【已在美团外卖首页】(锚点)、镜像连好、Handoff 开、cliclick 装好。
# 不在首页就先复位:底部首页(35,759)/详情页先返回(20,115)。
#
#   meituan-order.sh 皮爷咖啡 拿铁 大杯 少冰
#
# 注意:走的是【常量路径】——进店后用店内搜索框搜商品(确定),不赌会漂移的分类/列表坐标。
# 仍有两处 trust 的半稳定坐标(进第一家店 150,333 / 店内搜索首条选规格 300,204);
# 若促销 banner 把店卡推移导致漂掉,redo 一次或先 grab 一张核对。
set -uo pipefail
STORE="${1:?需要店名}"; ITEM="${2:?需要商品名}"; SIZE="${3:-标杯}"; TEMP="${4:-}"
PROC="iPhone Mirroring"
DIR="$(cd "$(dirname "$0")" && pwd)"
A(){ osascript -e "tell application \"System Events\" to tell process \"$PROC\" to set frontmost to true" >/dev/null 2>&1; }
CK(){ A; peekaboo click --coords "$1" >/dev/null 2>&1; }
PASTE(){ printf '%s' "$1" | pbcopy; sleep 2.6; A; cliclick kd:cmd t:v ku:cmd; }   # pbcopy 处理中文,避开 osascript 引号坑
case "$SIZE" in 大杯) SZ="200,300";; *) SZ="80,300";; esac
case "$TEMP" in 热) TP="63,356";; 冰) TP="95,356";; 少冰) TP="145,356";; 去冰) TP="195,356";; *) TP="";; esac

osascript -e "tell application \"System Events\" to tell process \"$PROC\" to set position of front window to {0,25}" >/dev/null 2>&1; sleep 0.4

# 1) 首页搜店 → 搜索栏 → 输入框 → 粘店名 → 搜索键
CK "140,141"; sleep 1.8
CK "130,120"; sleep 0.5
PASTE "$STORE"; sleep 1.0
CK "307,117"; sleep 2.2
# 2) 进第一家店(trust)
CK "150,333"; sleep 2.8
# 3) 上滑收店头 → 店内搜索框(常量) → 粘商品
A; peekaboo swipe --from-coords "173,600" --to-coords "173,250" --duration 320 --app "$PROC" >/dev/null 2>&1; sleep 1.2
CK "100,127"; sleep 1.2
PASTE "$ITEM"; sleep 1.6
# 4) 第一条结果『选规格』(trust 300,204)
CK "300,204"; sleep 1.8
# 5) 规格:份量 + 温度(都是固定行,稳)
CK "$SZ"; sleep 0.4
[ -n "$TP" ] && { CK "$TP"; sleep 0.4; }
# 6) 加入购物车
CK "265,604"; sleep 1.5
# 7) 去结算
CK "279,741"; sleep 2.6
peekaboo move --coords "330,90" >/dev/null 2>&1; sleep 0.3
"$DIR/grab.sh" "$PROC" /tmp/mt_order.png
echo "DONE → 结算页截图 /tmp/mt_order.png"
echo "下一步(见 profile,可继续盲跑到密码盘前停):美团红包→立即支付→餐具(需要餐具)→确认并提交→收银台选支付宝→确认交易→付款→[密码盘:停,问用户]"
