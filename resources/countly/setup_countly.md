# Setup of GCP resources

This document describes a minimal and low-cost setup of GCP resources in order to deploy the community version of [Countly](https://github.com/Countly/countly-server). 
Countly is used to obtain crash logs and anonymized usage data.
Alternatively, you can use any other cloud provider, Kubernetes as-a-service-provider (such as [Gardener](https://gardener.cloud)) or host Countly on premise.

Most likely this documentation is outdated when you read this, so read it with a grain of salt.

## Setup GKE cluster

**Attention**: This setup should only be used during evaluation period.
It is insufficient for productive usage in many regards ( e.g no node autoscaling, no SSD disks, low CPU and memory, no logging stack, ...).  
The sole purpose is to have a minimal installation at a minimum cost.

**Use gcloud to setup a GKE cluster** 
 -  public cluster to avoid having to setup a NAT Gateway
 -  two instance groups with one node each of type `g1-small`. 
    One instance group has 30 GiB of persistent storage for the mongo DB cluster (the other one only 10).
 -  instances are preemtible  
 -  K8s version `1.17.14-gke.400` (regular channel at the time of writing)

```
GKE_CLUSTER_NAME=<my-cluster>
GCP_PROJECT_NAME=<my-project>
gcloud beta container --project "$GCP_PROJECT_NAME" clusters create "$GKE_CLUSTER_NAME" --zone "europe-west1-c" --no-enable-basic-auth --cluster-version "1.17.14-gke.400" --release-channel "regular" --machine-type "g1-small" --image-type "COS_CONTAINERD" --disk-type "pd-standard" --disk-size "30" --node-labels pool=mongo --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --max-pods-per-node "110" --preemptible --num-nodes "1" --no-enable-stackdriver-kubernetes --enable-ip-alias --network "projects/mediathekviewmobile-real/global/networks/default" --subnetwork "projects/mediathekviewmobile-real/regions/europe-west1/subnetworks/default" --default-max-pods-per-node "110" --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --maintenance-window-start "2021-01-15T01:00:00Z" --maintenance-window-end "2021-01-15T08:00:00Z" --maintenance-window-recurrence "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR" --autoscaling-profile optimize-utilization --enable-shielded-nodes --no-shielded-integrity-monitoring && gcloud beta container --project "mediathekviewmobile-real" node-pools create "default" --cluster "mediathekviewmobile-clone-1" --zone "europe-west1-c" --machine-type "g1-small" --image-type "COS_CONTAINERD" --disk-type "pd-standard" --disk-size "15" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --preemptible --num-nodes "1" --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --max-pods-per-node "110"
```

Taint the mongo pool with NoSchedule to make sure MongoDB will be the only pod running on it.
```
kubectl taint node <node-from-mongo-pool> app=mongodb:NoSchedule
```

Also apply the priority classes that we'll use in the following.

```
kubectl apply -f ../k8s/priority
```

## Deploy MongoDB

MongoDB is the backend used for Countly.
This document uses the [MongoDB Community Operator](https://github.com/mongodb/mongodb-kubernetes-operator) for the setup.

Install the operator and the CRD into the GKE cluster.

```
kubectl apply -f ../k8s/mongo-db/operator
```

Then create the MongoDB custom resource 
  - only uses one replica in this example
  - using low resource limits (will not scale)
  - uses NodeSelector and Toleration to make sure it will be deployed on the Nodes tainted for mongoDB.
    (The mongo DB pool has a larger disk).
    
```
kubectl apply -f ../k8s/mongo-db/resources
```

This should create the mongoDB pod with name `mediathekviewmobile-mongodb-0`
Check mongoDB is working (you need to have the mongo CLI installed locally for the test):

```
kubectl port-forward  svc/mediathekviewmobile-mongodb-svc  27017:27017
mongo "mongodb://mediathekviewmobile:<my-password>@localhost:27017/admin?authSource=admin"
show collections
```

## Deploy Counlty 

Deploy Countly using MongoDB as the data store.

```
kubectl apply -f ../k8s/countly
```

Then 
```
kubectl port-forward  svc/countly-frontend  8080:6001
```
Make sure you can view the Countly frontend under `http://localhost:8080`.

## Expose the Countly API 

**Prerequisite**: Purchase / Own a domain to use (we do not want to serve on a static IP address).

### Obtain a valid certificate for your endpoint

This guide uses [cert-manager](https://cert-manager.io) to obtain a valid certificate for your domain.
Follows [this setup Guide](https://cert-manager.io/docs/configuration/acme/dns01/google/) for Cert-manager using CloudDNS.

Follow the [cert-manager](https://cert-manager.io/docs/installation/kubernetes/) docs to install it.

We use the DNS01 challenge with cert-manager.
Hence, we need the DNS provider's credentials. 
This guide uses CloudDNS.

Get CloudDNS credentials for your account & project.

```
GCP_PROJECT=mediathekviewmobile-real #my project
gcloud iam service-accounts create dns-admin \
    --display-name=dns-admin \
    --project=${GCP_PROJECT}

gcloud iam service-accounts keys create ./gcp-dns-admin.json \
    --iam-account=dns-admin@${GCP_PROJECT}.iam.gserviceaccount.com \
    --project=${GCP_PROJECT}

gcloud projects add-iam-policy-binding ${GCP_PROJECT} \
    --member=serviceAccount:dns-admin@${GCP_PROJECT}.iam.gserviceaccount.com \
    --role=roles/dns.admin
```

The `file gcp-dns-admin.json` contains the credentials.

```
kubectl create secret generic --namespace cert-manager clouddns-credentials \
    --from-file=./gcp-dns-admin.json
```

Create the issuer.
Make sure to insert your own E-Mail and domain names.

```
kubectl apply -f ../k8s/cert-manager
```

## Expose the Countly API


Install an ingress controller into the cluster.
We do not use the default GKE ingress controller to save the cost of a LoadBalancer in this setup.
Install nginx from [here](https://kubernetes.github.io/ingress-nginx/deploy/#gce-gke).

Then create the nodeport service that points to the nginx ingress controller pod.

```
kubectl apply -f ../k8s/expose-countly/nodeport-svc-to-ingress.yaml
```

Open firewall ports to allow traffic nodeports (source range 0.0.0.0/0)
```
gcloud compute firewall-rules create mediathekview-nodeport-access --allow tcp:32080,tcp:32443
```

Obtain the public IP of on of our nodes in the cluster (only works because nodes are in a public subnet 
- otherwise, we need to use a LoadBalancer or similar).

Create an A record of your custom domain with your DNS provider pointing to this public IP.
Note: we will use external-dns in the next step to automate this, don't worry.

Now the packet flow looks roughly like this:

```
Domain -> public-IP-VM:<NodePort> (allowed due to firewall-rules) -> kube-proxy - IpTable rules /... -> nginx-ingress (TLS termination) -> countly-frontend / backend service
```

Check that you can reach the instance public IP and nodeport
```
curl -v <public-IP>:32080/
*   Trying <public-IP>...
* TCP_NODELAY set
* Connected to <public-IP> (<public-IP>) port 32080 (#0)
> GET / HTTP/1.1
> Host: 34.78.83.232:32080
> User-Agent: curl/7.64.1
> Accept: */*
```

Then create the ingress resource 
  - has a cert manager annotation to obtain a valid LetsEncrypt certificate.

```
kubectl apply -f ../k8s/expose-countly/countly-ingress-gce.yaml
```
Wait for the certificate to be READY.

Check that you can successfully reach the Countly Frontent and Backend.

```
curl -v https://<xy.mydomain>.de:32443
Server certificate:
*  subject: CN=*.<mydomain>.de
*  start date: Jan 19 12:00:17 2021 GMT
*  expire date: Apr 19 12:00:17 2021 GMT
*  subjectAltName: host "x.<xy.mydomain>.de" matched cert's "*.<mydomain>.de"
*  issuer: C=US; O=Let's Encrypt; CN=R3
*  SSL certificate verify ok.
```

Then visit the Countly Frontend at `https://<xy.mydomain>.de:32443`, will redirect to `/login`.

**TIP**: If you got problems with the TLS termination at the ingress controller (e.g does not use your certificate),
try to add the flag  `--default-ssl-certificate` to the nginx deployment pointing to your tls secret created by the cert manager.

## Setup External DNS 

This is only useful because we use a low-cost setup that uses services of type NodePort with
ephemeral public Ips (in public subnet) and ephemeral instances (can be destroyed any time).
Hence, we need a solution to advertise the changing public IPs of our VMs to our DNS domain.
In essence, we use DNS as a poor-man's Load Balancer solution.

Instead, we could also use a LoadBalancer or allocate a static ip address and assign it to
a non-ephemeral VM, or similar.
If in a previous step, you create the static IP and pointed it to a VM with a NodePort in the cluster,
you can delete this static IP again.

Create the external DNS deployment in the `cert-manager` namespace (needs access to cloud dns secret created earlier - can be improved).

```
kubectl apply -f ../k8s/expose-countly/countly-ingress-gce.yaml
```

Annotate the NodePort service to sync the public IPs of all Nodes in the cluster 
to an A record for your specified domain.
This way, Node can be killed and assigned a new IP any time, and the controller keeps the
DNS records up-to date.

```
kubectl -n ingress-nginx annotate svc ingress-nginx-controller external-dns.alpha.kubernetes.io/hostname="*.mediathekviewmobile.de"
```