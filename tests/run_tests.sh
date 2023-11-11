#!/bin/bash

echo Building action container...
docker build -t rebuild-cache-sitemap-testing ../

echo Starting test HTTP server...
docker run --name testing-nginx -d -p 8080:80 -v "$(pwd)/html:/usr/share/nginx/html" nginx

sleep 1

echo Running tests now...

function run_test {
  INPUT="$1"
  cat /dev/null > ./output
  docker run --env $INPUT --env GITHUB_OUTPUT=/output -t --add-host example.com:host-gateway -v "$(pwd)/output:/output"  rebuild-cache-sitemap-testing
  cat ./output
}

function check_result {
  expected_sitemapscount=$1
  expected_urlscount=$2

  set -o allexport
  source ./output
  set +o allexport

  if [[ "$sitemapscount" -eq "$expected_sitemapscount" ]] && \
     [[ "$urlscount" -eq "$expected_urlscount" ]]; then
    echo "Text successful."
  else
    echo "Values do not match the expected values:"
    echo "sitemapscount - expected: $expected_sitemapscount, actual: $sitemapscount"
    echo "urlscount - expected: $expected_urlscount, actual: $urlscount"
    exit 1
  fi
}

run_test INPUT_ROBOTS_URL_PREFIX="http://example.com:8080"              && check_result 4 9
run_test INPUT_SITEMAP_URL="http://example.com:8080/sitemap_index.xml"  && check_result 3 7
run_test INPUT_SITEMAP_URL="http://example.com:8080/sitemap.xml"        && check_result 1 2


docker stop testing-nginx
docker rm testing-nginx
