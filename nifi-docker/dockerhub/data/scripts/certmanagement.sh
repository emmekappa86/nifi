#!/bin/bash

if [ "$#" -lt 1 ]; then
	echo "Illegal number of parameters"
else

	echo "Checking $1..."

	if [ $1 == "export" ]; then

		echo "Exporting SiSMAP root certificate..."
		cp /opt/nifi/nifi-current/conf/sismap_certs/CA/sismap_ca_cert.pem /home/sismap/certs
	
	elif [[ $1 == "generate" && "$#" -eq 4 ]]; then
	
		echo "Creating and signing $2_cert.pem..."
		
		args=$(eval echo "$4")
		
		cd /opt/nifi/nifi-current/conf/sismap_certs/CA
		:
		
		openssl genpkey -algorithm RSA -out new_certs/"$2"_key.pem -aes256 -pass pass:"$3"
		openssl req -new -key new_certs/"$2"_key.pem -out new_certs/"$2"_req.csr -passin pass:"$3" -subj "$args"
		openssl x509 -req -in new_certs/"$2"_req.csr -out new_certs/"$2"_cert.pem -CA sismap_ca_cert.pem -CAkey sismap_ca_key.pem -CAcreateserial -days 365 -passin pass:"$ROOTCERT_PASSWORD"
		
		cat new_certs/"$2"_key.pem new_certs/"$2"_cert.pem | openssl pkcs12 -export -out new_certs/"$2"_cert.p12 -passin pass:"$3" -password pass:"$3"
	
		cp new_certs/"$2"_key.pem new_certs/"$2"_cert.pem new_certs/"$2"_cert.p12 /home/sismap/certs
	
	elif [[ $1 == "import" && "$#" -eq 3 ]]; then
	
		echo "Importing PEM certificate in the trustore..."
		
		keytool -import -trustcacerts -alias $3 -file /home/sismap/certs/$2 -keystore /opt/nifi/nifi-current/conf/sismap_certs/sismap_truststore.p12 -storepass "$TRUSTSTORE_PASSWORD" -noprompt
		
	else 
	
		echo "Invalid command or number of arguments"

	fi
	
fi

