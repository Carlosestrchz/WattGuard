for i in {1..20}; do
  WATTS_SW=$(echo "scale=1; 120 + $RANDOM % 60" | bc)
  WATTS_A=$(echo "scale=1; 60 + $RANDOM % 40" | bc)
  WATTS_B=$(echo "scale=1; 20 + $RANDOM % 30" | bc)

  mosquitto_pub -t "wattguard/switch/a" \
    -m "{\"nodeId\":\"switch-proto.V1\",\"canal\":\"a\",\"watts\":$WATTS_SW,\"amps\":0.94,\"temp\":30.1,\"relay\":true}"

  mosquitto_pub -t "wattguard/gemelo/a" \
    -m "{\"nodeId\":\"twin-proto.V1\",\"canal\":\"a\",\"watts\":$WATTS_A,\"amps\":0.55,\"temp\":27.8,\"relay\":true}"

  mosquitto_pub -t "wattguard/gemelo/b" \
    -m "{\"nodeId\":\"twin-proto.V1\",\"canal\":\"b\",\"watts\":$WATTS_B,\"amps\":0.22,\"temp\":27.8,\"relay\":false}"

  sleep 2
done
