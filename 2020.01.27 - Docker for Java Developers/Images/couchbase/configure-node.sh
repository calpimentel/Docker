#!/bin/bash

set -x
set -m

/entrypoint.sh couchbase-server &

sleep 15

# Aqui começa a rest API
#--------------------------------------------------------------------------------------------------------------------
# Setup index and memory quota
curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=300 -d indexMemoryQuota=300

# Setup services
curl -v http://127.0.0.1:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex

# Setup credentials
curl -v http://127.0.0.1:8091/settings/web -d port=8091 -d username=Administrator -d password=password

# Setup Memory Optimized Indexes
curl -i -u Administrator:password -X POST http://127.0.0.1:8091/settings/indexes -d 'storageMode=memory_optimized'

# Load travel-sample bucket
#curl -v -u Administrator:password -X POST http://127.0.0.1:8091/sampleBuckets/install -d '["travel-sample"]'

#---------------------------------------------------------------------------------------------------------------------


# Configura uma variavel = MASTER/WORKER
echo "Type: $TYPE"

# Se MASTER nada acontece, mas se for WORKER, vai configurar o server
if [ "$TYPE" = "WORKER" ]; then
  echo "Sleeping ..."
  sleep 15

  #IP=`hostname -s`
  IP=`hostname -I | cut -d ' ' -f1`
  echo "IP: " $IP

  echo "Auto Rebalance: $AUTO_REBALANCE"
  if [ "$AUTO_REBALANCE" = "true" ]; then
    couchbase-cli rebalance --cluster=$COUCHBASE_MASTER:8091 --user=Administrator --password=password --server-add=$IP --server-add-username=Administrator --server-add-password=password
  else
    couchbase-cli server-add --cluster=$COUCHBASE_MASTER:8091 --user=Administrator --password=password --server-add=$IP --server-add-username=Administrator --server-add-password=password
  fi;
fi;

fg 1
