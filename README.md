Environment variables

// LINUX
// NCLOUD_ACCESS_KEY - (Optional, Required if access_key is not provided) Ncloud access key.
// NCLOUD_SECRET_KEY - (Optional, Required if secret_key is not provided) Ncloud secret
$ export NCLOUD_ACCESS_KEY="accesskey"
$ export NCLOUD_SECRET_KEY="secretkey"
$ export NCLOUD_REGION="KR"
$ terraform plan

// WINDOWS

set TF_VAR_access_key=accesskey
set TF_VAR_secret_key=secretkey
or
setx TF_VAR_access_key accesskey
setx TF_VAR_secret_key secretkey
