echo "Please Input Profile Name:"
read profile
echo "Please Input Project Name:"
read project
echo "Please Input ENV:"
read env
echo "Please Input Region:"
read region

# Create S3 bucket storage tfstate file
aws s3api create-bucket --bucket $project-$env-iac-state --region $region --create-bucket-configuration LocationConstraint=$region --profile $profile
aws s3api put-bucket-versioning --bucket $project-$env-iac-state --versioning-configuration Status=Enabled --region $region --profile $profile
aws s3api put-public-access-block \
    --bucket $project-$env-iac-state \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region $region --profile $profile

# Create Dynamodb table lock state
aws dynamodb create-table \
      --table-name $project-$env-terraform-state-lock \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --tags Key=Name,Value=$project-$env-terraform-state-lock Key=Environment,Value=$env \
      --region $region \
      --profile $profile

# Create KMS key 
KMS_KEY_ID=$(aws kms create-key --description "Encrypt tfstate in s3 backend" --query "KeyMetadata.KeyId" --output text --profile $profile --region $region)
aws kms create-alias --alias-name alias/$project-$env-iac --target-key-id $KMS_KEY_ID --profile $profile --region $region
KMS_KEY_ARN=$(aws kms describe-key --key-id $KMS_KEY_ID --query "KeyMetadata.Arn" --output text --profile $profile --region $region) && echo "Terraform KMS Key ARN: \n" $KMS_KEY_ARN
