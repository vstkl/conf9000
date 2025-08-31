#!/usr/bin/bash

function since() {
TARGET=1748222226
d_now=$(date +%-d)
d_target=$(date -d "@$TARGET" +%-d)
d_diff=$(($d_now - $d_target))

m_now=$(date +%-m)
m_target=$(date -d "@$TARGET" +%-m)
m_diff=$(($m_now - $m_target))

y_now=$(date +%-Y)
y_target=$(date -d "@$TARGET" +%-Y)
y_diff=$(($y_now - $y_target))

YEAR=365*24*60

echo "$d_now - $d_target = $d_diff"
echo "$m_now - $m_target = $m_diff"
echo "$y_now - $y_target = $y_diff"

result=""

if [[ $d_diff -ge 0 ]]; then
  result=$result$d_diff"d"
elif [[ $d_diff -le 0 ]]; then
  m_diff=$(($m_diff + 1))

  d_diff=$(($(date -d "@$TARGET" +%-d) $d_diff ))
  result=$result$d_diff"d"
fi
if [[ $m_diff > 0 ]]; then
  result=$result$m_diff"m"
fi
if [[ $y_diff > 0 ]]; then
  result=$result$y_diff"y"
fi
echo $result" ago"

}
alias since='since'
