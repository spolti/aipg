#!/bin/bash

# e.g.:
# X=30 ./run-request.sh https://example-onnx-mnist-test-rhoaieng-3115.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/example-onnx-mnist/infers

url=$1

if [ -z "$url" ]; then
    echo "Usage: $0 <url>"
    echo "to set the number of requests do X=10 $0 <url>"
    exit 1
fi
# NAMESPACE="test-rhoaieng-3115"
# export HOST_URL=$(oc get route example-onnx-mnist -ojsonpath='{.spec.host}' -n ${NAMESPACE})
# export HOST_PATH=$(oc get route example-onnx-mnist  -ojsonpath='{.spec.path}' -n ${NAMESPACE})


for i in $(seq 1 ${X:-1}); do
    echo "request ${i} of ${X:-1}"
    response=$(curl -s --insecure -w "%{http_code}" -X POST -H "Content-Type: application/json" -d @request.json ${url})
    # response=$(curl -s --insecure -w "%{http_code}" -X POST -d @request.json ${url})
    http_code=$(echo "$response" | tail -c 4)
    echo  "######## $http_code -- ${response}"
    echo
    sleep 0.5 # sleep for 0.5 seconds
    # curl --silent --location --fail --show-error --insecure https://${HOST_URL}${HOST_PATH}/infer -d  @${COMMON_MANIFESTS_DIR}/input-onnx.json
done
