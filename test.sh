#!/bin/bash

# Get invoice-app NodePort access
minikube service invoice-app --url

# Export invoice-app NodePort URL.
export INVOICE_APP_URL=$(minikube service invoice-app --url)
echo "Get invoice-app NodePort URL"
echo $INVOICE_APP_URL

# check invoices status
echo "Checking current status of bills..."
curl $INVOICE_APP_URL/invoices

# pay
echo "Paying bills..."
curl -d '{"InvoiceId":"I1", "Value":"12.15", "Currency":"EUR"}' -H "Content-Type: application/json" -X POST $INVOICE_APP_URL/invoices/pay

# check invoices status
echo "Checking current status of bills..."
curl $INVOICE_APP_URL/invoices
