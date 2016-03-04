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
