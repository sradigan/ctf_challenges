#!/usr/bin/bash
ctfflag='flag{rickastley4ever}'

startdir="$(pwd)"
workdir="$(mktemp -d)"

cd ${workdir}

#create disk image
dd if=/dev/zero of=./disk.img count=8 bs=1048576

#create partitions
echo -ne 'o\nn\np\n1\n\n\nw\nq\n' | fdisk ./disk.img

#make mount point
mkdir ./tmpmnt

#Download video from youtube and extract audio
youtube-dl -x --audio-format mp3 https://www.youtube.com/watch\?v\=dQw4w9WgXcQ

#Rename that terrible filename
mv Rick\ Astley\ -\ Never\ Gonna\ Give\ You\ Up\ \(Official\ Music\ Video\)-dQw4w9WgXcQ.mp3 most_excellent.mp3

#Remove any tags from file
id3v2 -D most_excellent.mp3

#Add in our tags and the CTF flag
id3v2 -t 'Never Gonna Give You Up' -a 'Rick Astley' -c "${ctfflag}" most_excellent.mp3

#generate gpg keys
export GNUPGHOME="$(mktemp -d)"
cat >foo <<EOF
     %echo Generating a basic OpenPGP key
     Key-Type: RSA
     Key-Length: 2048
     Subkey-Type: ELG-E
     Subkey-Length: 2048
     Name-Real: Joe Tester
     Name-Comment: No Protection
     Name-Email: joe@foo.bar
     Expire-Date: 0
     # Do a commit here, so that we can later print "done" :-)
     %no-protection
     %commit
     %echo done
EOF
gpg --batch --generate-key foo

#export keys to file
gpg --armor --export '<joe@foo.bar>' > gpg.pub
gpg --armor --export-secret-keys '<joe@foo.bar>' > gpg.priv

#print text to pdf files
text2pdf gpg.pub > gpg_pub.pdf
text2pdf gpg.priv > gpg_priv.pdf

#encrypt file
gpg --output secret_message.gpg --encrypt --recipient '<joe@foo.bar>' most_excellent.mp3

#setup loopdevice
sudo losetup -d /dev/loop1
sudo losetup /dev/loop1 ./disk.img -o $(echo '2048*512' | bc)

#create filesystem
sudo mkfs.ext4 /dev/loop1

#mount fs
sudo mount -o loop /dev/loop1 ./tmpmnt

sudo chmod 777 ./tmpmnt

#copy all files to disk
cp gpg_pub.pdf gpg_priv.pdf secret_message.gpg ./tmpmnt

cd ./tmpmnt

sha1sum * > index.txt

#delete everything except the encrypted file
rm gpg_pub.pdf gpg_priv.pdf

cd ..

#unmount the image
sudo umount ./tmpmnt

#clean up the loop device
sudo losetup -d /dev/loop1

#compress the image for hosting/downloading
gzip --best ./disk.img

#copy just the disk image back
mv ./disk.img.gz ${startdir}/disk.img.gz

#return to where we started
cd ${startdir}

#clean up all the working files
rm -rf ${workdir}
