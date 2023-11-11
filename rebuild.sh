#!/bin/bash -l

function process_url {
  url="$1"

  if [[ $url == *sitemaps.org* || $url == *w3.org* || $url == *google.com* ]]; then
    return
  fi

  echo Grabbing $url ...
  start_time=$(date +%s.%N)

  time $BROWSER_INIT "$url" || echo ""
  echo ""

  end_time=$(date +%s.%N)

  # Calculate how long the request took
  elapsed=$(echo "$end_time - $start_time" | bc)

  # Sleep to maintain the rate of 3 requests per second
  sleep_time=$(echo "scale=4; $RATE - $elapsed" | bc)

  # Ensure sleep time is not negative
  if (( $(echo "$sleep_time > 0" | bc -l) )); then
    sleep $sleep_time
  fi

  let "urlscount=urlscount+1"
}

# Check if domain is provided as environment variable
if [[ -n "${INPUT_SITEMAP_URL}" ]]; then

  curl -sfL $INPUT_SITEMAP_URL > /dev/null
  if [ $? -ne 0 ]; then
    echo "Root sitemap URL returned HTTP error!"
    exit 1
  fi
  SITEMAP_URLS+=("$INPUT_SITEMAP_URL")

elif [[ -n "${INPUT_ROBOTS_URL_PREFIX}" ]]; then
  SITEMAP_URLS=($(curl -sfL "${INPUT_ROBOTS_URL_PREFIX}/robots.txt" | grep -o '^Sitemap:[[:space:]]*.*' | awk '{print $2}'))
  if [ $? -ne 0 ]; then
    echo "robots.txt was not found under ${INPUT_ROBOTS_URL_PREFIX}!"
    exit 1
  fi
else
  echo You have to provide at least one of: sitemap_url, robots_url_prefix
  exit 1
fi

if [[ -n "${INPUT_USE_WGET}" && ( "${INPUT_USE_WGET}" == "1" || "${INPUT_USE_WGET}" == "on" || "${INPUT_USE_WGET}" == "true" || "${INPUT_USE_WGET}" == "TRUE" ) ]]; then
  BROWSER_INIT="wget -recursive --level=1 --page-requisites -e robots=off -q"
else
  BROWSER_INIT="curl -sL -o /dev/null"
fi

if [[ -n "${INPUT_RATE_LIMITATION}" ]]; then
  parsed_integer=$(expr "$INPUT_RATE_LIMITATION" + 0)
  if [ "$parsed_integer" -gt 0 ]; then
    RATE=$(echo "scale=4; 1 / $parsed_integer" | bc)
  else
    echo "RATE_LIMITATION has an invalid value: $INPUT_RATE_LIMITATION"
    exit 1
  fi
else
  RATE=0.25
fi

new_sitemaps=()
for SITEMAP_FILE in "${SITEMAP_URLS[@]}"; do
  sitemap_content=$(curl -sL "$SITEMAP_FILE")
  more_sitemaps=($(echo "$sitemap_content" | grep -oE "https?://[^[:space:]]+\.xml"))

  new_sitemaps+=("${more_sitemaps[@]}")
done
SITEMAP_URLS+=("${new_sitemaps[@]}")

echo Will process sitemaps:
for url in "${SITEMAP_URLS[@]}"; do
  echo $url
done


# Initialize counts
sitemapscount="${#SITEMAP_URLS[@]}"
urlscount=0

TIMEFORMAT="%Es"

for SITEMAP_FILE in "${SITEMAP_URLS[@]}"; do
  echo "Processing URLs in $SITEMAP_FILE ..."

  sitemap_content=$(curl -sfL "${SITEMAP_FILE}")
  if [ $? -ne 0 ]; then
    echo "Sitemap URL returned HTTP error code!"
    continue
  fi
  echo ""

  # Extract URLs from the sitemap
  urls=$(echo "$sitemap_content" | grep -oE 'http[s]?://[^<]+')

  for url in $urls; do
    process_url "$url"
  done
done

echo "Completed processing sitemaps."

echo "sitemapscount=$sitemapscount" >> "$GITHUB_OUTPUT"
echo "urlscount=$urlscount" >> "$GITHUB_OUTPUT"
echo "sitemap_urls=\"${SITEMAP_URLS[@]}\"" >> "$GITHUB_OUTPUT"

echo $GITHUB_OUTPUT
