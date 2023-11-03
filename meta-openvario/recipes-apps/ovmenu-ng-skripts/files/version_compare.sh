vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    
    if [[ ${ver1[0]} > 10000 ]]
    then
       # with fw 17119 make version 0.17119 for a correct compare
            ver1[1]=ver1[0]
            ver1[0]=0
    fi
    if [[ ${ver2[0]} > 10000 ]]
    then
       # with fw 17119 make version 0.17119 for a correct compare
            ver2[1]=ver2[0]
            ver2[0]=0
    fi
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return -1
        fi
    done
    return 0
}
