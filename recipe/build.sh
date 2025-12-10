#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

download_licenses() {
    pom_file=$1
    pom_xml=$(dirname ${pom_file})/pom.xml
    mv ${pom_file} ${pom_xml}
    sed -i "s/SNAPSHOT/${PKG_VERSION}/g" ${pom_xml}
    pushd $(dirname ${pom_xml})
    mvn license:download-licenses -Dgoal=download-licenses
    popd
}

export -f download_licenses

copy_licenses() {
    license_dir=$1
    if [ $(ls ${license_dir} | wc -l) -gt 0 ]; then
        cp ${license_dir}/* ${SRC_DIR}/target/generated-resources/licenses
    fi
}

export -f copy_licenses

mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/libexec/${PKG_NAME}

./mill -i show dist.installLocal

install -m 644 mill-assembly.jar ${PREFIX}/libexec/${PKG_NAME}/mill-assembly.jar

tee ${PREFIX}/bin/mill << EOF
#!/bin/sh
exec \${JAVA_HOME}/bin/java --enable-native-access=ALL-UNNAMED -jar \${CONDA_PREFIX}/libexec/mill/mill-assembly.jar "\$@"
EOF
chmod +x ${PREFIX}/bin/mill

# Create batch wrapper so that it has a .cmd extension and is recognized as executable
tee ${PREFIX}/bin/mill.cmd << EOF
call %JAVA_HOME%\bin\java --enable-native-access=ALL-UNNAMED -jar %CONDA_PREFIX%\libexec\mill\mill-assembly.jar %*
EOF

./mill -i show __.publishM2Local --m2RepoPath ${SRC_DIR}/m2
find ${SRC_DIR}/m2 -name "*.pom" | xargs -I % bash -c 'download_licenses %'
mkdir -p ${SRC_DIR}/target/generated-resources/licenses
find ${SRC_DIR}/m2 -type d -name "licenses" | grep generated-resources | grep -v "^./target" | xargs -I % bash -c "copy_licenses %"
