## VPC peering
This example links 2 VPC's in separate aws regions together using VPC Peering

```
+------------+           +------------+
|            |           |            |
|   London   | +-------> |  Ireland   |
|            |           |            |
+------------+           +------------+

```

#### References 
https://www.terraform.io/docs/providers/aws/r/vpc_peering_connection_accepter.html
https://www.terraform.io/docs/configuration/providers.html#alias-multiple-provider-instances 