#!/bin/bash
set -euo pipefail
#source .env

# =========================
# ログイン
# =========================
curl -i -L \
  -c cookies.txt \
  -b cookies.txt \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Origin: https://www.e-atoms.jp' \
  -H 'Referer: https://www.e-atoms.jp/ACESPORTSWebUser/Account/LogIn?ReturnUrl=%2fACESPORTSWebUser%2fYYS%2fReserve%2fInquiryReserve' \
  --data "UserName=${ACE_USER}&Password=${ACE_PASSWORD}&TmpoCdSisetuCd=&LessonNo=0&SelectedDay=0&席番号=&MenuCd=&IsCalledScheduleDetail=False" \
  'https://www.e-atoms.jp/ACESPORTSWebUser/Account/Login'


# =========================
# 選択可能日付取得
# =========================
curl -L   -c cookies.txt   -b cookies.txt   'https://www.e-atoms.jp/ACESPORTSWebUser/YYS/Reserve'   -o reserve_init.html
grep 'option.*年' reserve_init.html | sed 's/.*value="//; s/".*//'

# =========================
# アウトドアコート（3面）
# =========================
for day in $(grep 'option.*年' reserve_init.html | sed 's/.*value="//; s/".*//'); do
  for court in 00001 00002 00003; do
    curl -L \
      -c cookies.txt \
      -b cookies.txt \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      -H 'Origin: https://www.e-atoms.jp' \
      -H 'Referer: https://www.e-atoms.jp/ACESPORTSWebUser/YYS/Reserve/InquiryReserve' \
      --data "tmpoCD=001&day=$day&sisetuGrpCD=00001&sisetuCD=${court}&hourCd=&ExecuteType=ChangeCond" \
      'https://www.e-atoms.jp/ACESPORTSWebUser/YYS/Reserve/InquiryReserve' \
      -o "${day}_court_outdoor_${court}.html"
  done
done

# =========================
# インドアコート（4面）
# =========================
for day in $(grep 'option.*年' reserve_init.html | sed 's/.*value="//; s/".*//'); do
  for court in 0000A 0000B 0000C 0000D; do
    curl -L \
      -c cookies.txt \
      -b cookies.txt \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      -H 'Origin: https://www.e-atoms.jp' \
      -H 'Referer: https://www.e-atoms.jp/ACESPORTSWebUser/YYS/Reserve/InquiryReserve' \
      --data "tmpoCD=001&day=$day&sisetuGrpCD=00002&sisetuCD=${court}&hourCd=&ExecuteType=ChangeCond" \
      'https://www.e-atoms.jp/ACESPORTSWebUser/YYS/Reserve/InquiryReserve' \
      -o "${day}_court_indoor_${court}.html"
  done
done
