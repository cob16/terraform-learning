data "aws_caller_identity" "current" {}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  provider = aws.london
  vpc_id   = module.london.vpc_id

  peer_vpc_id   = module.ireland.vpc_id
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_region   = "eu-west-1"

  auto_accept = false //can only be used in the same account and region...
  tags        = module.label.tags
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.ireland
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = module.label.tags
}
