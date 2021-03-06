####################
# Create a cluster #
####################

# Install [doctl](https://github.com/digitalocean/doctl)

doctl auth init

doctl k8s cluster \
    create jx-rocks \
    --count 3 \
    --region nyc1 \
    --size s-2vcpu-4gb

kubectl config use do-nyc1-jx-rocks

# TODO: CA

####################################
# Install NGINX Ingress controller #
####################################

kubectl apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/1cd17cd12c98563407ad03812aebac46ca4442f2/deploy/mandatory.yaml

kubectl apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/1cd17cd12c98563407ad03812aebac46ca4442f2/deploy/provider/cloud-generic.yaml

export LB_IP=$(kubectl -n ingress-nginx \
    get svc -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")

echo $LB_IP # It might take a while until LB is created. Repeat the `export` command if the output is empty.

##############
# Install jx #
##############

# Static
jx install \
    --provider kubernetes \
    --external-ip $LB_IP \
    --domain jenkinx.$LB_IP.nip.io \
    --default-admin-password=admin \
    --ingress-namespace ingress-nginx \
    --ingress-deployment nginx-ingress-controller \
    --default-environment-prefix jx-rocks \
    --git-provider-kind github

# Serverless
jx install \
    --provider kubernetes \
    --external-ip $LB_IP \
    --domain $DOMAIN \
    --default-admin-password=admin \
    --ingress-namespace ingress-nginx \
    --ingress-deployment nginx-ingress-controller \
    --default-environment-prefix tekton \
    --git-provider-kind github \
    --namespace cd \
    --prow \
    --tekton

#######################
# Destroy the cluster #
#######################

doctl kubernetes cluster \
    delete jx-rocks \
    -f

# TODO: Delete the volumes

# TODO: Delete the LB