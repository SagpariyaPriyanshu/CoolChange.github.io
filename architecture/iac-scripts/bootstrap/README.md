# Bootstrap

Creates the S3 bucket + DynamoDB table that hold Terraform's remote state
for every environment in this project. This has to be a separate config
from everything else, since a config can't store its state in a backend
it hasn't created yet.

Run once, manually, before touching `environments/`:

```
cd bootstrap
terraform init
terraform plan
terraform apply
```

State for this config itself stays local (`terraform.tfstate` in this
folder — already covered by the root `.gitignore`). That's a deliberate
one-off exception: this config changes so rarely it's not worth the
extra indirection of storing its own state remotely.
