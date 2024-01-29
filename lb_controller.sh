curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

CLUSTER_NAME=app-eks-cluster
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
SERVICE_ACCOUNT_NAME="aws-load-balancer-controller"

# 해당하는 이름의 정책이 있는지 확인
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" --output text)

# 정책이 없으면 새로 생성
if [ -z "$POLICY_ARN" ]; then
    echo "Creating policy ${POLICY_NAME}..."
    aws iam create-policy \
        --policy-name $POLICY_NAME \
        --policy-document file://iam_policy.json
else
    echo "Policy ${POLICY_NAME} already exists. ARN: $POLICY_ARN"
fi

eksctl create iamserviceaccount \
  --cluster=${CLUSTER_NAME} \
  --namespace=kube-system \
  --name=${SERVICE_ACCOUNT_NAME} \
  --role-name ${CLUSTER_NAME}-lb-controller-role \
  --attach-policy-arn=${POLICY_ARN} \
  --approve

helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=${SERVICE_ACCOUNT_NAME}
