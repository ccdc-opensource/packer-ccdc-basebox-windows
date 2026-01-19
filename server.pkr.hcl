packer {
  required_version = ">= 1.12.0"
  required_plugins {
    vsphere = {
      source  = "github.com/hashicorp/vsphere"
      version = ">= 2.0.0"
    }
    ansible = {
      version = ">= 1.1.0"
      source = "github.com/hashicorp/ansible"
    }
  }
}

source "vmware-iso" "server" {
  disk_type_id                    = 0
  disk_adapter_type               = "pvscsi"
  guest_os_type                   = "windows2019srv-64"
  network_adapter_type            = "VMXNET3"
  network                         = "nat"
  version                         = 14
  vmx_remove_ethernet_interfaces  = true
  vmx_data                        = {
                                      "firmware": "efi"
                                    } 

  // Settings shared between all builders
  cpus             = 2
  memory           = 4096
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  disk_size        = var.system_disk_size
  disk_additional_size = [ var.x_mirror_disk_size, var.builds_disk_size ]
  headless         = false
  cd_files         = ["answer_files/windows-2022/autounattend.xml",
                      "vmware_drivers/$WinpeDriver$"]
  boot_wait        = "2s"
  boot_command     = ["<enter>"]
  shutdown_command = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  # output_directory = "${ var.output_directory }/${ var.vagrant_box }.${ source.type }"
  communicator     = "winrm"
  winrm_username   = "vagrant"
  winrm_password   = "vagrant"
  winrm_use_ssl    = "false"
  winrm_insecure   = "true"
  winrm_use_ntlm   = "true"
  winrm_timeout    = "10m"
}

source "hyperv-iso" "server" {
  generation        = 2
  boot_order        = ["SCSI:0:0"]
  first_boot_device = "DVD"
  switch_name       = var.hyperv_switch_name
  temp_path         = "tmp"
  vlan_id           = var.hyperv_vlan_id

  // Settings shared between all builders
  cpus             = 2
  memory           = 4096
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  disk_size        = var.system_disk_size
  disk_additional_size = [ var.x_mirror_disk_size, var.builds_disk_size ]
  headless         = false
  cd_files         = ["answer_files/windows-2022/autounattend.xml"]
  boot_wait        = "2s"
  boot_command     = ["<enter>"]
  shutdown_command = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  # output_directory = "${ var.output_directory }/${ var.vagrant_box }.${ source.type }"
  communicator     = "winrm"
  winrm_username   = "vagrant"
  winrm_password   = "vagrant"
  winrm_use_ssl    = "false"
  winrm_insecure   = "true"
  winrm_use_ntlm   = "true"
  winrm_timeout    = "10m"
}

source "vsphere-iso" "server" {
  vm_name              = var.vmware_center_vm_name
  RAM                  = 4096
  CPUs                 = 2
  vcenter_server       = var.vmware_center_host
  host                 = var.vmware_center_esxi_host
  username             = "${var.vmware_center_username}"
  password             = "${var.vmware_center_password}"
  insecure_connection  = false
  datacenter           = var.vmware_center_datacenter
  datastore            = var.vmware_center_datastore
  guest_os_type        = var.vsphere_guest_os_type
  cluster              = var.vmware_center_cluster_name
  remove_network_adapter = true
  convert_to_template  = true
  iso_checksum         = var.iso_checksum
  iso_url              = var.iso_url
  iso_paths            = ["[] /vmimages/tools-isoimages/windows.iso"]
  cd_files = [
    "${path.cwd}/scripts/"
  ]
  cd_content = {
    "autounattend.xml" = templatefile("${abspath(path.root)}/answer_files/windows-2022/autounattend.pkrtpl.hcl", {
      vagrant_username       = var.vagrant_username
      vagrant_password       = var.vagrant_password
      vm_inst_os_language  = "en-US"
      vm_inst_os_keyboard  = "en-US"
      vm_guest_os_language = "en-US"
      vm_guest_os_keyboard = "en-US"
      vm_guest_os_timezone = "UTC"
    })
  }
  disk_controller_type = ["pvscsi"]
  storage {
      disk_size = "${var.disk_size}"
      disk_thin_provisioned = true
  }
  network_adapters {
      network = "${var.vmware_center_vm_network}"
      network_card = "vmxnet3"
  }
  boot_wait            = "2s"
  boot_command         = ["<enter>"]
  shutdown_command     = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator         = "winrm"
  winrm_username       = var.vagrant_username
  winrm_password       = var.vagrant_password
  winrm_use_ssl        = "false"
  winrm_insecure       = "true"
  winrm_use_ntlm       = "true"
  winrm_timeout        = "10m"


}

build {

  sources = [
    # "source.vmware-iso.server",
    "source.vsphere-iso.server"
    # "source.hyperv-iso.server"
  ]

  provisioner "ansible" {
    playbook_file = "${var.ansible_playbook_file}"
    galaxy_file = "${var.ansible_requirements_file}"
    roles_path = "${var.ansible_roles_path}"
    galaxy_force_install = true
    user            = "vagrant"
    use_proxy       = false
    extra_arguments = [
      "-vvv",
      "-e",
      "ansible_winrm_server_cert_validation=ignore",
      "-e",
      "ansible_winrm_scheme=http",
      "-e",
      "ansible_winrm_transport=ntlm",
      "-e", 
      "ansible_become_method=runas",
      "-e",
      "ansible_become_user=System",
      "-e",
      "ansible_winrm_read_timeout_sec=600"
    ]
  }

  # post-processors {

  #   post-processor "vagrant" {
  #     output               = "${var.output_directory}/${ var.vagrant_box }.${ replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop") }.box"
  #     vagrantfile_template = "Vagrantfile-uefi.template"
  #   }

    # // Once box has been created, upload it to Artifactory
    # post-processor "shell-local" {
    #   command = join(" ", [
    #     "jf rt upload",
    #     "--target-props \"box_name=${ var.vagrant_box };box_provider=${replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop")};box_version=${ formatdate("YYYYMMDD", timestamp()) }.0\"",
    #     "--retries 10",
    #     "--access-token ${ var.artifactory_api_key }",
    #     "--user ${ var.artifactory_username }",
    #     "--url \"https://artifactory.ccdc.cam.ac.uk/artifactory\"",
    #     "${var.output_directory}/${var.vagrant_box}.${replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop")}.box",
    #     "ccdc-vagrant-repo/${var.vagrant_box}.${formatdate("YYYYMMDD", timestamp())}.0.${replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop")}.box"
    #   ])
    # }
  # }
}
