# Upgrade from v1.10.x to v1.11.x

In this version of `fury-eks-installer`, we had to introduce support for launch templates due to the [deprecation of launch configurations](https://aws.amazon.com/blogs/compute/amazon-ec2-auto-scaling-will-no-longer-add-support-for-new-ec2-features-to-launch-configurations/).

To achieve this goal, we introduced a new variable `node_pools_launch_kind` (that defaults to `launch_templates`) to select wheter to use launch templates, launch configurations or both.

## Migrate from launch configurations to launch templates

1. Cordon all the existing nodes created using launch configurations using `kubectl cordoni <node_name>`.

> ⚠️ **WARNING**
> If any of the node fails before migrating to launch templates, the pods will have nowhere to be scheduled. If you can't cordon all the nodes at once, take note of the existing nodes and start cordoning them after the new nodes from the launch templates start joining the cluster.

2. Add `node_pools_launch_kind = "both"` to your Terraform module configuration and apply.

3. Wait for the new nodes to join the cluster.

4. Drain the old nodes that you cordoned in step 1 using `kubectl drain --ignore-daemonsets --delete-local-data <node_name>`. Now all the pods are running on nodes created with launch templates.

5. Change `node_pools_launch_kind` to `"launch_templates"` in your Terraform module configuration and apply.
