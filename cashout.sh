#1/usr/bin/env sh
DEBUG_API=http://127.0.0.1:2635
MIN_AMOUNT=5

function getPeers() {
  curl -s "$DEBUG_API/chequebook/cheque" | jq -r '.lastcheques | .[].peer'
}

function getip() {
  curl -s https://ipinfo.io/ | jq -r .ip
}

function getCumulativePayout() {
  local peer=$1
  local cumulativePayout=$(curl -s "$DEBUG_API/chequebook/cheque/$peer" | jq '.lastreceived.payout')
  if [[ $cumulativePayout == null ]]
  then
    echo 0
  else
    echo $cumulativePayout
  fi
}

function getLastCashedPayout() {
  local peer=$1
  local cashout=$(curl -s "$DEBUG_API/chequebook/cashout/$peer" | jq '.cumulativePayout')
  if [[ $cashout == null ]]
  then
    echo 0
  else
    echo $cashout
  fi
}

function getUncashedAmount() {
  local peer=$1
  local cumulativePayout=$(getCumulativePayout $peer)
  if [[ $cumulativePayout == 0 ]]
  then
    echo 0
    return
  fi

  cashedPayout=$(getLastCashedPayout $peer)
  if [[ $cumulativePayout ]]; then
  	let uncashedAmount=$(($cumulativePayout-$cashedPayout))
  fi
  echo $uncashedAmount
}

function cashout() {
  local peer=$1
  txHash=$(curl -s -XPOST "$DEBUG_API/chequebook/cashout/$peer" | jq -r .transactionHash) 

  echo cashing out cheque for $peer in transaction $txHash >&2

#  result="$(curl -s $DEBUG_API/chequebook/cashout/$peer | jq .result)"
#   while [[ "$result" == "null" ]]
#   do
#     sleep 5
#     result=$(curl -s $DEBUG_API/chequebook/cashout/$peer | jq .result)
#   done
}

function cashoutAll() {
  local minAmount=$1
  for peer in $(getPeers)
  do
    local uncashedAmount=$(getUncashedAmount $peer)
    if [[ "$uncashedAmount" > 0 ]]
    then
      echo "uncashed cheque for $peer ($uncashedAmount uncashed)" >&2
      local ip=$(getip)
      echo "ip:$ip receive gbzz $uncashedAmount" | mail -s "出矿通知" 791023293@qq.com
      cashout $peer
    fi
  done
}

function listAllUncashed() {
  for peer in $(getPeers)
  do
    local uncashedAmount=$(getUncashedAmount $peer)
    if [[ "$uncashedAmount" > 0 ]]
    then
      echo $peer $uncashedAmount
    fi
  done
}


echo "execing..."
cashoutAll
