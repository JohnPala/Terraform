#Add Azure Provider
provider "azurerm" {
}

#Create Resource Group
resource "azurerm_resource_group" "k8terraform" {
    name = "${var.resource_group_name}"
    location = "${var.location}"
}

#Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "aksterraform" {
    name                = "${var.log_analytics_workspace_name}"
    location            = "${var.log_analytics_workspace_location}"
    resource_group_name = "${azurerm_resource_group.k8terraform.name}"
    sku                 = "${var.log_analytics_workspace_sku}"
}

#Enable Log Analytics Solution
resource "azurerm_log_analytics_solution" "aksterraformsolution" {
    solution_name         = "ContainerInsights"
    location              = "${azurerm_log_analytics_workspace.aksterraform.location}"
    resource_group_name   = "${azurerm_resource_group.k8terraform.name}"
    workspace_resource_id = "${azurerm_log_analytics_workspace.aksterraform.id}"
    workspace_name        = "${azurerm_log_analytics_workspace.aksterraform.name}"

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

#Create AKS Cluster
resource "azurerm_kubernetes_cluster" "k8cluster" {
    name = "${var.cluster_name}"
    location = "${azurerm_resource_group.k8terraform.location}"
    resource_group_name = "${azurerm_resource_group.k8terraform.name}"
    dns_prefix = "${var.dns_prifix}"

    agent_pool_profile{
        name = "aksterraform"
        count = "${var.agent_count}"
        vm_size = "Standard_B2ms"
        os_type = "Linux"
        os_disk_size_gb = 30
    }
    addon_profile{
        oms_agent{
            enabled = true
            log_analytics_workspace_id = "${azurerm_log_analytics_workspace.aksterraform.id}"
        }
    }

    service_principal{
        client_id = "${var.arm_client_id}"
        client_secret = "${var.arm_client_secret}"
    }
    tags ={
        Enviornment = "Development"
    }
}

#Outputs
output "client_key" {
    value = "${azurerm_kubernetes_cluster.k8cluster.kube_config.0.client_key}"
}

output "client_certificate" {
    value = "${azurerm_kubernetes_cluster.k8cluster.kube_config.0.client_certificate}"
}

output "cluster_ca_certificate" {
    value = "${azurerm_kubernetes_cluster.k8cluster.kube_config.0.cluster_ca_certificate}"
}

output "cluster_username" {
    value = "${azurerm_kubernetes_cluster.k8cluster.kube_config.0.username}"
}

output "cluster_password" {
    value = "${azurerm_kubernetes_cluster.k8cluster.kube_config.0.password}"
}

output "kube_config" {
    value = "${azurerm_kubernetes_cluster.k8cluster.kube_config_raw}"
}

output "host" {
    value = "${azurerm_kubernetes_cluster.k8cluster.kube_config.0.host}"
}