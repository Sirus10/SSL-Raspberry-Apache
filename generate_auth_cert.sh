#!/bin/bash
#
# This script aim at creating Certificate for web server providing SSL/HTTPS services
# Main sources  : http://domotique.web2diz.net
# Other sources : http://goo.gl/lJJApr / https://goo.gl/srvnsK
#

echo "############################################################################################"
echo "I - Creation d'une autorite de certification"
echo "############################################################################################"

#############################################################################
openssl genrsa -des3 -out ca.key 2048 -sha512 
openssl req -new -key ./ca.key -out ./ca.csr
openssl x509 -req -days 3650 -in ./ca.csr -out ./ca.crt -signkey ./ca.key -sha512
openssl x509 -in ca.crt -text
openssl rsa -in ca.key -pubout -out ca.public.key
#############################################################################

echo "############################################################################################"
echo "II - Creation du certificat serveur et signature par l'autorite de certification "
echo "############################################################################################"

#############################################################################
openssl genrsa -des3 -out server.key 2048
openssl req  -new -key ./server.key -out server.csr -sha512
openssl x509 -req  -in ./server.csr -CA ./ca.crt -CAkey ./ca.key -CAcreateserial -out ./server.crt -days 3650 -sha512
openssl pkcs12 -export -in server.crt -inkey server.key -out server.p12 -name "Server certificate"
openssl pkcs12 -info -in server.p12
openssl rsa -in server.key -pubout -out server.public.key
openssl rsa -in server.key -out server.nopassphrase.key
#############################################################################

echo "############################################################################################"
echo "III  Client Cert generation"
echo "############################################################################################"

#############################################################################
openssl genrsa -des3 -out client.key 2048
openssl req -new -key ./client.key -out client.csr  -sha512
openssl x509 -req -in ./client.csr -CA ./ca.crt -CAkey ./ca.key -CAcreateserial -out ./client.crt -days 3650  -sha512
openssl pkcs12 -export -in client.crt -inkey client.key -out client.p12 -name "Client certificate"
openssl pkcs12 -info -in client.p12
openssl rsa -in client.key -pubout -out client.public.key
#############################################################################

echo "############################################################################################" 
echo "IV passwd file "
echo "############################################################################################"

# export the certificates in fake auth format
# see http://serverfault.com/questions/533639/apache-authentication-with-ssl-certificate-and-sslusername
# WF 2016-01-06
# http://serverfault.com/questions/577835/apache-ssl-certificate-and-basic-auth-combination-password-if-no-certificate
# http://httpd.apache.org/docs/trunk/ssl/ssl_howto.html#certauthenticate 

echo "Ajouter les entrees suivantes dans le fichier .htpasswd : "

fakepass=`openssl passwd -crypt -salt xx password`
for c in *.crt 
do
  openssl x509 -in $c -text  | grep Subject: | awk -v fakepass=$fakepass '
BEGIN { FS="," }
{ 
  gsub("Subject: ","",$0)
  for (i=1;i<=NF;i++) {
    f=trim($i)
    printf("/%s",f);
  }
  printf(":%s\n",fakepass);
}

# see https://gist.github.com/andrewrcollins/1592991
function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }
'
done
