#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/libexec/${PKG_NAME}

./mill -i show dist.assembly
install -m 755 out/dist/assembly.dest/out.jar ${PREFIX}/libexec/${PKG_NAME}/mill.jar

tee ${PREFIX}/bin/mill << EOF
#!/bin/sh
exec \${JAVA_HOME}/bin/java -jar \${CONDA_PREFIX}/libexec/mill/mill.jar "\$@"
EOF

# Create batch wrapper so that it has a .cmd extension and is recognized as executable
tee ${PREFIX}/bin/mill.cmd << EOF
call %JAVA_HOME%\bin\java -jar %CONDA_PREFIX%\libexec\mill\mill.jar %*
EOF

./mill -i show dist.publishM2Local --m2RepoPath ${SRC_DIR}/m2
pom_file=$(find ${SRC_DIR}/m2 -name "*.pom")
mv ${pom_file} $(dirname ${pom_file})/pom.xml

cd $(dirname ${pom_file})
sed -i "s/SNAPSHOT/${PKG_VERSION}/g" pom.xml

# Download licenses and move them to ${SRC_DIR}
mvn license:download-licenses -Dgoal=download-licenses
mv target ${SRC_DIR}
