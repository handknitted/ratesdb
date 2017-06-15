# mysql cost-analytics instance
A mysql instance intended to provide persistence for rates within the cost-analytics-api.
 
## Usage

1 Start a kubernetes 'cluster' - to make this easy we'll use minikube

  See http://kubernetes.io/docs/getting-started-guides/minikube/

  *but basically it's a couple of simple gets from googlapis:*

    curl -Lo kubectl http://storage.googleapis.com/kubernetes-release/release/v1.5.1/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.15.0/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/

  Start minikube with a little more resource than the puny default

    minikube start --cpus 2 --memory 4096 --disk-size 10g
  
  N.B. If behind a proxy append

    --docker-env http_proxy=$http_proxy --docker-env https_proxy=$https_proxy
  
  and run 
  
    export no_proxy=$no_proxy,$(minikube ip)

  Then

    kubectl config use-context minikube # this happens by default but maybe you'll need it if in a different console?
    minikube dashboard # opens the dashboard in default browser


2 Install Helm locally and set up the minikube environment

    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
    chmod 700 get_helm.sh
    ./get_helm.sh

  Provided you have the minikube env set up to respond to kubectl you can just
  
    helm init

3 Generate the helm chart for ratesdb

      cd ratesdb/
      helm package .

4 Start ratesdb

    helm install ratesdb --namespace handknitted --name ratesdb

  To take down our services with helm is simple.  When the chart is released a
  daft name is assigned it.  If you forget it no problem:
  
    helm list
    
  then the list of releases and their corresponding charts provides you with
  the required name (for instance 'manageable-jaguar' and 'lanky-marsupial'):
  
    helm delete --purge manageable-jaguar
    helm delete --purge lanky-marsupial
    
  the `--purge` is required to leave the namespace clear.  Otherwise resources
  still exist, even if they didn't install successfully.
 
5 Proxy the pod to a local port

    kubectl port-forward -n handknitted ratesdb-sql-controller-xxxxx 3306
    
6 Test that the proxying is working

    $  mysql -u cost-analytics --host localhost --protocol=TCP -p
    [Enter password 'password' by default]
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 2
    Server version: 5.5.56 MySQL Community Server (GPL)
    .....

7 To have a look at what's going on

  Get a console on the ratesdb pod

    kubectl exec ratesdb -n handknitted -i -t -- bash
