# Kickstart file automatically generated by anaconda.

install
url --url http://download.fedora.redhat.com/pub/fedora/linux/releases/8/Fedora/i386/os/

%include common-install.ks

repo --name=f8 --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-8&arch=i386
repo --name=f8-updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f8&arch=i386
repo --name=freeipa --baseurl=http://freeipa.com/downloads/devel/rpms/F7/i386/ --includepkgs=ipa*
repo --name=ovirt-management --baseurl=http://ovirt.et.redhat.com/repos/ovirt-management-repo/i386/

%packages
%include common-pkgs.ks

%post

%include common-post.ks
%include devel-post.ks

# get the PXE boot image; this can take a while
IMAGE=ovirt-pxe-host-image-i386-0.3.tar.bz2
wget http://ovirt.org/download/$IMAGE -O /tmp/$IMAGE
tar -C / -jxvf /tmp/$IMAGE
rm -f /tmp/$IMAGE

%end
