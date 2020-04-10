pipeline {
    agent {
        label'master'
    }
    parameters {
        choice(name: 'OpenshiftContainerPlatformVersion', choices: ['3.11', '4.0', '4.2', '4.3'], description: 'RedHat OpenShift version to deploy',)
        choice(name: 'Environment', choices: ['mcpvc-lab-coe-trex', 'Env-2', 'Env-3'], description: 'T-REX AWS target Environment',)
        choice(name: 'aws_region', choices: ['us-east-1', 'us-west-2', ''], description: 'AWS region to deploy OpenShift CFT',)
        string(name: 'stack_name', defaultValue: '', description: 'OpenShift CFT stack Name',)
        choice(name: 'state', choices: ['present', 'absent'], description: 'OpenShift CFT deploy/changeset-deploy and delete condition',)
        choice(name: 'AZ_1', choices: ['us-east-1a', 'us-east-1b', 'us-east-1c', 'us-east-1d', 'us-east-1e', 'us-east-1f'], description: 'OpenShift HA AZ 1',)
        choice(name: 'AZ_2', choices: ['us-east-1a', 'us-east-1b', 'us-east-1c', 'us-east-1d', 'us-east-1e', 'us-east-1f'], description: 'OpenShift HA AZ 2',)
        choice(name: 'AZ_3', choices: ['us-east-1a', 'us-east-1b', 'us-east-1c', 'us-east-1d', 'us-east-1e', 'us-east-1f'], description: 'OpenShift HA AZ 3',)
        string(name: 'VPCCIDR', defaultValue: '10.192.0.0/16', description: 'vpc cidr block range',)
        string(name: 'PrivateSubnet1CIDR', defaultValue: '10.192.0.0/19', description: 'private subnet 1 cidr block range',)
        string(name: 'PrivateSubnet2CIDR', defaultValue: '10.192.32.0/19', description: 'private subnet 2 cidr block range',)
        string(name: 'PrivateSubnet3CIDR', defaultValue: '10.192.64.0/19', description: 'private subnet 3 cidr block range',)
        string(name: 'PublicSubnet1CIDR', defaultValue: '10.192.128.0/20', description: 'public subnet 1 cidr block range',)
        string(name: 'PublicSubnet2CIDR', defaultValue: '10.192.144.0/20', description: 'public subnet 2 cidr block range',)
        string(name: 'PublicSubnet3CIDR', defaultValue: '10.192.160.0/20', description: 'public subnet 3 cidr block range',)
        string(name: 'RemoteAccessCIDR', defaultValue: '73.135.216.94/32', description: 'container access cidr ip range',)
        string(name: 'ContainerAccessCIDR', defaultValue: '73.135.216.94/32', description: 'container access cidr ip range',)
        string(name: 'DomainName', defaultValue: 'oscarose-ogba.com', description: 'Route53 domain name',)
        string(name: 'HostedZoneID', defaultValue: 'Z1ZVUHT3L33LTB', description: 'Hosted Zone id',)
        string(name: 'SubDomainPrefix', defaultValue: 'openshift', description: 'OpenShift sub level domain name',)
        string(name: 'KeyPairName', defaultValue: 'docker', description: 'OpenShift instance key pair name',)
        choice(name: 'AmiId', choices: ['ami-0916c408cb02e310b', ''], description: 'OpenShift instance Ami Id',)
        choice(name: 'NumberOfMaster', choices: ['1', '2', '3'], description: 'OpenShift instance type',)
        choice(name: 'NumberOfEtcd', choices: ['1', '2', '3'], description: 'OpenShift instance type',)
        choice(name: 'NumberOfNodes', choices: ['1', '2', '3'], description: 'OpenShift instance type',)
        choice(name: 'MasterInstanceType',choices: ['m5.xlarge', 'm4.xlarge', ''], description: 'OpenShift master instance type',)
        choice(name: 'EtcdInstanceType', choices: ['m5.xlarge', 'm4.xlarge', ''], description: 'OpenShift etcd instance type',)
        choice(name: 'NodesInstanceType', choices: ['m5.xlarge', 'm4.xlarge', ''], description: 'OpenShift worker node instance type',)
        string(name: 'OpenShiftAdminPassword', defaultValue: '', description: 'OpenShift admin UI password',)
        string(name: 'RedhatSubscriptionUserName', defaultValue: 'oscarose', description: 'RedHat OpenShift subscription username',)
        string(name: 'RedhatSubscriptionPassword', defaultValue: '', description: 'RedHat OpenShift subscription password',)
        string(name: 'RedhatSubscriptionPoolID', defaultValue: '8a85f99a707807c30170833f7f5f2066', description: 'RedHat OpenShift subscription pool id',)
    }
    stages {
        stage('clone down openshift repo') {
            steps {
                git branch: 'master',
                    credentialsId: 'github_jenkins',
                        url: 'https://github.com/oscarose/demoshift.git'
            }
        }
        stage('deploy openshift cft') {
            steps {
                script {
                    wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[password: "${OpenShiftAdminPassword}", var: 'PSWD']]]) {
                        wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[password: "${RedhatSubscriptionPassword}", var: 'PSWD1']]]) {
                            sh """
                            aws s3 mb s3://openshift-ogbacft --region us-east-1
                            aws s3 cp $WORKSPACE/OpenShiftCFT.yaml s3://openshift-ogbacft
                            ansible-playbook $WORKSPACE/OpenShiftdelpoy.yaml \n
                                --extra-vars "ansible_python_interpreter=/usr/bin/python OpenshiftContainerPlatformVersion=${OpenshiftContainerPlatformVersion} \n
                                Environment=${Environment} aws_region=${aws_region} stack_name=${stack_name} state=${state} AZ_1=${AZ_1} AZ_2=${AZ_2} AZ_3=${AZ_3} \n
                                VPCCIDR=${VPCCIDR} PrivateSubnet1CIDR=${PrivateSubnet1CIDR} PrivateSubnet2CIDR=${PrivateSubnet2CIDR} PrivateSubnet3CIDR=${PrivateSubnet3CIDR} \n
                                PublicSubnet1CIDR=${PublicSubnet1CIDR} PublicSubnet2CIDR=${PublicSubnet2CIDR} PublicSubnet3CIDR=${PublicSubnet3CIDR} RemoteAccessCIDR=${RemoteAccessCIDR} \n
                                ContainerAccessCIDR=${ContainerAccessCIDR} DomainName=${DomainName} HostedZoneID=${HostedZoneID} SubDomainPrefix=${SubDomainPrefix} KeyPairName=${KeyPairName} \n
                                AmiId=${AmiId} NumberOfMaster=${NumberOfMaster} NumberOfEtcd=${NumberOfEtcd} NumberOfNodes=${NumberOfNodes} MasterInstanceType=${MasterInstanceType} EtcdInstanceType=${EtcdInstanceType} \n
                                NodesInstanceType=${NodesInstanceType} OpenShiftAdminPassword=${OpenShiftAdminPassword} RedhatSubscriptionUserName=${RedhatSubscriptionUserName} RedhatSubscriptionPassword=${RedhatSubscriptionPassword} \n
                                RedhatSubscriptionPoolID=${RedhatSubscriptionPoolID}"
                            aws s3 rm s3://openshift-ogbacft/OpenShiftCFT.yaml
                            aws s3 rb s3://openshift-ogbacft
                            """
                        }
                    }
                }
            }
        }
    }
}
