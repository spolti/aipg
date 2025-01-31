
secure:
> this token is obtained from openShift Cluster, at this point it is n
TOKEN="${SA_TOKEN}"

curl --insecure -X POST -H "Authorization: Bearer $TOKEN" https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist/versions/1/infer -d @request-kserve.json       


insecure:
curl --insecure -X POST  https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist/versions/1/infer -d @request-kserve.json
curl --insecure -X POST  https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist/infer -d @request-kserve.json   
curl --insecure -X POST  https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist:predict -d @request-kserve.json   
curl --insecure https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist/ready

curl --insecure https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v1/models/noauth/ready


v2/models/resnet/ready

curl --insecure -X POST  https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist/versions/1/infer -d @request-kserve.json