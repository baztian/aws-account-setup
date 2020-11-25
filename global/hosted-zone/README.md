# Set up a hosted zone

Sets up a hosted zone for a subdomain which domain is owned by a different registrar.

The Terraform code has been heavily inspired by
https://www.grailbox.com/2020/04/how-to-set-up-a-domain-in-amazon-route-53-with-terraform/.

# DomainFactory configuration (my registrar)

Nameserver -> Add entry
Hostname ${output.this_acm_domain_validation_options.resource_record_name}
Type CNAME
Destination ${output.this_acm_domain_validation_options}
