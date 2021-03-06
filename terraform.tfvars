# The type of cluster that will be created/used (kubernetes, openshift, ocp4, or crc) Use "openshift" for OpenShift 3.11
cluster_type="ocp4"
# Flag indicating if we are using an existing cluster or creating a new one
cluster_exists="true"

# The prefix that should be applied to the cluster name and service names (if not provided
# explicitly). If not provided then the resource_group_name will be used as the prefix.
name_prefix="gsi-learning-ocp43"

# The cluster name can be provided (particularly if using an existing cluster). The value
# for cluster name used by the scripts will be set in the following order of presidence:
# - "${cluster_name}"
# - "${name_prefix}-cluster"
# - "${resource_group_name}-cluster"
cluster_name="gsi-learning-ocp43"

resource_group_name="gsi-cloudnative-squad"
vlan_region="us-east"
# Vlan config

# The following values tell the IBMCloud terraform provider the details about the new
# cluster it will create.
# If `cluster_exists` is set to `true` then these values are not needed
#vlan_datacenter="wdc04"
#private_vlan_id="2440701"
#public_vlan_id="2440699"

