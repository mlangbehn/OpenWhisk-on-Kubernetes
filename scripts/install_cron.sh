#!/bin/bash -e

declare -A git_repos
git_repos+=( \
    ["incubator-openwhisk-deploy-kube"]=https://github.com/apache/incubator-openwhisk-deploy-kube.git )

install_bluemix_cli() {
    echo "Installing Bluemix cli"
    curl -L public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_0.5.4_amd64.tar.gz > Bluemix_CLI.tar.gz
    tar -xvf Bluemix_CLI.tar.gz
    sudo ./Bluemix_CLI/install_bluemix_cli
}

bluemix_auth() {
    echo "Authenticating with Bluemix"
    echo "1" | bx login -a https://api.ng.bluemix.net -u "$BLUEMIX_USER" -p "$BLUEMIX_PASS"
    bx plugin install container-service -r Bluemix
}

install_kubectl() {
    echo "Installing kubectl"
    curl -LO https://storage.googleapis.com/kubernetes-release/release/"$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"/bin/linux/amd64/kubectl
    chmod 0755 kubectl
    sudo mv kubectl /usr/local/bin
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

main() {
    install_bluemix_cli
    bluemix_auth
    install_kubectl
    install_wsk
    install_git_repos
}

main "$@"
