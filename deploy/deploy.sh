# Orchestrates the deployment of the entire solution, available parameters are:

# --recover-keyvault: recover the keyvault
# --cleanup: cleanup the resource group
# --deploy-infra: deploy the infrastructure
# --deploy-functionapp: deploy the function app
# --deploy-vm: deploy the vm
# --deploy-all: deploy the entire solution
# --help: display the help

# if parameter $1 says --recover-keyvault, then recover the keyvault
if [ "$1" = "--recover-keyvault" ]; then
    sh ./recover-keyvault.sh
elif [ "$1" = "--cleanup" ]; then
    # Handle cleanup logic here
    echo "Performing cleanup..."
elif [ "$1" = "--deploy-infra" ]; then
    # Handle infrastructure deployment logic here
    echo "Deploying infrastructure..."
    sh ./deploy.infra.sh
elif [ "$1" = "--deploy-functionapp" ]; then
    # Handle function app deployment logic here
    echo "Deploying function app..."
    sh ./deploy.functionapp.sh
elif [ "$1" = "--deploy-vm" ]; then
    # Handle VM deployment logic here
    echo "Deploying VM..."
    sh ./deploy.vm.sh
elif [ "$1" = "--deploy-all" ]; then
    # Handle deployment of the entire solution logic here
    echo "Deploying the entire solution..."
    sh ./deploy.network.sh
    sh ./recover-keyvault.sh
    sh ./deploy.infra.sh
    sh ./deploy.functionapp.sh
    sh ./deploy.vm.sh
elif [ "$1" = "--help" ]; then
    # Display help information
    echo "Available parameters:"
    echo "--recover-keyvault: recover the keyvault"
    echo "--cleanup: cleanup the resource group"
    echo "--deploy-infra: deploy the infrastructure"
    echo "--deploy-functionapp: deploy the function app"
    echo "--deploy-vm: deploy the vm"
    echo "--deploy-all: deploy the entire solution"
    echo "--help: display the help"
else
    echo "Invalid parameter. Use --help to see the available options."
fi
