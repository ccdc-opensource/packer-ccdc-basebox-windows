variable "iso_url" {
  type    = string
  default = "${env("ISO_URL")}"
}

variable "iso_checksum" {
  type    = string
  default = "${env("ISO_CHECKSUM")}"
}

variable "disk_size" {
  type    = string
  default = "80000"
  description = "System disk size in megabytes."
}

variable "hyperv_switch_name" {
  type    = string
  default = "Default Switch"
}

variable "hyperv_vlan_id" {
  type    = string
  default = env("HYPERV_VLAN_ID")
}

variable "output_directory" {
  type    = string
  default = "${env("PWD")}/output/"
}

variable "artifactory_api_key" {
  type    = string
  default = env("ARTIFACTORY_API_KEY")
}

variable "artifactory_username" {
  type    = string
  default = env("USER")
}
variable "ansible_playbook_file" {
  type    = string
  default = "ansible_provisioning/playbook.yaml"
}
variable "ansible_requirements_file" {
  type    = string
  default = "ansible_provisioning/requirements.yaml"
}
variable "ansible_roles_path" {
  type    = string
  default = "ansible_provisioning/roles"
}

// VSphere settings
variable "vmware_center_cluster_name" {
  type    = string
  default = "${env("VMWARECENTER_CLUSTER_NAME")}"
}
variable "vmware_center_datacenter" {
  type    = string
  default = "${env("VMWARECENTER_DATACENTER")}"
}
variable "vmware_center_datastore" {
  type    = string
  default = "${env("VMWARECENTER_DATASTORE")}"
}
variable "vmware_center_esxi_host" {
  type    = string
  default = "${env("VMWARECENTER_ESXI_HOST")}"
}
variable "vmware_center_host" {
  type    = string
  default = "${env("VMWARECENTER_HOST")}"
}
variable "vmware_center_password" {
  type      = string
  default   = env("VMWARECENTER_PASSWORD")
  sensitive = true
}
variable "vmware_center_username" {
  type    = string
  default = env("VMWARECENTER_USERNAME")
}
variable "vmware_center_vm_folder" {
  type    = string
  default = "${env("VMWARECENTER_VM_FOLDER")}"
}
variable "vmware_center_vm_name" {
  type    = string
  default = "${env("VMWARECENTER_VM_NAME")}"
}
variable "vmware_center_vm_network" {
  type    = string
  default = "${env("VMWARECENTER_VM_NETWORK")}"
}
variable "vsphere_guest_os_type" {}
variable "vagrant_box" {}
variable "cd_files" {}