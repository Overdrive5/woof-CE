#!/bin/sh -e

command_qemu() {
    echo "$1" >> /tmp/qemu.in
}

wait_for_screenshot() {
    rm -f /tmp/$2.pnm  /tmp/$2-masked.bmp
    started=0
    sleep 1
    for i in `seq 1 $(($1 - 1))`; do
        /bin/echo -ne "\033[H"
        [ -f /tmp/$2.pnm ] && img2txt -d none -H 24 /tmp/$2.pnm
        echo -n "Waiting for $2 (${i}/$1) ... "
        command_qemu "screendump /tmp/$2.pnm"
        sleep 1
        composite -compose atop mask.xpm /tmp/$2.pnm /tmp/$2-masked.bmp
        cmp /tmp/$2.bmp /tmp/$2-masked.bmp > /dev/null || continue
        started=1
        break
    done

    if [ $started -eq 0 ]; then
        echo TIMEOUT
        return 1
    fi

    echo PASS
    return 0
}

[ -p /tmp/qemu.in ] || mkfifo /tmp/qemu.in
[ -p /tmp/qemu.out ] || mkfifo /tmp/qemu.out

if [ -n "$GITHUB_ACTIONS" ]; then
    qemu-system-x86_64 -m 512 -drive format=raw,file=$1 -monitor pipe:/tmp/qemu -vga cirrus -display none &
else
    qemu-system-x86_64 -m 512 -drive format=raw,file=$1 -monitor pipe:/tmp/qemu -vga cirrus &
fi

trap "command_qemu quit" EXIT INT TERM

for SHOT in *.pnm; do
    convert ${SHOT} /tmp/${SHOT%.pnm}.bmp
done

/bin/echo -ne "\033[2J\033[H"

# wait until the desktop is ready
wait_for_screenshot 360 quicksetup

command_qemu "sendkey alt-f4"
wait_for_screenshot 10 welcome1stboot

command_qemu "sendkey alt-f4"
wait_for_screenshot 5 desktop

command_qemu "sendkey ctrl-alt-t"
wait_for_screenshot 10 terminal