# CyberSapient EKS Infrastructure

This Terraform configuration deploys a cost-optimized Amazon EKS cluster in the Ohio region (us-east-2) for CyberSapient's development environment.

## 🏗️ Architecture Overview

- **Region**: US East 2 (Ohio) - Most cost-effective region
- **Compute**: Spot instances (t3.medium/t3a.medium) for ~70% cost savings
- **Network**: Single NAT Gateway for cost optimization
- **Storage**: GP3 volumes (20GB) for better price-performance
- **EKS Version**: 1.29 (latest stable)

## 💰 Cost Optimization Features

### Spot Instances
- Primary node group uses 100% spot instances
- Mix of t3.medium and t3a.medium for better availability
- Expected savings: ~70% compared to on-demand

### Network Optimization
- Single NAT Gateway saves ~$45/month per additional gateway
- Smaller subnets to reduce IP allocation costs

### Storage Optimization
- GP3 volumes instead of GP2 (better price-performance)
- Reduced disk size from 50GB to 20GB

### Instance Sizing
- t3.medium for spot workloads
- t3.small for critical on-demand workloads
- Minimal initial scaling (2 spot + 1 on-demand)

## 📋 Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0
3. kubectl for cluster management

## 🚀 Deployment Instructions

### 1. Clone and Navigate
```bash
cd /Users/amarthyanathb/Projects/cybersapient/terraform-cyber/opsverse-eks-iam
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review Configuration
```bash
terraform plan -var-file="../vars.tfvars"
```

### 4. Deploy Infrastructure
```bash
terraform apply -var-file="../vars.tfvars"
```

### 5. Configure kubectl
```bash
aws eks update-kubeconfig --region us-east-2 --name cybersapient-eks-cluster
```

## 🔧 Configuration Files

### Key Files Modified:
- `vars.tfvars` - Updated for Ohio region and cost optimization
- `eks.tf` - Configured spot instances and mixed instance policy
- `network.tf` - Single NAT gateway and proper tagging
- `variables.tf` - Maintains flexibility for future changes

## 📊 Expected Monthly Costs (Approximate)

| Component | Configuration | Monthly Cost (USD) |
|-----------|---------------|-------------------|
| EKS Control Plane | Standard | $72 |
| Spot Instances (2x t3.medium) | ~70% savings | $25 |
| On-Demand Instance (1x t3.small) | Standard | $15 |
| NAT Gateway | Single gateway | $32 |
| EBS Storage (60GB GP3) | 3 nodes | $6 |
| **Total Estimated** | | **~$150/month** |

*Note: Actual costs may vary based on usage patterns and AWS pricing changes.*

## ⚠️ Important Considerations

### Spot Instance Limitations
- Spot instances can be terminated with 2-minute notice
- Not suitable for stateful applications without proper handling
- Consider using node taints and tolerations for workload placement

### Cluster Access
- Update the `aws_auth_users` section in `eks.tf` with actual IAM users
- Default configuration includes `cybersapient-admin` user

### Scaling Considerations
- Node groups configured for auto-scaling (1-6 nodes)
- Monitor costs during scaling events
- Consider using Cluster Autoscaler for efficient scaling

## 🛡️ Security Best Practices

1. **IAM Roles**: Use least-privilege principle
2. **Network**: Private subnets for worker nodes
3. **Pod Security**: Implement Pod Security Standards
4. **Secrets**: Use AWS Secrets Manager or Kubernetes secrets
5. **Monitoring**: Enable CloudWatch Container Insights

## 📈 Monitoring and Cost Management

### Recommended Monitoring
```bash
# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Enable Container Insights (optional)
aws eks create-addon --cluster-name cybersapient-eks-cluster --addon-name aws-for-fluent-bit
```

### Cost Monitoring
- Enable AWS Cost Explorer
- Set up billing alerts
- Use AWS Cost and Usage Reports
- Monitor spot instance interruption rates

## 🔄 Maintenance

### Regular Tasks
1. Update EKS cluster version quarterly
2. Update node AMI monthly
3. Review and optimize resource requests/limits
4. Monitor spot instance interruption patterns

### Backup Strategy
```bash
# Install Velero for cluster backups (recommended)
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts/
helm install velero vmware-tanzu/velero --namespace velero --create-namespace
```

## 🚨 Troubleshooting

### Common Issues

1. **Spot Instance Interruptions**
   ```bash
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

2. **Node Not Ready**
   ```bash
   kubectl describe node <node-name>
   ```

3. **Pod Scheduling Issues**
   ```bash
   kubectl describe pod <pod-name>
   ```

### Spot Instance Handling
```yaml
# Example toleration for spot instances
tolerations:
- key: "spot-instance"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
```

## 📚 Additional Resources

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Spot Instance Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-best-practices.html)
- [EKS Cost Optimization](https://aws.amazon.com/blogs/containers/cost-optimization-for-kubernetes-on-aws/)

## 🤝 Support

For issues related to this infrastructure:
1. Check AWS CloudFormation events
2. Review Terraform state and logs
3. Consult AWS EKS documentation
4. Monitor AWS Service Health Dashboard

---

**Note**: This configuration is optimized for development environments. For production workloads, consider:
- Multi-AZ NAT Gateways
- Larger instance types
- Higher percentage of on-demand instances
- Enhanced monitoring and logging
- Disaster recovery planning