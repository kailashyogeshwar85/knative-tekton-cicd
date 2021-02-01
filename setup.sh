 #!/bin/bash
 # Setup script for configuring all the required dependencies for Kubernetes
# minikube start --driver=docker --kubernetes-version=1.17.0
# installing knative
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.20.0/serving-crds.yaml

# Serving components
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.20.0/serving-core.yaml

#installing tekton trigger and tekton pipeline
# Pipeline

kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# Triggers
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml


# Tekton Dashboard
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml

echo "Creating namespace"
kubectl apply -f ./tekton/namespace

CONFIG_FILE=./tekton/secrets/secret.json

if [ ! -f "$CONFIG_FILE" ]; then
  echo "$CONFIG_FILE missing."
  echo "
    Follow Below Steps
    1. Go to Google Cloud Console and create Service Account
    2. Create key, and get the <some name>.json
    3. Rename json file to secret.json and copy to secrets directory
  "
  exit 1
fi
echo "Creating PUSH secret"

kubectl create secret generic gcr-secret-push \
        --from-file=.dockerconfigjson=./tekton/secrets/secret.json \
        --type=kubernetes.io/dockerconfigjson \
        --namespace=github-deployment

echo "Creating PULL secret of docker-registry type"
kubectl create secret docker-registry gcr-secret-pull-image \
          --docker-server=https://asia.gcr.io \
          --docker-username=_json_key \
          --docker-password="$(cat ./tekton/secrets/secret.json)" \
          --docker-email=johnsmith@example.com \
          --namespace=github-app-faas

# Patch default sa in namespace which will be used to pull image
kubectl --namespace=github-app-faas patch serviceaccount default \
          -p '{"imagePullSecrets": [{"name": "gcr-secret-pull-image"}]}'
# apply resources
echo "APPLYING TRIGGER CRDs"
kubectl apply -R -f ./tekton/triggers

echo "APPLYING SA"
kubectl apply -f ./tekton/account

echo "APPLYING PIPELINE"
kubectl apply -R -f ./tekton/pipelines

# Port Forward your event listener will be listening on port 8000
# kubectl port-forward $(kubectl get pod -o=name -n github-deployment) -n github-deployment 8080:8000
echo "Expost Event Listener with below command
      kubectl port-forward $(kubectl get pod -o=name -n github-deployment) -n github-deployment 8080:8000
    "

echo "Execute kubectl proxy & Open your browser at
  http://localhost:8001/api/v1/namespaces/tekton-pipelines/services/tekton-dashboard:http/proxy/
"