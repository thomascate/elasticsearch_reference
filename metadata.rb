name 'elasticsearch_reference'
maintainer 'Thomas Cate'
maintainer_email 'tcate@chef.io'
license 'Apache 2.0'
description 'Installs/Configures elasticsearch_reference'
long_description 'Installs/Configures elasticsearch_reference'
version '0.1.25'
chef_version '>= 12.1' if respond_to?(:chef_version)

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
# issues_url 'https://github.com/<insert_org_here>/elasticsearch_reference/issues'

# The `source_url` points to the development repository for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
# source_url 'https://github.com/<insert_org_here>/elasticsearch_reference'

depends 'java', '~> 1.50'
depends 'elasticsearch', '~> 3.3'
depends 'sysctl', '~> 0.10'
