#!/bin/bash

# 1024x1024の紫色の画像を作成
sips -z 1024 1024 --setProperty format png /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/BookmarkIcon.icns --out icon-1024.png 2>/dev/null

# 各サイズを生成
declare -A sizes=(
    ["icon-20.png"]=20
    ["icon-20@2x.png"]=40
    ["icon-20@2x-1.png"]=40
    ["icon-20@3x.png"]=60
    ["icon-29.png"]=29
    ["icon-29@2x.png"]=58
    ["icon-29@2x-1.png"]=58
    ["icon-29@3x.png"]=87
    ["icon-40.png"]=40
    ["icon-40@2x.png"]=80
    ["icon-40@2x-1.png"]=80
    ["icon-40@3x.png"]=120
    ["icon-60@2x.png"]=120
    ["icon-60@3x.png"]=180
    ["icon-76.png"]=76
    ["icon-76@2x.png"]=152
    ["icon-83.5@2x.png"]=167
)

# ベース画像がない場合は、システムアイコンから作成
if [ ! -f "icon-1024.png" ]; then
    echo "Creating temporary base icon..."
    # 空の画像を作成する別の方法
    # macOSの標準ツールを使用
    touch temp.txt
    textutil -convert html temp.txt -output temp.html
    # 代わりに、ユーザーに画像を用意してもらう
    echo "Please provide a 1024x1024 PNG icon as icon-1024.png"
    exit 1
fi

for filename in "${!sizes[@]}"; do
    size=${sizes[$filename]}
    sips -z $size $size icon-1024.png --out "$filename"
done

echo "Icons resized successfully!"
