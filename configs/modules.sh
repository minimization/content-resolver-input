for filename in sst_cs_infra_services-varnish sst_cs_apps-java-ant sst_cs_apps-perl-5.30 sst_cs_infra_services-subversion sst_cs_infra_services-nginx sst_cs_apps-perl-5.32 sst_java-jmc sst_cs_apps-java-maven stream-httpd
do

mv $filename-c9s.yaml $filename.yaml

done
