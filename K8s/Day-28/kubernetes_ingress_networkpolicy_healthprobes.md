# Kubernetes Training: Ingress, Network Policies & Health Probes

## Killercoda Hands-on Lab

**Level:** Beginner to Intermediate\
**Environment:** Killercoda Kubernetes Playground\
**Application:** NGINX\
**Topics:**

1.  Ingress --- HTTP/HTTPS Traffic Management
2.  Network Policies --- Traffic Firewall
3.  Health Probes --- Application Reliability

------------------------------------------------------------------------

# Lab Preparation

Open a Kubernetes playground in Killercoda.

Recommended environment:

-   Kubernetes cluster
-   One terminal
-   `kubectl` command available
-   An Ingress controller installed, preferably NGINX Ingress Controller

## Check the Cluster

``` bash
kubectl get nodes
```

Expected output:

``` text
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   ...   ...
```

Check namespaces:

``` bash
kubectl get namespaces
```

Check existing pods:

``` bash
kubectl get pods -A
```

Create a lab namespace:

``` bash
kubectl create namespace web-lab
```

Use the namespace:

``` bash
kubectl config set-context --current --namespace=web-lab
```

Verify:

``` bash
kubectl config view --minify --output 'jsonpath={..namespace}'
```

Expected:

``` text
web-lab
```

> If Killercoda already contains an Ingress controller, use it. If not,
> the Ingress resource may remain in a `Pending` state or may not route
> traffic. The Ingress demonstrations below include a controller check.

------------------------------------------------------------------------

# Part 1: Ingress --- HTTP/HTTPS Traffic Management

## 1. What Is Ingress?

Ingress is a Kubernetes API object used to manage external HTTP and
HTTPS traffic entering a cluster.

It provides routing rules that send incoming requests to Kubernetes
Services.

Simple example:

``` text
User Browser
     |
     | http://shop.example.com
     v
Ingress Controller
     |
     v
Ingress Rules
     |
     v
Service
     |
     v
Pods
```

Ingress is commonly used for:

-   Host-based routing
-   Path-based routing
-   TLS/HTTPS termination
-   Routing multiple applications through one external entry point
-   Sending traffic to different Services

## 2. Important Difference: Ingress vs Ingress Controller

### Ingress

Ingress is the Kubernetes configuration object containing routing rules.

Example:

``` yaml
kind: Ingress
```

### Ingress Controller

The Ingress Controller is the actual software that watches Ingress
resources and configures a reverse proxy or load balancer.

Examples:

-   NGINX Ingress Controller
-   Traefik
-   HAProxy
-   Kong
-   cloud-provider Ingress controllers

**Important:** Creating an Ingress object alone does not route traffic.
A compatible Ingress Controller must be installed and running.

## 3. Ingress vs Service

  -----------------------------------------------------------------------
  Feature                 Service                 Ingress
  ----------------------- ----------------------- -----------------------
  Main purpose            Exposes Pods internally Routes HTTP/HTTPS
                          or externally           requests

  Traffic type            TCP/UDP and other       Mainly HTTP/HTTPS
                          supported traffic       

  Routing                 Selects Pods using      Routes using host and
                          labels                  path

  Common types            ClusterIP, NodePort,    Ingress resource
                          LoadBalancer            

  Example                 `web-service`           `shop.example.com`

  Layer                   Commonly Layer 4        Commonly Layer 7
  -----------------------------------------------------------------------

## 4. Why Do We Use Ingress?

Without Ingress, an application may need a separate external Service:

``` text
Application A -> LoadBalancer Service
Application B -> LoadBalancer Service
Application C -> LoadBalancer Service
```

With Ingress:

``` text
                    +-------------------+
Application A ------|                   |
Application B ------| Ingress Controller|---- External IP
Application C ------|                   |
                    +-------------------+
                              |
                   +----------+----------+
                   |          |          |
                 Service A  Service B  Service C
```

This can reduce the number of external entry points and centralize HTTP
routing.

------------------------------------------------------------------------

## Demo 1: Deploy an NGINX Application

Create a Deployment:

``` bash
kubectl create deployment nginx-app \
  --image=nginx:1.25 \
  --replicas=2
```

Check the Deployment:

``` bash
kubectl get deployments
```

Check Pods:

``` bash
kubectl get pods -o wide
```

Expected:

``` text
NAME                         READY   STATUS    RESTARTS   AGE
nginx-app-xxxxxxxxxx-xxxxx   1/1     Running   0          ...
nginx-app-xxxxxxxxxx-yyyyy   1/1     Running   0          ...
```

Expose the Deployment using a ClusterIP Service:

``` bash
kubectl expose deployment nginx-app \
  --name=nginx-service \
  --port=80 \
  --target-port=80 \
  --type=ClusterIP
```

Check the Service:

``` bash
kubectl get service nginx-service
```

Expected:

``` text
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
nginx-service   ClusterIP   10.xxx.xxx.xxx  <none>        80/TCP
```

### Test the Service Internally

Run a temporary curl Pod:

``` bash
kubectl run curl-test \
  --image=curlimages/curl:8.10.1 \
  --rm -it \
  --restart=Never \
  -- curl http://nginx-service
```

Expected output includes:

``` html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

### Explain to Students

-   The Deployment creates and maintains Pods.
-   The Service provides a stable virtual IP and DNS name.
-   The Service selects Pods using labels.
-   The Service is internal because it is a ClusterIP.
-   Ingress will provide HTTP routing from outside the cluster.

------------------------------------------------------------------------

## Demo 2: Create an Ingress Resource

Create a file:

``` bash
nano ingress.yaml
```

Add:

``` yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: nginx.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-service
                port:
                  number: 80
```

Apply it:

``` bash
kubectl apply -f ingress.yaml
```

Check it:

``` bash
kubectl get ingress
```

Detailed output:

``` bash
kubectl describe ingress nginx-ingress
```

Possible output:

``` text
Name:             nginx-ingress
Namespace:        web-lab
Address:
Ingress Class:    nginx
Rules:
  Host          Path  Backends
  ----          ----  --------
  nginx.local
                /     nginx-service:80
```

### Understand the YAML

``` yaml
apiVersion: networking.k8s.io/v1
```

Uses the stable Kubernetes Ingress API.

``` yaml
kind: Ingress
```

Creates an Ingress object.

``` yaml
metadata:
  name: nginx-ingress
```

Names the Ingress resource.

``` yaml
spec:
  ingressClassName: nginx
```

Selects the Ingress Controller class named `nginx`.

``` yaml
rules:
  - host: nginx.local
```

Requests with the Host header `nginx.local` match this rule.

``` yaml
path: /
pathType: Prefix
```

Routes requests beginning with `/`.

``` yaml
backend:
  service:
    name: nginx-service
    port:
      number: 80
```

Sends matching requests to `nginx-service` on port 80.

------------------------------------------------------------------------

## Demo 3: Check the Ingress Controller

List IngressClasses:

``` bash
kubectl get ingressclass
```

Check all Ingress Controller Pods:

``` bash
kubectl get pods -A | grep -i ingress
```

Check Services:

``` bash
kubectl get svc -A | grep -i ingress
```

If the controller is in a namespace such as `ingress-nginx`:

``` bash
kubectl get pods -n ingress-nginx
```

``` bash
kubectl get svc -n ingress-nginx
```

### If No Ingress Controller Exists

The Ingress resource can still be created, but traffic will not be
routed until a compatible controller is installed.

In Killercoda, use the scenario's provided controller installation
instructions if available. Do not assume that every Kubernetes
playground has the same controller or external IP.

------------------------------------------------------------------------

## Demo 4: Test Ingress Using a Host Header

If the Ingress Controller is reachable through a node IP or local
endpoint, test with curl.

First inspect the Ingress:

``` bash
kubectl get ingress nginx-ingress -o wide
```

If an address is available:

``` bash
curl -H "Host: nginx.local" http://<INGRESS-ADDRESS>/
```

Example:

``` bash
curl -H "Host: nginx.local" http://192.168.1.20/
```

Expected output:

``` html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

### Why Is the Host Header Important?

The Ingress rule says:

``` yaml
host: nginx.local
```

Therefore, the request must contain:

``` http
Host: nginx.local
```

Without the correct Host header, the request may not match the rule.

------------------------------------------------------------------------

## Demo 5: Host-Based Routing

We will create two applications:

-   Application 1: app-one
-   Application 2: app-two

### Create App One

``` bash
kubectl create deployment app-one \
  --image=nginx:1.25
```

``` bash
kubectl expose deployment app-one \
  --name=app-one-service \
  --port=80
```

Create a custom page:

``` bash
kubectl run app-one-page \
  --image=busybox:1.36 \
  --restart=Never \
  -- sh -c 'echo "Welcome to Application ONE" > /tmp/index.html; sleep 3600'
```

For a simple and reliable demonstration, use separate NGINX images with
different response content by creating ConfigMaps.

Create ConfigMap for app one:

``` bash
kubectl create configmap app-one-html \
  --from-literal=index.html="Welcome to Application ONE"
```

Create ConfigMap for app two:

``` bash
kubectl create configmap app-two-html \
  --from-literal=index.html="Welcome to Application TWO"
```

Create app-one YAML:

``` bash
nano app-one.yaml
```

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-one
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-one
  template:
    metadata:
      labels:
        app: app-one
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports:
            - containerPort: 80
          volumeMounts:
            - name: html
              mountPath: /usr/share/nginx/html
      volumes:
        - name: html
          configMap:
            name: app-one-html
---
apiVersion: v1
kind: Service
metadata:
  name: app-one-service
spec:
  selector:
    app: app-one
  ports:
    - port: 80
      targetPort: 80
```

Apply:

``` bash
kubectl apply -f app-one.yaml
```

### Create App Two

``` bash
nano app-two.yaml
```

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-two
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-two
  template:
    metadata:
      labels:
        app: app-two
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports:
            - containerPort: 80
          volumeMounts:
            - name: html
              mountPath: /usr/share/nginx/html
      volumes:
        - name: html
          configMap:
            name: app-two-html
---
apiVersion: v1
kind: Service
metadata:
  name: app-two-service
spec:
  selector:
    app: app-two
  ports:
    - port: 80
      targetPort: 80
```

Apply:

``` bash
kubectl apply -f app-two.yaml
```

Check:

``` bash
kubectl get pods
kubectl get svc
```

### Create Host-Based Ingress

``` bash
nano host-ingress.yaml
```

``` yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-based-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: one.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-one-service
                port:
                  number: 80
    - host: two.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-two-service
                port:
                  number: 80
```

Apply:

``` bash
kubectl apply -f host-ingress.yaml
```

Test:

``` bash
curl -H "Host: one.example.com" http://<INGRESS-ADDRESS>/
```

Expected:

``` text
Welcome to Application ONE
```

Test the second application:

``` bash
curl -H "Host: two.example.com" http://<INGRESS-ADDRESS>/
```

Expected:

``` text
Welcome to Application TWO
```

### Main Learning Point

The IP address can be the same, but the Host header determines which
Service receives the request.

``` text
one.example.com  ---> app-one-service
two.example.com  ---> app-two-service
```

------------------------------------------------------------------------

## Demo 6: Path-Based Routing

Create:

``` bash
nano path-ingress.yaml
```

``` yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: shop.example.com
      http:
        paths:
          - path: /app1
            pathType: Prefix
            backend:
              service:
                name: app-one-service
                port:
                  number: 80
          - path: /app2
            pathType: Prefix
            backend:
              service:
                name: app-two-service
                port:
                  number: 80
```

Apply:

``` bash
kubectl apply -f path-ingress.yaml
```

Test:

``` bash
curl -H "Host: shop.example.com" http://<INGRESS-ADDRESS>/app1
```

``` bash
curl -H "Host: shop.example.com" http://<INGRESS-ADDRESS>/app2
```

### Important Note About Path Rewriting

The simple configuration above forwards the request path as received.
For example, `/app1` may be sent to the backend as `/app1`.

Some applications expect `/` instead. In that case, path rewriting may
be required, and the exact annotation depends on the Ingress Controller.

For NGINX Ingress Controller, a rewrite example is:

``` yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
```

Use rewrite annotations only when the backend application requires them.

------------------------------------------------------------------------

## Demo 7: Ingress with TLS/HTTPS

Ingress can terminate TLS.

Traffic flow:

``` text
Client --HTTPS--> Ingress Controller --HTTP--> Service --> Pod
```

Create a self-signed certificate for lab use:

``` bash
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=secure.example.com/O=training"
```

Create a TLS Secret:

``` bash
kubectl create secret tls secure-tls \
  --key tls.key \
  --cert tls.crt
```

Create Ingress:

``` bash
nano tls-ingress.yaml
```

``` yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - secure.example.com
      secretName: secure-tls
  rules:
    - host: secure.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-service
                port:
                  number: 80
```

Apply:

``` bash
kubectl apply -f tls-ingress.yaml
```

Test:

``` bash
curl -k -H "Host: secure.example.com" \
  https://<INGRESS-ADDRESS>/
```

`-k` allows curl to accept the self-signed certificate in this lab.

### Production TLS Notes

In production:

-   Use a trusted certificate.
-   Protect TLS private keys.
-   Consider cert-manager for certificate automation.
-   Configure HTTP-to-HTTPS redirects where required.
-   Monitor certificate expiry.

------------------------------------------------------------------------

## Ingress Troubleshooting Commands

``` bash
kubectl get ingress
```

``` bash
kubectl describe ingress <ingress-name>
```

``` bash
kubectl get ingressclass
```

``` bash
kubectl get svc
```

``` bash
kubectl get endpoints
```

``` bash
kubectl get endpointslices
```

``` bash
kubectl get pods -A | grep -i ingress
```

``` bash
kubectl logs -n ingress-nginx \
  deploy/ingress-nginx-controller
```

Common problems:

  Problem                  Possible reason
  ------------------------ ---------------------------------------------
  Ingress has no address   Controller not installed or not ready
  404 response             Host/path rule did not match
  502/503 response         Service has no ready endpoints
  TLS error                Wrong Secret, hostname, or certificate
  Connection refused       Controller Service or port is not reachable
  Default backend page     Request did not match an Ingress rule

------------------------------------------------------------------------

# Part 2: Network Policies --- Traffic Firewall

## 1. What Is a NetworkPolicy?

A NetworkPolicy is a Kubernetes resource used to control network traffic
to and from Pods.

It acts like a traffic firewall for Pods.

NetworkPolicy can control:

-   Ingress traffic: traffic coming into a Pod
-   Egress traffic: traffic leaving a Pod
-   Source Pods
-   Destination Pods
-   Namespaces
-   IP blocks
-   Ports and protocols

## 2. Simple NetworkPolicy Diagram

``` text
                 NetworkPolicy
                      |
          +-----------+-----------+
          |                       |
       Ingress                  Egress
   Incoming traffic         Outgoing traffic
          |                       |
          v                       v
       Pod A                    Pod A
```

Example:

``` text
Frontend Pod ---> Backend Pod
       allowed only on TCP 8080
```

If a policy blocks the traffic:

``` text
Frontend Pod -X-> Backend Pod
```

## 3. Important NetworkPolicy Concepts

### Pod Selector

Selects which Pods the policy applies to.

``` yaml
podSelector:
  matchLabels:
    app: backend
```

This policy applies to Pods labeled:

``` yaml
app: backend
```

### Ingress

Controls incoming connections to selected Pods.

``` yaml
policyTypes:
  - Ingress
```

### Egress

Controls outgoing connections from selected Pods.

``` yaml
policyTypes:
  - Egress
```

### Namespace Selector

Selects traffic from Pods in a namespace.

``` yaml
namespaceSelector:
  matchLabels:
    kubernetes.io/metadata.name: frontend
```

### Pod Selector

Selects Pods with specific labels.

``` yaml
podSelector:
  matchLabels:
    app: frontend
```

### Port

Restricts traffic to a port.

``` yaml
ports:
  - protocol: TCP
    port: 8080
```

------------------------------------------------------------------------

## 4. Critical Behavior: Default Allow vs Default Deny

By default, in many Kubernetes clusters, Pods can communicate freely
unless NetworkPolicies restrict them.

A NetworkPolicy does not automatically block all traffic just because it
exists.

### Default Deny Ingress

``` yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

Meaning:

-   Selects all Pods in the namespace.
-   Denies incoming traffic unless another policy allows it.

### Default Deny Egress

``` yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
spec:
  podSelector: {}
  policyTypes:
    - Egress
```

Meaning:

-   Selects all Pods in the namespace.
-   Denies outgoing traffic unless another policy allows it.

### Important

NetworkPolicy behavior depends on the network plugin/CNI. The cluster
must support NetworkPolicy enforcement.

Examples of CNIs that support NetworkPolicy include:

-   Calico
-   Cilium
-   Weave Net
-   Other compatible implementations

------------------------------------------------------------------------

## Demo 1: Create Frontend and Backend Pods

Create a frontend Deployment:

``` bash
kubectl create deployment frontend \
  --image=nginx:1.25
```

Create a backend Deployment:

``` bash
kubectl create deployment backend \
  --image=nginx:1.25
```

Expose backend:

``` bash
kubectl expose deployment backend \
  --name=backend-service \
  --port=80
```

Check:

``` bash
kubectl get pods --show-labels
```

Test backend from frontend:

``` bash
kubectl exec deploy/frontend -- \
  curl -s http://backend-service
```

Expected output contains:

``` html
Welcome to nginx!
```

### Explain

Currently:

``` text
frontend ---> backend-service ---> backend Pod
```

Traffic is allowed because no restrictive policy has been applied.

------------------------------------------------------------------------

## Demo 2: Default Deny Ingress

Create:

``` bash
nano deny-ingress.yaml
```

``` yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

Apply:

``` bash
kubectl apply -f deny-ingress.yaml
```

Check:

``` bash
kubectl get networkpolicy
```

Test from frontend:

``` bash
kubectl exec deploy/frontend -- \
  curl --connect-timeout 5 -sS http://backend-service
```

Expected behavior:

-   The request may time out or fail.
-   Exact output depends on the CNI and cluster configuration.

### Why?

The policy selects every Pod in the namespace:

``` yaml
podSelector: {}
```

It enables ingress isolation:

``` yaml
policyTypes:
  - Ingress
```

No ingress rule is specified, so incoming traffic is denied for selected
Pods.

------------------------------------------------------------------------

## Demo 3: Allow Frontend to Access Backend

Delete the deny policy first:

``` bash
kubectl delete networkpolicy deny-all-ingress
```

Create an allow policy:

``` bash
nano allow-frontend.yaml
```

``` yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 80
```

Apply:

``` bash
kubectl apply -f allow-frontend.yaml
```

Test:

``` bash
kubectl exec deploy/frontend -- \
  curl -s http://backend-service
```

Expected:

``` html
Welcome to nginx!
```

### Explain the Policy

``` yaml
podSelector:
  matchLabels:
    app: backend
```

The policy applies to backend Pods.

``` yaml
ingress:
  - from:
      - podSelector:
          matchLabels:
            app: frontend
```

Only traffic from Pods labeled `app: frontend` is allowed.

``` yaml
ports:
  - protocol: TCP
    port: 80
```

Only TCP port 80 is allowed.

### Important Scope Rule

A `podSelector` inside `from` selects Pods in the same namespace as the
NetworkPolicy.

To select Pods in another namespace, use `namespaceSelector`, or combine
namespace and pod selectors.

------------------------------------------------------------------------

## Demo 4: Test Traffic from an Unapproved Pod

Create a test Pod:

``` bash
kubectl run attacker \
  --image=curlimages/curl:8.10.1 \
  --restart=Never \
  -- sleep 3600
```

Check labels:

``` bash
kubectl get pod attacker --show-labels
```

Try accessing backend:

``` bash
kubectl exec attacker -- \
  curl --connect-timeout 5 -sS http://backend-service
```

Expected:

-   The request should fail or time out if the policy is enforced.
-   The frontend Pod should still be allowed.

Test frontend again:

``` bash
kubectl exec deploy/frontend -- \
  curl -s http://backend-service
```

Expected:

``` html
Welcome to nginx!
```

Clean up:

``` bash
kubectl delete pod attacker
```

------------------------------------------------------------------------

## Demo 5: Default Deny Egress

Create:

``` bash
nano deny-egress.yaml
```

``` yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
spec:
  podSelector: {}
  policyTypes:
    - Egress
```

Apply:

``` bash
kubectl apply -f deny-egress.yaml
```

Test DNS:

``` bash
kubectl exec deploy/frontend -- \
  nslookup backend-service
```

Test HTTP:

``` bash
kubectl exec deploy/frontend -- \
  curl --connect-timeout 5 -sS http://backend-service
```

Depending on the CNI and DNS configuration, DNS resolution and HTTP
traffic may fail.

### Important Production Consideration

If you deny all egress, Pods may lose access to:

-   Kubernetes DNS
-   External APIs
-   Package repositories
-   Cloud metadata endpoints
-   Databases
-   Monitoring systems

Therefore, egress policies should be designed carefully.

------------------------------------------------------------------------

## Demo 6: Allow DNS and Backend Egress

Delete the default egress policy:

``` bash
kubectl delete networkpolicy deny-all-egress
```

Create an egress policy for frontend:

``` bash
nano frontend-egress.yaml
```

``` yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: backend
      ports:
        - protocol: TCP
          port: 80
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

Apply:

``` bash
kubectl apply -f frontend-egress.yaml
```

### Note

The DNS rule assumes that the DNS Pods are in `kube-system` and have
compatible labels. A more precise production policy should select the
actual DNS Pods, often using labels such as:

``` yaml
k8s-app: kube-dns
```

Check actual labels:

``` bash
kubectl get pods -n kube-system --show-labels
```

Test:

``` bash
kubectl exec deploy/frontend -- \
  nslookup backend-service
```

``` bash
kubectl exec deploy/frontend -- \
  curl -s http://backend-service
```

------------------------------------------------------------------------

## Demo 7: Namespace-Based NetworkPolicy

Create another namespace:

``` bash
kubectl create namespace testing
```

Label it explicitly:

``` bash
kubectl label namespace testing purpose=testing
```

Create a Pod in the testing namespace:

``` bash
kubectl run testing-client \
  -n testing \
  --image=curlimages/curl:8.10.1 \
  --restart=Never \
  -- sleep 3600
```

A policy can allow traffic from that namespace:

``` yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-testing-namespace
  namespace: web-lab
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              purpose: testing
      ports:
        - protocol: TCP
          port: 80
```

Save as:

``` bash
nano namespace-policy.yaml
```

Apply:

``` bash
kubectl apply -f namespace-policy.yaml
```

Test from testing namespace:

``` bash
kubectl exec -n testing testing-client -- \
  curl -s http://backend-service.web-lab.svc.cluster.local
```

Expected:

``` html
Welcome to nginx!
```

Clean up:

``` bash
kubectl delete namespace testing
```

------------------------------------------------------------------------

## NetworkPolicy Rules to Remember

### Same Namespace Pod Selector

``` yaml
from:
  - podSelector:
      matchLabels:
        app: frontend
```

### Another Namespace Selector

``` yaml
from:
  - namespaceSelector:
      matchLabels:
        purpose: testing
```

### Namespace + Pod Selector Together

``` yaml
from:
  - namespaceSelector:
      matchLabels:
        purpose: testing
    podSelector:
      matchLabels:
        app: client
```

This means:

-   The source Pod must have `app: client`.
-   The source namespace must have `purpose: testing`.

### IP Block

``` yaml
from:
  - ipBlock:
      cidr: 10.0.0.0/8
```

Use IP blocks carefully because traffic may be seen with different
source IPs depending on the network implementation.

------------------------------------------------------------------------

## NetworkPolicy Troubleshooting

``` bash
kubectl get networkpolicy
```

``` bash
kubectl describe networkpolicy <policy-name>
```

``` bash
kubectl get pods --show-labels
```

``` bash
kubectl get namespaces --show-labels
```

``` bash
kubectl get pods -n kube-system --show-labels
```

Test DNS:

``` bash
kubectl exec deploy/frontend -- nslookup backend-service
```

Test connectivity:

``` bash
kubectl exec deploy/frontend -- \
  curl --connect-timeout 5 -v http://backend-service
```

Common problems:

  Problem                         Possible reason
  ------------------------------- ------------------------------------------------
  Policy has no effect            CNI does not enforce NetworkPolicy
  Allowed Pod is blocked          Label mismatch
  DNS fails                       Egress policy blocks DNS
  Cross-namespace traffic fails   Missing namespaceSelector
  Backend is unreachable          Service has no endpoints
  Policy seems too open           Another policy may allow the traffic
  Traffic still works             The policy does not select the destination Pod

### Very Important Rule

NetworkPolicies are additive.

If multiple policies select a Pod, the allowed traffic is the union of
the rules from those policies. Adding a restrictive policy does not
necessarily override an existing allow policy.

------------------------------------------------------------------------

# Part 3: Health Probes --- Application Reliability

## 1. What Are Health Probes?

Health probes are checks performed by the Kubernetes kubelet to
determine whether a container is healthy and ready.

Kubernetes supports three main probes:

1.  Liveness Probe
2.  Readiness Probe
3.  Startup Probe

------------------------------------------------------------------------

## 2. Liveness Probe

### Meaning

A liveness probe checks whether the application is still alive.

If the liveness probe repeatedly fails, Kubernetes may restart the
container.

### Example

``` yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
```

### Simple Explanation

``` text
Is the application still alive?
        |
       Yes ---> Keep running
        |
       No
        |
        v
Restart container
```

### Use Cases

-   Application deadlock
-   Application process stuck
-   Unresponsive application
-   Internal application failure

------------------------------------------------------------------------

## 3. Readiness Probe

### Meaning

A readiness probe checks whether a Pod is ready to receive traffic.

If readiness fails:

-   The Pod is marked NotReady.
-   The Pod is removed from normal Service endpoints.
-   The container is not necessarily restarted.

### Simple Explanation

``` text
Can this Pod receive traffic?
        |
       Yes ---> Service sends traffic
        |
       No
        |
        v
Service stops sending normal traffic
```

### Use Cases

-   Application is starting
-   Database connection is unavailable
-   Dependency is not ready
-   Application is overloaded
-   Temporary maintenance

------------------------------------------------------------------------

## 4. Startup Probe

### Meaning

A startup probe checks whether a slow-starting application has completed
startup.

While the startup probe is failing:

-   Liveness and readiness probes are held back.
-   Kubernetes waits for startup.
-   If startup does not succeed within the allowed time, the container
    may be restarted.

### Use Cases

-   Java applications
-   Large applications
-   Applications loading models
-   Applications with long initialization
-   Legacy applications

------------------------------------------------------------------------

## 5. Liveness vs Readiness vs Startup

  -----------------------------------------------------------------------
  Probe                   Main question           Failure action
  ----------------------- ----------------------- -----------------------
  Liveness                Is the application      Container may restart
                          alive?                  

  Readiness               Can the application     Pod removed from
                          receive traffic?        Service endpoints

  Startup                 Has the application     Prevents premature
                          started?                liveness/readiness
                                                  checks
  -----------------------------------------------------------------------

### Easy Memory Trick

-   **Liveness:** Restart me if I am stuck.
-   **Readiness:** Do not send traffic until I am ready.
-   **Startup:** Give me time to start.

------------------------------------------------------------------------

## 6. Types of Probe Checks

### HTTP GET

``` yaml
httpGet:
  path: /healthz
  port: 8080
```

Kubernetes sends an HTTP request.

Success usually requires an HTTP status code in the 200--399 range.

### TCP Socket

``` yaml
tcpSocket:
  port: 8080
```

Checks whether a TCP connection can be established.

### Exec

``` yaml
exec:
  command:
    - cat
    - /tmp/healthy
```

Runs a command inside the container.

Exit code `0` means success.

### gRPC

``` yaml
grpc:
  port: 9090
```

Used for gRPC health checking when supported by the application and
Kubernetes version.

------------------------------------------------------------------------

## Demo 1: Basic NGINX Readiness Probe

Create:

``` bash
nano readiness.yaml
```

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: readiness-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: readiness-demo
  template:
    metadata:
      labels:
        app: readiness-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 2
            periodSeconds: 5
            timeoutSeconds: 2
            failureThreshold: 3
            successThreshold: 1
---
apiVersion: v1
kind: Service
metadata:
  name: readiness-service
spec:
  selector:
    app: readiness-demo
  ports:
    - port: 80
      targetPort: 80
```

Apply:

``` bash
kubectl apply -f readiness.yaml
```

Check Pods:

``` bash
kubectl get pods
```

Check readiness:

``` bash
kubectl get pods -w
```

Expected:

``` text
NAME                              READY   STATUS    RESTARTS   AGE
readiness-demo-xxxxxxxxxx-xxxxx   1/1     Running   0          ...
readiness-demo-xxxxxxxxxx-yyyyy   1/1     Running   0          ...
```

Check Service endpoints:

``` bash
kubectl get endpoints readiness-service
```

Or:

``` bash
kubectl get endpointslices
```

### Explain

The readiness probe checks:

``` text
http://Pod-IP:80/
```

If NGINX returns a successful response, the Pod becomes Ready.

------------------------------------------------------------------------

## Demo 2: Readiness Failure

We will change the readiness path to a path that does not exist.

Edit the Deployment:

``` bash
kubectl edit deployment readiness-demo
```

Change:

``` yaml
path: /
```

to:

``` yaml
path: /wrong-health-check
```

Save and exit.

Watch Pods:

``` bash
kubectl get pods -w
```

Expected:

``` text
READY   STATUS
0/1     Running
```

The container is still running, but the Pod is not ready.

Check:

``` bash
kubectl describe pod <pod-name>
```

Look for:

``` text
Readiness probe failed
```

Check endpoints:

``` bash
kubectl get endpoints readiness-service
```

The failing Pod should not appear as a ready endpoint.

### Restore the Correct Path

``` bash
kubectl edit deployment readiness-demo
```

Change back to:

``` yaml
path: /
```

Watch:

``` bash
kubectl get pods -w
```

Expected:

``` text
1/1     Running
```

------------------------------------------------------------------------

## Demo 3: Liveness Probe Restart

Create a Pod with a liveness probe that checks a file.

``` bash
nano liveness.yaml
```

``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-demo
spec:
  containers:
    - name: app
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          touch /tmp/healthy
          sleep 30
          rm -f /tmp/healthy
          sleep 600
      livenessProbe:
        exec:
          command:
            - cat
            - /tmp/healthy
        initialDelaySeconds: 5
        periodSeconds: 5
        failureThreshold: 2
```

Apply:

``` bash
kubectl apply -f liveness.yaml
```

Watch:

``` bash
kubectl get pod liveness-demo -w
```

After approximately 30 seconds, the file is removed.

The liveness probe runs:

``` bash
cat /tmp/healthy
```

The command fails because the file no longer exists.

After the configured failures, Kubernetes restarts the container.

Check:

``` bash
kubectl get pod liveness-demo
```

Look at restart count:

``` bash
kubectl get pod liveness-demo \
  -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount
```

Describe:

``` bash
kubectl describe pod liveness-demo
```

Look for events such as:

``` text
Liveness probe failed
Killing container
```

### Explain

``` text
File exists
   |
   v
Probe succeeds
   |
   v
Container continues

File deleted
   |
   v
Probe fails repeatedly
   |
   v
Container restarted
```

------------------------------------------------------------------------

## Demo 4: Startup Probe

Create:

``` bash
nano startup.yaml
```

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: startup-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: startup-demo
  template:
    metadata:
      labels:
        app: startup-demo
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports:
            - containerPort: 80
          command:
            - sh
            - -c
            - |
              sleep 20
              nginx -g 'daemon off;'
          startupProbe:
            httpGet:
              path: /
              port: 80
            periodSeconds: 5
            failureThreshold: 10
          livenessProbe:
            httpGet:
              path: /
              port: 80
            periodSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /
              port: 80
            periodSeconds: 5
            failureThreshold: 3
```

Apply:

``` bash
kubectl apply -f startup.yaml
```

Watch:

``` bash
kubectl get pods -w
```

### What Happens?

1.  Container starts.
2.  Application waits 20 seconds.
3.  Startup probe initially fails.
4.  Liveness and readiness probes are not yet used for normal checking.
5.  NGINX starts.
6.  Startup probe succeeds.
7.  Readiness and liveness probes begin operating.

### Calculate Startup Time

The maximum startup probe window is approximately:

``` text
periodSeconds × failureThreshold
```

For this example:

``` text
5 × 10 = 50 seconds
```

This is a simplified planning calculation. Actual timing can vary due to
probe execution and startup behavior.

------------------------------------------------------------------------

## Demo 5: HTTP Health Endpoint Using NGINX

NGINX serves `/` by default. It does not automatically provide a custom
`/healthz` endpoint.

Create a ConfigMap containing a health page:

``` bash
kubectl create configmap health-page \
  --from-literal=healthz="healthy"
```

Create:

``` bash
nano nginx-health.yaml
```

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-health
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-health
  template:
    metadata:
      labels:
        app: nginx-health
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports:
            - containerPort: 80
          volumeMounts:
            - name: health
              mountPath: /usr/share/nginx/html/healthz
              subPath: healthz
          readinessProbe:
            httpGet:
              path: /healthz
              port: 80
            initialDelaySeconds: 2
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /healthz
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
      volumes:
        - name: health
          configMap:
            name: health-page
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-health-service
spec:
  selector:
    app: nginx-health
  ports:
    - port: 80
      targetPort: 80
```

Apply:

``` bash
kubectl apply -f nginx-health.yaml
```

Test:

``` bash
kubectl run health-client \
  --image=curlimages/curl:8.10.1 \
  --rm -it \
  --restart=Never \
  -- curl http://nginx-health-service/healthz
```

Expected:

``` text
healthy
```

### Simulate Health Failure

Delete the ConfigMap:

``` bash
kubectl delete configmap health-page
```

Existing mounted ConfigMap content may remain available depending on how
it is mounted and updated. For a predictable failure demonstration, edit
the Deployment to use a wrong path or remove the health file from a
writable test container.

A simple method is to change the probe path:

``` bash
kubectl edit deployment nginx-health
```

Change:

``` yaml
path: /healthz
```

to:

``` yaml
path: /bad-healthz
```

Watch:

``` bash
kubectl get pods -w
```

The Pods should become NotReady. If the liveness probe also uses the
wrong path, the containers may restart.

------------------------------------------------------------------------

## Probe Configuration Fields

### initialDelaySeconds

How many seconds Kubernetes waits before starting the probe.

``` yaml
initialDelaySeconds: 10
```

### periodSeconds

How often the probe runs.

``` yaml
periodSeconds: 5
```

### timeoutSeconds

How long Kubernetes waits for a probe response.

``` yaml
timeoutSeconds: 2
```

### failureThreshold

How many consecutive failures are needed before the probe is considered
failed.

``` yaml
failureThreshold: 3
```

### successThreshold

How many consecutive successes are needed to mark a probe successful.

``` yaml
successThreshold: 1
```

For liveness and startup probes, `successThreshold` must be 1.

------------------------------------------------------------------------

## Common Probe Mistakes

### Mistake 1: Wrong Port

Container listens on 8080:

``` yaml
ports:
  - containerPort: 8080
```

But probe checks 80:

``` yaml
httpGet:
  path: /
  port: 80
```

Result: Probe fails.

### Mistake 2: Wrong Path

Application provides:

``` text
/health
```

But probe checks:

``` text
/healthz
```

Result: Probe may fail.

### Mistake 3: Liveness Checks a Dependency

Bad design:

``` text
Liveness checks database connectivity.
Database is temporarily unavailable.
Application is restarted repeatedly.
```

Better:

-   Liveness checks whether the application process is functioning.
-   Readiness checks whether the application can serve traffic.
-   Dependency checks should be designed carefully.

### Mistake 4: No Startup Probe for Slow Applications

A slow application may be restarted before it finishes starting.

Use a startup probe to provide enough startup time.

### Mistake 5: Probe Is Too Aggressive

Very short timeouts and low failure thresholds may cause false failures.

Tune probes based on real application behavior.

------------------------------------------------------------------------

# Combined Real-World Architecture

The three topics work together.

``` text
                         Internet User
                              |
                              | HTTPS
                              v
                     Ingress Controller
                              |
                              v
                       Frontend Service
                              |
                              v
                       Frontend Pods
                              |
                     NetworkPolicy
                              |
                              v
                       Backend Service
                              |
                              v
                       Backend Pods
                              |
                   Readiness / Liveness
                   /        |        \
                  /         |         \
             Healthy     Unhealthy   Starting
                |            |           |
           Receive       Restart or   Startup probe
            traffic      remove       protects startup
```

## Example Production Flow

1.  User sends an HTTPS request.
2.  Ingress Controller receives the request.
3.  Ingress routes the request to a Service.
4.  Service sends traffic only to ready Pods.
5.  NetworkPolicy allows only approved traffic.
6.  Readiness probe removes unhealthy Pods from traffic.
7.  Liveness probe restarts stuck containers.
8.  Startup probe protects slow-starting applications.

------------------------------------------------------------------------

# Full Combined Demo

## Step 1: Create Namespace

``` bash
kubectl create namespace production-demo
```

## Step 2: Create Application

``` bash
kubectl create deployment production-nginx \
  -n production-demo \
  --image=nginx:1.25 \
  --replicas=2
```

## Step 3: Expose Service

``` bash
kubectl expose deployment production-nginx \
  -n production-demo \
  --name=production-service \
  --port=80
```

## Step 4: Add Readiness and Liveness

``` bash
kubectl edit deployment production-nginx -n production-demo
```

Add under the container:

``` yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 2
  periodSeconds: 5

livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 10
```

## Step 5: Create Ingress

``` bash
nano production-ingress.yaml
```

``` yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: production-ingress
  namespace: production-demo
spec:
  ingressClassName: nginx
  rules:
    - host: production.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: production-service
                port:
                  number: 80
```

Apply:

``` bash
kubectl apply -f production-ingress.yaml
```

## Step 6: Add NetworkPolicy

``` bash
nano production-policy.yaml
```

``` yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: production-ingress-policy
  namespace: production-demo
spec:
  podSelector:
    matchLabels:
      app: production-nginx
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 80
```

Apply:

``` bash
kubectl apply -f production-policy.yaml
```

### Explanation

This policy allows TCP port 80 traffic from Pods in any namespace.

It does not automatically allow external traffic unless the cluster's
networking path presents that traffic as matching the policy.

In real production environments, verify the source identity and CNI
behavior before relying on this exact rule.

## Step 7: Verify Everything

``` bash
kubectl get all -n production-demo
```

``` bash
kubectl get ingress -n production-demo
```

``` bash
kubectl get networkpolicy -n production-demo
```

``` bash
kubectl describe deployment production-nginx -n production-demo
```

``` bash
kubectl describe pod -n production-demo <pod-name>
```

``` bash
kubectl get endpoints -n production-demo
```

------------------------------------------------------------------------

# Student Practice Activities

## Activity 1: Ingress

1.  Create two Deployments named `blue-app` and `green-app`.
2.  Expose both using ClusterIP Services.
3.  Create host-based Ingress rules:
    -   `blue.example.com`
    -   `green.example.com`
4.  Test both using curl and the Host header.
5.  Add a path-based rule:
    -   `/blue`
    -   `/green`
6.  Explain the difference between host-based and path-based routing.
7.  Add TLS using a Kubernetes TLS Secret.

## Activity 2: NetworkPolicy

1.  Create Pods named `frontend`, `backend`, and `database`.
2.  Allow frontend to access backend on port 8080.
3.  Deny all other ingress traffic to backend.
4.  Allow backend to access database on port 5432.
5.  Block frontend from accessing database directly.
6.  Create a default-deny egress policy.
7.  Allow DNS traffic.
8.  Test every allowed and denied connection.
9.  Use `kubectl describe networkpolicy` to explain the rules.

## Activity 3: Health Probes

1.  Deploy NGINX with a readiness probe.
2.  Change the readiness path to an invalid path.
3.  Observe the Ready column.
4.  Check Service endpoints.
5.  Create a liveness probe using an `exec` command.
6.  Make the command fail.
7.  Observe the restart count.
8.  Create a slow-starting application.
9.  Add a startup probe.
10. Explain why startup probes prevent premature restarts.

------------------------------------------------------------------------

# Interview Questions

## Ingress Questions

1.  What is Ingress in Kubernetes?
2.  What is the difference between Ingress and Ingress Controller?
3.  Can Ingress route TCP traffic?
4.  What is host-based routing?
5.  What is path-based routing?
6.  How do you configure TLS in Ingress?
7.  What happens if no Ingress Controller is installed?
8.  How do you troubleshoot a 404 from Ingress?
9.  What is the role of `ingressClassName`?
10. What is the difference between Ingress and LoadBalancer Service?

## NetworkPolicy Questions

1.  What is NetworkPolicy?
2.  What is the difference between ingress and egress?
3.  What does `podSelector: {}` mean?
4.  What is default-deny ingress?
5.  What is default-deny egress?
6.  What is the difference between `podSelector` and
    `namespaceSelector`?
7.  Are NetworkPolicies supported by every network plugin?
8.  Are NetworkPolicies additive or overriding?
9.  How can you allow DNS while denying other egress?
10. How do you troubleshoot a NetworkPolicy that is not working?

## Health Probe Questions

1.  What is a liveness probe?
2.  What is a readiness probe?
3.  What is a startup probe?
4.  What happens when readiness fails?
5.  What happens when liveness fails?
6.  Why do we need startup probes?
7.  What are the types of probes?
8.  What is `initialDelaySeconds`?
9.  What is `failureThreshold`?
10. What is the difference between a readiness failure and a liveness
    failure?

------------------------------------------------------------------------

# Quick Revision

## Ingress

``` text
External HTTP/HTTPS traffic
          |
          v
Ingress Controller
          |
          v
Service
          |
          v
Pods
```

**Purpose:** Route HTTP/HTTPS traffic.

## NetworkPolicy

``` text
Pod A ---- allowed/blocked ----> Pod B
```

**Purpose:** Control Pod network traffic.

## Health Probes

``` text
Liveness  = Should I restart?
Readiness = Should I receive traffic?
Startup   = Have I started yet?
```

------------------------------------------------------------------------

# Cleanup Commands

Delete the lab namespace:

``` bash
kubectl delete namespace web-lab
```

Delete the testing namespace if it still exists:

``` bash
kubectl delete namespace testing
```

Delete the production demo:

``` bash
kubectl delete namespace production-demo
```

Check remaining resources:

``` bash
kubectl get all -A
```

------------------------------------------------------------------------

# Trainer Notes

## Recommended Teaching Order

1.  Explain Pods and Deployments briefly.
2.  Explain Services before Ingress.
3.  Demonstrate internal Service connectivity.
4.  Introduce Ingress and test host routing.
5.  Explain NetworkPolicy using a frontend/backend example.
6.  Demonstrate default deny and allow rules.
7.  Explain readiness before liveness.
8.  Demonstrate a readiness failure.
9.  Demonstrate a liveness restart.
10. Finish with the combined architecture.

## Important Killercoda Notes

-   Commands may vary between Killercoda scenarios.
-   Some scenarios already have an Ingress Controller.
-   Some scenarios do not support external LoadBalancer IPs.
-   NetworkPolicy enforcement depends on the installed CNI.
-   Use `kubectl get pods -A` to discover the environment.
-   Use internal curl Pods to test Services and NetworkPolicies.
-   For Ingress, use the controller's available IP, port, or
    scenario-specific access method.
-   Never assume that `localhost`, a node IP, or an Ingress address is
    identical across playgrounds.

## Final Student Understanding

After completing this lab, students should be able to explain:

-   How external HTTP/HTTPS traffic reaches Kubernetes Pods.
-   How Ingress routes requests using host and path rules.
-   How NetworkPolicies act as Pod-level traffic firewalls.
-   How to allow only specific application-to-application traffic.
-   How readiness controls traffic routing.
-   How liveness triggers container restarts.
-   How startup probes protect slow-starting applications.
-   How these features work together in a production-style Kubernetes
    application.
