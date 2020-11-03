#/bin/bash
 
set -x
set -e
 
para1=
work_dir=$1
count=0

isempty=
 
pwd=${PWD}
 
while read line; do
    echo $line
    isempty="notempty"
    count=$((count+1))
    line1=${line%%/*}
    if [ -z "$line" ]; then
        echo $work_dir not exist !!!!!!!!!!!! 1>&2
        continue
    fi
    if [ $(ls -A $pwd/$line | wc -l) -eq 0 ]; then
        echo $work_dir empty !!!!!!!!!!!! 1>&2
        isempty="empty"
    fi
    workdir=$pwd/$line
    echo ==== $workdir
    cd $workdir
        rm -rf .git
        git init .  1>&2
        git add . -f 1>&2

        if [ "$isempty" = "notempty" ]; then
            git commit -m "init"
            if [ "$line1" = "device" ]; then
                git push --set-upstream git://172.19.110.236/and6r81/$line.git master
            else
                git push --set-upstream git://172.19.110.236/and6r81/platform/$line.git master
            fi
        else
            echo "add empyt_file"
            touch empty_file
            git add .
            git commit -m "add empty_file"
            
            if [ "$line1" = "device" ]; then
              git push --set-upstream git://172.19.110.236/and6r81/$line.git master
            else
              git push --set-upstream git://172.19.110.236/and6r81/platform/$line.git master
            fi

            echo number:$count should be empty $line >> $HOME/log_$(date +%Y_%m_%d)
         fi
    echo -e "number:$count \n"
    cd -
done
