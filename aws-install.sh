# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

# This script is to be ran in an ec2 AWS instance using nubis-base image

PERL_VER="5.10.1"
PERL_DIR="/opt/perl-$PERL_VER"
PERL="$PERL_DIR/bin/perl"
PERL_BUILD=/usr/local/bin/perl-build
PERL_BUILD_OPTIONS="--noman -A ccflags=-fPIC -D useshrplib"
CPANM=/usr/local/bin/cpanm
CARTON="$PERL_DIR/bin/carton"
GITHUB_BRANCH="upstream-merge"

yum -y update \
    && yum -y install epel-release \
    && yum -y groupinstall  "Development Tools" \
    && yum -y install \
        expat-devel \
        gd-devel \
        gmp-devel \
        httpd24-devel \
	    mod24_perl-devel \
        mysql55-devel \
        openssl-devel \
        perl-core \
    && yum clean all

wget https://raw.github.com/tokuhirom/Perl-Build/master/perl-build -O $PERL_BUILD
wget https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm -O $CPANM
chmod a+x $PERL_BUILD $CPANM

$PERL_BUILD $PERL_BUILD_OPTIONS $PERL_VER /opt/perl-$PERL_VER

$PERL $CPANM Carton App::FatPacker File::pushd Module::CPANfile ExtUtils::MakeMaker Software::License Getopt::Long

git clone https://github.com/mozilla/webtools-bmo-bugzilla -b $GITHUB_BRANCH /opt/bugzilla/
cd /opt/bugzilla

git clean -df \
    && $PERL Makefile.PL \
    && make cpanfile GEN_CPANFILE_ARGS='-A -U auth_ldap -U auth_radius -U psgi -U inbound_email -U moving -U sqlite -U update -U pg -U oracle -U mod_perl -U smtp_auth' \
    && $PERL $CPANM -l local ExtUtils::ParseXS \
    && $CARTON install \
    && $CARTON bundle --cached \
    && $CARTON fatpack \
    && rm -vfr local

./vendor/bin/carton install --cached --deployment

rpm -qa > RPM_LIST
tar zcf /vendor.tar.gz RPM_LIST cpanfile cpanfile.snapshot vendor
