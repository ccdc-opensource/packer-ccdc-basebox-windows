variable "iso_url" {
  type    = string
  default = "https://software-download.microsoft.com/download/pr/19042.508.200927-1902.20h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-gb.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:574f00380ead9e4b53921c33bf348b5a2fa976ffad1d5fa20466ddf7f0258964"
}

variable "vagrant_box" {
  type    = string
  default = "ccdc-basebox/windows-10"
}

variable "system_disk_size" {
  type    = string
  default = "80000"
  description = "System disk size in megabytes."
}

variable "x_mirror_disk_size" {
  type    = string
  default = "200000"
  description = "Size in megabytes for x_mirror disk."
}

variable "builds_disk_size" {
  type    = string
  default = "300000"
  description = "Size in megabytes for builds disk."
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

source "virtualbox-iso" "windows-10-20h2" {
  firmware                  = "efi"
  gfx_accelerate_3d         = true
  gfx_controller            = "vboxsvga"
  gfx_vram_size             = 128
  guest_additions_interface = "sata"
  guest_additions_mode      = "disable"
  guest_os_type             = "Windows10_64"
  hard_drive_interface      = "sata"
  hard_drive_nonrotational  = false
  hard_drive_discard        = false
  iso_interface             = "sata"
  nic_type                  = "82540EM"
  shutdown_command          = false
  usb                       = true
  vboxmanage = [
    ["storagectl", "{{ .Name }}", "--name", "IDE Controller", "--remove"],
  ]

  // Settings shared between all builders
  cpus             = 2
  memory           = 4096
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  disk_size        = var.system_disk_size
  disk_additional_size = [ var.x_mirror_disk_size, var.builds_disk_size ]
  headless         = false
  cd_files         = ["answer_files/windows-10-20h2/autounattend.xml"]
  boot_wait        = "2s"
  boot_command     = ["<enter>"]
  shutdown_command = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  output_directory = "${ var.output_directory }/${ var.vagrant_box }.${ source.type }"
  communicator     = "winrm"
  winrm_username   = "vagrant"
  winrm_password   = "vagrant"
  winrm_use_ssl    = "false"
  winrm_insecure   = "true"
  winrm_use_ntlm   = "true"
  winrm_timeout    = "10m"
}

source "vmware-iso" "windows-10-20h2" {
  // Settings shared between all builders
  cpus             = 2
  memory           = 4096
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  disk_size        = var.system_disk_size
  disk_additional_size = [ var.x_mirror_disk_size, var.builds_disk_size ]
  headless         = false
  cd_files         = ["answer_files/windows-10-20h2/autounattend.xml"]
  boot_wait        = "2s"
  boot_command     = ["<enter>"]
  shutdown_command = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  output_directory = "${ var.output_directory }/${ var.vagrant_box }.${ source.type }"
  communicator     = "winrm"
  winrm_username   = "vagrant"
  winrm_password   = "vagrant"
  winrm_use_ssl    = "false"
  winrm_insecure   = "true"
  winrm_use_ntlm   = "true"
  winrm_timeout    = "10m"
}

source "hyperv-iso" "windows-10-20h2" {
  generation   = 2
  boot_order   = ["SCSI:0:0"]
  first_boot_device = "DVD"
  switch_name       = var.hyperv_switch_name
  temp_path         = "tmp"
  vlan_id           = var.hyperv_vlan_id
  // Settings shared between all builders
  cpus             = 2
  memory           = 4096
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  // Vagrant's Hyper-V provider fails to import boxes with multiple disks properly
  // https://github.com/hashicorp/vagrant/pull/12283 will fix this.
  // In the meantime, just provision one very large disk for the VM.
  disk_size        = 400000
  // disk_additional_size = [ var.x_mirror_disk_size, var.builds_disk_size ]
  headless         = false
  cd_files         = ["answer_files/windows-10-20h2/autounattend.xml"]
  boot_wait        = "2s"
  boot_command     = ["<enter>"]
  shutdown_command = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  output_directory = "${ var.output_directory }/${ var.vagrant_box }.${ source.type }"
  communicator     = "winrm"
  winrm_username   = "vagrant"
  winrm_password   = "vagrant"
  winrm_use_ssl    = "false"
  winrm_insecure   = "true"
  winrm_use_ntlm   = "true"
  winrm_timeout    = "10m"
}

build {

  sources = [
    "source.vmware-iso.windows-10-20h2",
    "source.hyperv-iso.windows-10-20h2",
    "source.virtualbox-iso.windows-10-20h2",
  ]

  provisioner "ansible" {
    playbook_file = "./ansible_provisioning/playbook.yaml"
    galaxy_file = "./ansible_provisioning/requirements.yaml"
    roles_path = "./ansible_provisioning/roles"
    galaxy_force_install = true
    user            = "vagrant"
    use_proxy       = false
    extra_arguments = [
      // "-vvv",
      "-e",
      "ansible_winrm_server_cert_validation=ignore",
      "-e",
      "ansible_winrm_scheme=http",
      "-e",
      "ansible_become_method=runas",
      "-e",
      "ansible_become_user=System",
      "-e",
      "ansible_winrm_read_timeout_sec=600"
    ]
  }

  post-processors {

    post-processor "vagrant" {
      output               = "${var.output_directory}/${ var.vagrant_box }.${ replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop") }.box"
      vagrantfile_template = "Vagrantfile-uefi.template"
    }

    // Once box has been created, upload it to Artifactory
    post-processor "shell-local" {
      command = join(" ", [
        "jf rt upload",
        "--target-props \"box_name=${ var.vagrant_box };box_provider=${replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop")};box_version=${ formatdate("YYYYMMDD", timestamp()) }.0\"",
        "--retries 10",
        "--access-token ${ var.artifactory_api_key }",
        "--user ${ var.artifactory_username }",
        "--url \"https://artifactory.ccdc.cam.ac.uk/artifactory\"",
        "${var.output_directory}/${var.vagrant_box}.${replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop")}.box",
        "ccdc-vagrant-repo/${var.vagrant_box}.${formatdate("YYYYMMDD", timestamp())}.0.${replace(replace(replace(source.type, "-iso", ""), "hyper-v", "hyperv"), "vmware", "vmware_desktop")}.box"
      ])
    }
  }
}
