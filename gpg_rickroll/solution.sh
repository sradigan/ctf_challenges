#!/usr/bin/bash

startdir="$(pwd)"
workdir="$(mktemp -d)"

#copy our disk image for dissection
cp disk.img.gz ${workdir}

#change to somewhere we can muck up
cd ${workdir}

#unzip the image
gunzip ./disk.img.gz

#run scalpel against it (make sure scalpel's config file is modified to look for pdfs)
scalpel disk.img
for pdf in $(find ./scalpel-output -name '*.pdf'); do
	txtfile=$(basename "${pdf}").txt
	pdftotext -layout "${pdf}" "${txtfile}"
	#Strip any empty lines or non-printables and garbage text
	sed -i 's/[^[:print:]]//g;/^$/d;/^[^=]\+=\+$/,/-----END PGP.*KEY BLOCK-----/{/^[^=]\+=\+$/!{/-----END PGP.*KEY BLOCK-----/!d;};}' "${txtfile}"
done

#import gpg keys into dummy home
export GNUPGHOME="$(mktemp -d)"
for f in $(find . -maxdepth 1 -name '*.txt'); do
	grep -q '\-\-\-\-\-BEGIN PGP.*KEY BLOCK\-\-\-\-\-' $f
	if [ 0 -eq $? ]; then
		sha1sum $f
		gpg --import $f
	fi
done
#hopefully we found some good keys

#make mount point
mkdir ./tmpmnt

#setup loopdevice
sudo losetup -d /dev/loop1
sudo losetup /dev/loop1 ./disk.img -o $(echo '2048*512' | bc)

#mount the image
sudo mount -o loop /dev/loop1 ./tmpmnt
sudo chmod 777 ./tmpmnt

#for debugging, list off what is in the mount
find ./tmpmnt -ls

#get the file hashes
cat ./tmpmnt/index.txt

#pull the encrypted file
cp ./tmpmnt/secret_message.gpg ./enc.gpg
sha1sum ./enc.gpg

#unmount the image
sudo umount ./tmpmnt

#clean up the loop device
sudo losetup -d /dev/loop1

#decrypt the file
gpg --decrypt --try-all-secrets --output ./plaintext.mp3 ./enc.gpg

#debugging, show it is an mp3 file
file plaintext.mp3

#read out the tags
id3v2 -l plaintext.mp3

cd "$startdir"

#clean up our working directory
rm -rf "$workdir"
