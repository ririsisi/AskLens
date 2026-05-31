ARG ES_BASE_IMAGE=docker.elastic.co/elasticsearch/elasticsearch:8.15.3
FROM ${ES_BASE_IMAGE}

RUN bin/elasticsearch-plugin install --batch https://get.infini.cloud/elasticsearch/analysis-ik/8.15.3
