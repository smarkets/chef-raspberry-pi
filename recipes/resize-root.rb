#
# Resize the root partition to fit the SD card.
# This is copied mostly verbatim from raspi-config
#

if not File.exists?('/etc/partition-resize-stamp')

  bash "resize_partition" do
    user "root"
    returns [1, 0] # fdisk will return an error if it can't re-read the partition table (normal)
    code <<-EOH
  PART_START=$(parted /dev/mmcblk0 -ms unit s p | grep "^2" | cut -f 2 -d:)
  [ "$PART_START" ] || return 1
  # Return value will likely be error for fdisk as it fails to reload the
  # partition table because the root fs is mounted
  fdisk /dev/mmcblk0 <<EOF
p
d
2
n
p
2
$PART_START

p
w
EOF
EOH
  end

  cookbook_file "/etc/init.d/resize2fs_once" do
    owner "root"
    mode "700"
  end

  bash "update-rcd" do
    user "root"
    code "update-rc.d resize2fs_once defaults"
  end

  file "/etc/partition-resize-stamp"

  log "Rebooting system now..."

  bash "reboot" do
    user "root"
    code "reboot"
  end

  ruby_block "exit_recipe" do
    # Abort the run here so we don't get interrupted by the reboot
    block do
      raise
    end
  end
end
