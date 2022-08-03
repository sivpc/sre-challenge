#!/bin/bash

# before run this test, you need to install jq tool
# Linux => sudo apt install jq, sudo dnf install jq
# Mac   => brew install jq

# exporting invoice-app-url
echo "exporting invoice-app-url..."
export INVOICE_APP_URL=$(minikube service invoice-app --url)
echo $INVOICE_APP_URL
echo -e '\n'

# save invoices in to file
echo "saving invoices in to file..."
curl $INVOICE_APP_URL/invoices > invoice.json
echo -e '\n'

# check invoices status
printf "Before Paid - Current status of invoices...\n"
curl $INVOICE_APP_URL/invoices
echo -e '\n'

# Get the total number of invoices
size=$(jq length invoice.json)
printf "Total number of invoices - %s" "$size"

# Pay the invoice for all the unpaid ones
printf "\nPaying the invoice for all the unpaid ones..."

for (( c=0; c<size; c++ ))
do
   echo -e '\n'
   result=$( echo $c+1 | bc )

   printf "\n### Invoice - %s" "$result"

   InvoiceId=$(jq '.['$c'].InvoiceId' invoice.json)
   Value=$(jq '.['$c'].Value' invoice.json)
   Currency=$(jq '.['$c'].Currency' invoice.json)
   IsPaid=$(jq '.['$c'].IsPaid' invoice.json)

   printf "\nIsPaid =  %s" "$IsPaid"

   echo -e '\n'
   if [ "$IsPaid" = "false" ]; then
       echo "Paying Invoice" $result "bill..."
       curl -d '{"InvoiceId":"'+$InvoiceId+'", "Value":"'+Value+'", "Currency":"'+Currency+'"}' -H "Content-Type: application/json" -X POST $INVOICE_APP_URL/invoices/pay
   else
       echo "Invoice "$result" has already been paid!"
   fi
done
echo -e '\n'

# check invoices status
echo "After Paid - Current status of invoices..."
curl $INVOICE_APP_URL/invoices

echo -e '\n'
echo "Test complete!"
echo -e '\n'
