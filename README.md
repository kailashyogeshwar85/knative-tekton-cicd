# knative-tekton-cicd
Project Implementing Native K8's CI/CD using Knative for FaaS Tekton Pipeline &amp; Tekton Trigger for CI/CD implementation

# tekton-pipelines

Tekton pipeline poc project created for Wmio connector.

Pipeline is responsible for building the source code which is uploaded to s3 and create a k8's knative service.

## Pre Requisites
*  Create Alias for kubectl in .bashrc as `kc`
*  K8s cluster minikube for local with kubernetes-version=1.17.0
*  Knative installation on cluster
*  Istio service mesh
*  tekton-pipelines for CI/CD
*  tekton-trigger for dynamic pipeline resource and pipeline run creation and webhook based pipeline invokation.

## Expose Event Listener to Host
`kc port-forward $(kc get pod -o=name -n github-deployment) -n github-deployment 8080:8000`

## Invoke Webhook
``` bash
curl --location --request POST 'http://localhost:8080' \
    --header 'Content-Type: application/json' \
    --data-raw '{
      "repoUrl": "https://github.com/kailashyogeshwar85/knative-nodeapp.git"
    }
```
## AutoScaling Testing
``` bash
# This command can only be executed from the cluster
curl -X POST \
     -H 'Host: github-nodeapp.github-app-faas.svc.cluster.local' \
     -H 'Content-Type: application/json' \
     -d '{"Payload":"{\"type\":\"action\",\"version\":\"v1\",\"func\":\"print\",\"input\":{\"log\":\"Hello I am Logger\"}}"}' \
     'http://github-nodeapp.github-app-faas.svc.cluster.local'

#  OR
# It will run automated loadtesting using hey benchmark tool with 10 rps
kc apply -f jobs/
```


Steps
- Create Service Accounts for below resources
     - trigger
     - pipeline
     - image pull/push
     - knative service
- Create Trigger EventListener for exposing Webhook URL
- Create TriggerBinding to map body.properties to params.
- Create TriggerTemplate to pass the binded params to pipeline as input params.
- Create PipelineResource & Define Pipeline
- Create Task and add steps to it
- Reference task from Pipeline and pass the required params as input to the task.
- Process the params and build the image and push it to registry.
- Two ways to create service:
  - Create Task for Service creation
  - Send Acknowledgement to calling service which will use helm for installing service (params = imageUrl@digest)

### LESSONS LEARNT:
  While writing article I had tested on older knative version which had different rules for specifying `triggertemplate` & `triggerbinding` using name.
  Now it is referenced using `ref` directive.

# DEBUGGING
- Add sleep TIME_IN_SEC step to inspect step
- kc  exec -it github-deploy-pipeline-run-fj6nc-build-source-9hqg4-pod-l2fsc --container step-inspect -n github-deployment -- /bin/bash
## Testing Auto Scaling
It will create a JOB and loadtest your FaaS using `hey` tool to see the autoscalling in effect.

## Additional Tools
Jaegar: It can be used for E2E distributed tracing of the request. Written in go and UX is user friendly.
Prometheus/Grafana: Monitoring tool for seeing realtime RPS and autoscalling in effect.
---
Happy Coding