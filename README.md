# Code examples for Master Class: Monitoring and alerting in Rancher 2.5

## Installation steps

Fill out `terraform-setup/terraform.tfvars` with aws and digital ocean credentials.

Create infrastructure and install Rancher

```
make install
```

## Configure Rancher

Go to https://rancher-demo.plgrnd.be/login and set up admin password and server url.

## Install rancher-monitoring

* In the local cluster, go to Cluster Explorer -> Apps & Marketplace.
* Install the rancher-monitoring app with the default settings

! NOTE: On Rancher <2.5.2, install from dev-v2.5 branch, enable k3s in yaml, increase memory limit to 3500Mi

## Explore rancher-monitoring

* See the helm install output
* Have a look at the installed workloads in `cattle-monitoring-system`.
* Have a look at Prometheus
    * Scraping targets
    * Built-in alerting rules
* Have a look at Grafana
    * Built-in dashboards
    * Logging into Grafana as admin

## Deploy your own workload and scrape it

* Deploy shop

```
kubectl -n default apply -f scrape-custom-service/01-demo-shop.yaml
```

* Have a look at shop

* Add prometheus-exporter to redis deployment

```
kubectl -n default apply -f scrape-custom-service/02-redis-prometheus-exporter.yaml
```

* Add ServiceMonitor for redis deployment

```
kubectl -n default apply -f scrape-custom-service/03-redis-servicemonitor.yaml
```

* See that Prometheus starts scraping Redis

* Add Redis Grafana dashboard

```
kubectl apply -f scrape-custom-service/04-redis-grafana-dashboard.yaml
```

* Add Redis PrometheusRule

```
kubectl -n default apply -f scrape-custom-service/05-redis-prometheus-rules.yaml
```

* Configure alertmanager

* Force alert

```
 kubectl -n default apply -f scrape-custom-service/05-redis-prometheus-rules-force-alert.yaml```
```
* See that alert fires

* Reset

```
kubectl -n default apply -f scrape-custom-service/05-redis-prometheus-rules.yaml
```

## More and more helm charts already include ServiceMonitors

```
helm repo add presslabs https://presslabs.github.io/charts
helm upgrade --install mysql-operator presslabs/mysql-operator --namespace mysql-operator --set serviceMonitor.enabled=true --create-namespace 
```

Add db

```
kubectl apply -f scrape-custom-service/06-mysql-cluster.yaml
```

Add rules and dashboard

```
kubectl apply -f scrape-custom-service/07-mysql-rules.yaml
kubectl apply -f scrape-custom-service/08-mysql-grafana-dashboard.yaml
```

## Logging

* Install rancher-logging

* Install loki

```
helm upgrade --install loki loki/loki --namespace loki -f logging/loki-values.yaml --create-namespace
```

* Add grafana datasource

```
kubectl apply -f logging/datasource.yaml
kubectl rollout restart deployment -n cattle-monitoring-system rancher-monitoring-grafana
```

* Add ClusterFlow and Output

```
kubectl apply -f logging/logging-cluster-flow.yaml
```

Wait a bit and show logs in Grafana Explorer for `{namespace="default"}`

## HPA

* Deploy sample app

```
kubectl -n default apply -f custom-metrics-hpa/deployment.yaml
```

Deploy HPA

```
kubectl -n default apply -f custom-metrics-hpa/hpa.yaml
```

Create load at https://sample-app.plgrnd.be/

```
watch kubectl describe hpa -n default
watch kubectl get pods -n default
```

## V1 to V2 migration

* Notifiers
* Dashboards
* Non Prometheus Query Alerts
* Prometheus Query Alerts


```
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-rules
  namespace: default
spec:
  groups:
    - name: custom.rules
      rules:
        - alert: Deployment with unavailable replicas
          expr: kube_deployment_status_replicas_unavailable > 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has {{ $value }} unavailable replicas"
```