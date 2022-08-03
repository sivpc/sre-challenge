## Welcome

We're really happy that you're considering joining us!
This challenge will help us understand your skills and will also be a starting point for the next interview.
We're not expecting everything to be done perfectly as we value your time but the more you share with us, the more we get to know about you!

This challenge is split into 3 parts:

1. Debugging
2. Implementation
3. Questions

If you find possible improvements to be done to this challenge please let us know in this readme and/or during the interview.

## The challenge

Pleo runs most of its infrastructure in Kubernetes.
It's a bunch of microservices talking to each other and performing various tasks like verifying card transactions, moving money around, paying invoices, etc.
This challenge is similar but (a lot) smaller :D

In this repo, we provide you with:

- `invoice-app/`: An application that gets invoices from a DB, along with its minimal `deployment.yaml`
- `payment-provider/`: An application that pays invoices, along with its minimal `deployment.yaml`
- `Makefile`: A file to organize commands.
- `deploy.sh`: A file to script your solution
- `test.sh`: A file to perform tests against your solution.

### Set up the challenge env

1. Fork this repository
2. Create a new branch for you to work with.
3. Install any local K8s cluster (ex: Minikube) on your machine and document your setup so we can run your solution.

### Part 1 - Fix the issue

The setup we provide has a :bug:. Find it and fix it! You'll know you have fixed it when the state of the pods in the namespace looks similar to this:

```
NAME                                READY   STATUS                       RESTARTS   AGE
invoice-app-jklmno6789-44cd1        1/1     Ready                        0          10m
invoice-app-jklmno6789-67cd5        1/1     Ready                        0          10m
invoice-app-jklmno6789-12cd3        1/1     Ready                        0          10m
payment-provider-abcdef1234-23b21   1/1     Ready                        0          10m
payment-provider-abcdef1234-11b28   1/1     Ready                        0          10m
payment-provider-abcdef1234-1ab25   1/1     Ready                        0          10m
```

#### Requirements

Write here about the :bug:, the fix, how you found it, and anything else you want to share.

##### The :bug:
container (deployment.yaml) has runAsNonRoot and image will run as root (Dockerfile)

##### The fix
Create NonRoot user in image (Dockerfile) and in the deployment runAs that user

##### how you found it
Step 1: kubectl get pods -> pod status in CreateContainerConfigError <br />
Step 2: kubectl describe pod xxx-xxx -> it shows the error (container has runAsNonRoot and image will run as root)


### Part 2 - Setup the apps

We would like these 2 apps, `invoice-app` and `payment-provider`, to run in a K8s cluster and this is where you come in!

#### Requirements

1. `invoice-app` must be reachable from outside the cluster.
   * Create a NordPort service for the invoice-app is fulfill above requirement
2. `payment-provider` must be only reachable from inside the cluster.
   * Create a ClusterIP service for the payment-provider is fulfill above requirement
3. Update existing `deployment.yaml` files to follow k8s best practices. Feel free to remove existing files, recreate them, and/or introduce different technologies. Follow best practices for any other resources you decide to create.

   *  invoice-app deployment.yaml 

   ``` yaml	
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: invoice-app
      spec:
        replicas: 3
        selector:
          matchLabels:
            app: invoice-app
        template:
          metadata:
            labels:
              app: invoice-app
          spec:
            containers:
            - name: main
              image: invoice-app:latest
              imagePullPolicy: IfNotPresent
              envFrom:
              - configMapRef:
                  name: invoice-app-config
            securityContext:     
              runAsNonRoot: true
              runAsUser: 1001
      ---
      apiVersion: v1
      kind: Service
      metadata:
        name: invoice-app
        labels:
          app: invoice-app
      spec:
        type: NodePort
        selector:
          app: invoice-app
        ports:
          - protocol: TCP
            name: http
            port: 8081
            targetPort: 8081
    
   ```
       

   * payment-provider deployment.yaml

     ``` yaml
       apiVersion: apps/v1
       kind: Deployment
       metadata:
         name: payment-provider
       spec:
         replicas: 3
         selector:
           matchLabels:
             app: payment-provider
         template:
           metadata:
             labels:
               app: payment-provider
           spec:
             containers:
             - name: main
               image: payment-provider:latest
               imagePullPolicy: IfNotPresent
             securityContext:
               runAsNonRoot: true
               runAsUser: 1001
       ---
       apiVersion: v1
       kind: Service
       metadata:
         name: payment-provider
         labels:
           app: payment-provider
       spec:
         type: ClusterIP
         selector:
           app: payment-provider
         ports:
           - protocol: TCP
             name: http
             port: 8082
             targetPort: 8082

     ```


3. Provide a better way to pass the URL in `invoice-app/main.go` - it's hardcoded at the moment
   * Create a configmap and use that in deployment

     * configmap.yaml

        ``` yaml
           apiVersion: v1
           kind: ConfigMap
           metadata:
             name: invoice-app-config
           data:
             URL: http://payment-provider:8082/payments/pay
        ```

     * Use that in deployment.yaml

       ``` yaml
         spec:
           containers:
           - name: main
             image: invoice-app:latest
             imagePullPolicy: IfNotPresent
             envFrom:
             - configMapRef:
                 name: invoice-app-config
       ```
       
4. Complete `deploy.sh` in order to automate all the steps needed to have both apps running in a K8s cluster.

   ```shell
    #!/bin/bash
    
    # Start minikube
    minikube start
    
    # invoice-app
    # Build image
    cd invoice-app \
    && docker build -t invoice-app -f Dockerfile .
    
    # From host, push the Docker image directly to minikube
    minikube image load invoice-app:latest
    
    # Apply configmap
    kubectl apply -f configmap.yaml
    
    # Deploy
    kubectl apply -f deployment.yaml
    
    # payment-provider
    # Build image
    cd ../payment-provider \
    && docker build -t payment-provider -f Dockerfile .
    
    # From host, push the Docker image directly to minikube
    minikube image load payment-provider:latest
    
    # Deploy deployment
    kubectl apply -f deployment.yaml
    
    # Check that it's running
    kubectl get pods

   ```

5. Complete `test.sh` so we can validate your solution can successfully pay all the unpaid invoices and return a list of all the paid invoices.

   ```shell
    #!/bin/bash
    
    # before run this test, you need to install jq tool
    # Linux => sudo apt install jq, sudo dnf install jq
    # Mac   => brew install jq
    
    # exporting invoice-app-url
    export INVOICE_APP_URL=$(minikube service invoice-app --url)
    echo $INVOICE_APP_URL
    
    # save invoices in to file
    curl $INVOICE_APP_URL/invoices > invoice.json
    
    # check invoices status
    echo "Before Paid - Current status of invoices..."
    curl $INVOICE_APP_URL/invoices
    
    # Get the total number of invoices
    size=$(jq length invoice.json)
    
    # Pay the invoice for all the unpaid ones
    for (( c=0; c<size; c++ ))
    do
        result=$( echo $c+1 | bc )
        InvoiceId=$(jq '.['$c'].InvoiceId' invoice.json)
        Value=$(jq '.['$c'].Value' invoice.json)
        Currency=$(jq '.['$c'].Currency' invoice.json)
        IsPaid=$(jq '.['$c'].IsPaid' invoice.json)
        if [ "$IsPaid" = "false" ]; then
          echo "Paying Invoice" $result "bill..."
          curl -d '{"InvoiceId":"'+$InvoiceId+'", "Value":"'+Value+'", "Currency":"'+Currency+'"}' -H "Content-Type: application/json" -X POST $INVOICE_APP_URL/invoices/pay
        else
          echo "Invoice "$result" has already been paid!"
        fi
    done
    
    # check invoices status
    echo "After Paid - Current status of invoices..."
    curl $INVOICE_APP_URL/invoices

    echo "Test complete!"

   ```

### Part 3 - Questions

Feel free to express your thoughts and share your experiences with real-world examples you worked with in the past.

#### Requirements

1. What would you do to improve this setup and make it "production ready"?
2. There are 2 microservices that are maintained by 2 different teams. Each team should have access only to their service inside the cluster. How would you approach this?
3. How would you prevent other services running in the cluster to communicate to `payment-provider`?

## What matters to us?

We expect the solution to run but we also want to know how you work and what matters to you as an engineer.
Feel free to use any technology you want! You can create new files, refactor, rename, etc.

Ideally, we'd like to see your progression through commits, verbosity in your answers and all requirements met.
Don't forget to update the README.md to explain your thought process.
