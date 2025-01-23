
secure:
TOKEN="eyJhbGciOiJSUzI1NiIsImtpZCI6IlQ5RXNsTDhhN3UyLVlEMW1Rb21ESXB0UXdVRmpEOTRDVjZmR0VMZjZUdWsifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJ0ZXN0LWF1dGhvcmlubyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJ0ZXN0LW1uaXN0LXNhIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6Im1uaXN0LXNhIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiNTc4Yjk4MmUtNDMxMS00YWJmLWEwNGUtMTZkOTM4YTliNzRkIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OnRlc3QtYXV0aG9yaW5vOm1uaXN0LXNhIn0.goVCSb8e7zKSrCd_haF7ZZCvy3zbvjTOzzpYVsMtPkwc3EaP29_QLtLnhegupyKvRj8dfpQGUp0ZVgLYogTXsmxJFSfQwgSpQVp9H81QgfmKT5MOtl3R7J78S7_GPFK1rsM4VYxt1X-hEXToSpRsCITREB8S-lmg67TE3U5JdGdZdiH8RwJeopEynjl2Kjy7Wo2MlGDPYXTR7p0_I72J9V9jiAy5uiwmjtDwweg1mWfxoompXnbjA3PlX59owtIR27FbM4WXEsF1bRIbZiD5MYK9jv1eM8EaZlSlGHgEgmYrGcOvuHs5Ll_j8wFs9db6uecD7VcDzhjcsVVVpkC86k_4MvyyfU2gkDQ4cu5wEol7drArlbXDp6rn2Cz7v1-V-j33CniF4WHvvxj7qJgPXzhrMG_osyBu4UCqEDxQLe9KY7lThU_5JqADo1m2Rbn6SS9fJ3iWUxlNxbzdyIjbVMJ4KjzlByRljJDwqsGYvOmqWLkW941RweX8YqW5YPI_QOBgYjLARRGFQZVIk7bbaDNieGYTm6_-HgLCsbghcNGypRgiDy-htZhlnTKt6GP8FIwhjzY1z_VVnPtqrpkrW3JwGwOKWdocZil02Hb2tw9X73s4TYJGupistn1zrHBhh4RdyQD-M0VPlADS6__ZHSALIXfO3etH1z37Y-CIQPQ"

curl --insecure -X POST -H "Authorization: Bearer $TOKEN" https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist/versions/1/infer -d @request-kserve.json       


insecure:
curl --insecure -X POST  https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist/versions/1/infer -d @request-kserve.json
curl --insecure -X POST  https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist/infer -d @request-kserve.json   
curl --insecure -X POST  https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist:predict -d @request-kserve.json   
curl --insecure https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist/ready

curl --insecure https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v1/models/noauth/ready


v2/models/resnet/ready

curl --insecure -X POST  https://mnist-test-authorino.apps.rosa.spolti.vqoo.p3.openshiftapps.com/v2/models/mnist/versions/1/infer -d @request-kserve.json