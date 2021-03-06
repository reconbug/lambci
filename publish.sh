#!/bin/bash -ex

REGIONS="\
  ap-northeast-1 \
  ap-northeast-2 \
  ap-south-1 \
  ap-southeast-1 \
  ap-southeast-2 \
  ca-central-1 \
  eu-central-1 \
  eu-west-1 \
  eu-west-2 \
  eu-west-3 \
  sa-east-1 \
  us-east-1 \
  us-east-2 \
  us-west-1 \
  us-west-2 \
"
VERSION=$(npm run -s v)

echo $VERSION > /tmp/lambci.txt

aws s3api put-object --bucket lambci --key fn/lambci-build-${VERSION}.zip --body build/lambda.zip --acl public-read

aws s3api copy-object --copy-source lambci/fn/lambci-build-${VERSION}.zip --bucket lambci --key fn/lambci-build-latest.zip --acl public-read &

aws s3api put-object --bucket lambci --key fn/latest.txt --body /tmp/lambci.txt --acl public-read &

npm run template
aws s3api put-object --bucket lambci --key templates/lambci.template --body build/versioned.yaml --acl public-read &
aws s3api put-object --bucket lambci --key templates/template.yaml --body build/versioned.yaml --acl public-read &

for region in $REGIONS; do
  aws s3api copy-object --region $region --copy-source lambci/fn/lambci-build-${VERSION}.zip --bucket lambci-${region} --key fn/lambci-build-${VERSION}.zip --acl public-read && \
  aws s3api copy-object --region $region --copy-source lambci-${region}/fn/lambci-build-${VERSION}.zip --bucket lambci-${region} --key fn/lambci-build-latest.zip --acl public-read &
done

for job in $(jobs -p); do
  wait $job
done

rm /tmp/lambci.txt
