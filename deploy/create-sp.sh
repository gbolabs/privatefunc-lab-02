spName="sp-priv-fct-dev-gbo"

# create a new service principal
echo "Create a new service principal"
az ad sp create-for-rbac --name $spName --skip-assignment

# create a new group for the service principal
echo "Create a new group for the service principal"
az ad group create --display-name "grp-priv-fct-dev-gbo" --mail-nickname "grp-priv-fct-dev-gbo"
