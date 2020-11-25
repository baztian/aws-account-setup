# Set up a hosted zone

Sets up a hosted zone for a subdomain which domain is owned by a different registrar.

The Terraform code has been heavily inspired by
https://www.grailbox.com/2020/04/how-to-set-up-a-domain-in-amazon-route-53-with-terraform/.

Interesting additional information
https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingSubdomain.html.

# DomainFactory configuration (my registrar)

Nameserver -> Add entry
Hostname ${output.this_acm_domain_validation_options.resource_record_name}
Type CNAME
Destination ${output.this_acm_domain_validation_options}

For each entry in ${output.this_route53_name_servers}
Nameserver -> Add entry
Hostname ${output.this_acm_domain_validation_options.domain_name} # the one _without_ the `*.`
Type NS
Destination ${currententry from output.this_route53_name_servers}
