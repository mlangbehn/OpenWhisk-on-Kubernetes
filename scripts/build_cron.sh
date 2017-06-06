#!/bin/bash -e

bluemix_auth() {
    echo "Authenticating with Bluemix"
    echo "1" | bx login -a https://api.ng.bluemix.net -u "$BLUEMIX_USER" -p "$BLUEMIX_PASS"
}

clean_cluster() {
    bx cs workers "$CLUSTER"
    $(bx cs cluster-config "$CLUSTER" | grep export)
    echo "Deleting openwhisk namespace if it exists..."
    kubectl delete --ignore-not-found=true -f "$HOME"/git/incubator-openwhisk-deploy-kube/configure/openwhisk_kube_namespace.yml
    kuber=$(kubectl get ns | grep openwhisk)
    while [ ${#kuber} -ne 0 ]
    do
        sleep 30s
        kubectl get ns
        kuber=$(kubectl get ns | grep openwhisk)
    done
    echo "Cluster is clean"
}

deploy_cluster() {
    echo "Creating openwhisk namespace..."
    kubectl apply -f "$HOME"/git/incubator-openwhisk-deploy-kube/configure/openwhisk_kube_namespace.yml
    echo "Creating ClusterRoleBinding..."
    kubectl apply -f permission.yaml
    echo "Creating openwhisk job"
    kubectl apply -f "$HOME"/git/incubator-openwhisk-deploy-kube/configure/configure_whisk.yml
    kubectl get -n openwhisk jobs
    kuber=$(kubectl get -n openwhisk jobs | grep configure | awk '{print $3}')
    while [[ $kuber -eq 0 ]] || [[ -z $kuber ]]
    do
        echo "Configuring openwhisk.."
        sleep 15s
        kubectl get -n openwhisk jobs
        kuber=$(kubectl get -n openwhisk jobs | grep configure | awk '{print $3}')
    done
}

test_openwhisk() {
    echo "Getting IP and Port"
    IP=$(kubectl get nodes | grep Ready | awk '{print $1}')
    kubectl get nodes
    AUTH_SECRET=$(kubectl -n openwhisk get secret openwhisk-auth-tokens -o yaml | grep 'auth_whisk_system:' | awk '{print $2}' | base64 --decode)
    WSK_PORT=$(kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1)
    if [ -z "$IP" ] || [ -z "$AUTH_SECRET" ] || [ -z "$WSK_PORT" ]
    then
        echo "IP, AUTH_SECRET, or NODEPORT not found"
        exit 1
    fi
    kubectl get pods -n openwhisk
    echo "Testing OpenWhisk"
    wsk property set --auth "$AUTH_SECRET" --apihost https://"$IP":"$WSK_PORT"
    wsk -i action invoke /whisk.system/utils/echo -p message hello --blocking --result
}

main() {
    bluemix_auth
    clean_cluster
    deploy_cluster
    test_openwhisk
}

main "$@"
