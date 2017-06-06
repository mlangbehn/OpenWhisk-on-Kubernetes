#!/bin/bash -ex

ETCD_VERSION="v3.1.8"

declare -A git_repos
git_repos+=( \
    ["incubator-openwhisk-deploy-kube"]=https://github.com/apache/incubator-openwhisk-deploy-kube.git \
    ["kubernetes"]=https://github.com/kubernetes/kubernetes.git )

install_etcd() {
    echo "Installing etcd"
    curl -LO https://github.com/coreos/etcd/releases/download/"$ETCD_VERSION"/etcd-"$ETCD_VERSION"-linux-amd64.tar.gz
    tar xzf etcd-"$ETCD_VERSION"-linux-amd64.tar.gz
    sudo mv etcd-"$ETCD_VERSION"-linux-amd64/etcd /usr/local/bin
    rm -rf etc-"$ETCD_VERSION"-linux-amd64*
}

install_kubectl() {
    echo "Installing kubectl"
    curl -LO https://storage.googleapis.com/kubernetes-release/release/"$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"/bin/linux/amd64/kubectl
    chmod 0755 kubectl
    sudo mv kubectl /usr/local/bin
}

install_cfssl() {
    go get -u github.com/cloudflare/cfssl/cmd/...
}

install_wsk() {
    echo "Installing wsk"
    curl -LO https://openwhisk.ng.bluemix.net/cli/go/download/linux/amd64/wsk
    chmod 0755 wsk
    sudo mv wsk /usr/local/bin
}

install_git_repos() {
    mkdir -p "$HOME/git"
    pushd "$HOME/git"
    for repo in "${!git_repos[@]}"; do
        echo "Installing $repo to $HOME/git"
        if [[ -d "$repo" ]]; then
            pushd "$repo"
        else
            git clone "${git_repos[$repo]}"
            pushd "$repo"
        fi
        git fetch --all
        git reset --hard origin/master
        popd
    done
    popd
}

start_k8s() {
    pushd "$HOME/git/kubernetes"
    echo "Configure kubectl"
    kubectl config set-credentials myself --username=admin --password=admin
    kubectl config set-context local --cluster=local --user=myself
    kubectl config set-cluster local --server=http://localhost:8080
    kubectl config use-context local
    echo "Start local k8s cluster"
    sudo PATH="$PATH":"$HOME"/.gimme/versions/go1.7.4.linux.amd64/bin/go ./hack/local-up-cluster.sh
    # Verify k8s is running and reachable
    popd
}

main() {
    sudo ip link set docker0 promisc on
    install_etcd
    install_kubectl
    install_cfssl
    install_wsk
    install_git_repos
    start_k8s
}

main "$@"
