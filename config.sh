#!/usr/bin/env bash
## provide the location of python 3.7 lib install path as parameter
## e.g. config.sh


#envName="VIP"
#if [ $# -eq 0 ]
#then
#	# no user env name specified, use default
#    echo "No user env name provided, using default name VIP"
#else
#	envName=$1
#	echo "User provided env name $1"
#fi
#
## setup conda env based on VIP.yml
#
#conda env create -n $envName -f VIP.yml
#conda activate $envName
#echo "Done with conda env setup"
#

set -o errexit

if ! python -c 'import sys; sys.exit(sys.version_info[:2] != (3, 12))'; then
  echo "This installer requires Python 3.12; activate the VIP environment first." >&2
  exit 1
fi

## buld the cellxgene and install -----------

## obtain a clean version cellxgene a specific version by sha key
if [ -e cellxgene ]; then
  echo "The cellxgene directory already exists; move it before running this installer." >&2
  exit 1
fi
git clone https://github.com/nilchia/cellxgene.git
cd cellxgene
git checkout 96eb35b9c6741b6fd3a469e4d064f5f9e3861714 # v_1.3.0_close_button
# Match the NumPy version in VIP_conda_R.yml instead of downgrading it.
grep -qx 'numpy==2.0.1' server/requirements.txt
sed -i 's/^numpy==2\.0\.1$/numpy==2.1.0/' server/requirements.txt
cd ..

## update the client-side source code of cellxgene for VIP
echo -e "\nwindow.store = store;" >> cellxgene/client/src/reducers/index.js
sed -i "s|<div id=\"root\"></div>|$(sed -e 's/[&\\/]/\\&/g; s/|/\\|/g; s/$/\\/;' -e '$s/\\$//' index_template.insert)\n&|" "cellxgene/client/index_template.html"

sed -i "s|logoRelatedPadding = 50|logoRelatedPadding = 60|" "cellxgene/client/src/components/leftSidebar/index.js"

## update the cellxgene title to cellxgene VIP
sed -i "s|title=\"cellxgene\"|title=\"cellxgene VIP\"|" "cellxgene/client/src/components/app.js"

## modify zoom/pan default
sed -i "s|const *scaleMax *= *[0-9\.]\+|const scaleMax = 50000|; s|const *scaleMin *= *[0-9\.]\+|const scaleMin = 0.1|; s|const *panBound *= *[0-9\.]\+|const panBound = 80|" "cellxgene/client/src/util/camera.js"

## update the server-side source code of cellxgene for VIP
## Please change /tmp if different temporary directory is used in your local environment
echo '
from server.app.VIPInterface import route
@webbp.route("/VIP", methods=["POST"])
def VIP():
    return route(request.data,current_app.app_config)' >> cellxgene/server/app/app.py


# Old branch for nicer plots that are incorporated into ver 1.6.1 now
#git clone https://github.com/theislab/scanpy.git
#cd scanpy;git checkout 2ea9f836cec6e12a5cdd37bc4a229d4eadf59d37;cd ..
#pip install scanpy/

cd cellxgene
make pydist
make install-dist
cd ..

## finished setting up ------
./update.VIPInterface.sh all

export LIBARROW_MINIMAL=false

# Newer version of nbconvert works >= 7.7.0
# if [ $(python -c 'import nbconvert; print(nbconvert.__version__)') != "5.6.1" ]; then pip install nbconvert==5.6.1; fi
