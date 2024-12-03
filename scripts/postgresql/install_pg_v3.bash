#!/bin/bash

PG_VER=$1

if [ ! -d /mnt/volumez/pg_vol ]; then 
	mkdir -p /mnt/volumez/pg_vol
fi 

if [ ! -d /mnt/volumez/pg_wal ]; then 
	mkdir -p /mnt/volumez/pg_wal
fi 

if [ "${PG_VER}" == "" ]; then
        echo ""
        echo "Error: Postgresql version is mandatory."
        echo "Usage: bash install_pg.bash <PG_VER>"
        echo "example:"
        echo "bash install_pg.bash 16"
        exit 1
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    if [ "$OS" == "ubuntu" ]; then
        #instal pg on Ubuntu
        sudo apt install curl ca-certificates
        sudo install -d /usr/share/postgresql-common/pgdg
        sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
        sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
        sudo apt update
        sudo apt -y install postgresql-${PG_VER}
	systemctl disable postgresql
	systemctl stop  postgresql

        #adding env variables to postgres's .bash_profile
        echo "export PGHOME=/usr/lib/postgresql/${PG_VER}" >> ~postgres/.bash_profile
        echo "export PGDATA=/mnt/volumez/pg_vol/data" >> ~postgres/.bash_profile
        echo "export PGLOG=/mnt/volumez/pg_vol/log" >> ~postgres/.bash_profile
        echo "export LD_LIBRARY_PATH=\${PGHOME}/lib" >> ~postgres/.bash_profile
        echo "export PATH=\${PATH}:\${PGHOME}/bin" >> ~postgres/.bash_profile
        echo "export PGPASSWORD=postgres" >> ~postgres/.bash_profile

    elif [ "$OS" == "rhel" ]; then
        #instal pg on RHEL
        sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
        sudo dnf -qy module disable postgresql
        sudo dnf install -y postgresql${PG_VER}-server

        #adding env variables to postgres's .bash_profile
        echo "export PGHOME=/usr/pgsql-${PG_VER}" >> ~postgres/.bash_profile
        echo "export PGDATA=/mnt/volumez/pg_vol/data" >> ~postgres/.bash_profile
        echo "export PGLOG=/mnt/volumez/pg_vol/log" >> ~postgres/.bash_profile
        echo "export LD_LIBRARY_PATH=\${PGHOME}/lib" >> ~postgres/.bash_profile
        echo "export PATH=\${PATH}:\${PGHOME}/bin" >> ~postgres/.bash_profile
        echo "export MANPATH=\${PGHOME}/share/man" >> ~postgres/.bash_profile
        echo "export PGPASSWORD=postgres" >> ~postgres/.bash_profile

    else
        echo "Unsupported OS: $OS"
        exit 1
    fi

    #create directories and permissions
    mkdir /mnt/volumez/pg_vol/data  /mnt/volumez/pg_vol/log
    chown -R postgres:postgres  /mnt/volumez/pg_vol  /mnt/volumez/pg_wal

    #init the database
    su - postgres -c 'pg_ctl -D ${PGDATA} initdb'

    #move wal to separate volume
    mv /mnt/volumez/pg_vol/data/pg_wal /mnt/volumez/pg_wal/
    ln -s /mnt/volumez/pg_wal/pg_wal /mnt/volumez/pg_vol/data/pg_wal

    #update postgres parameters
    chown postgres:postgres /tmp/postgresql.conf
    su - postgres -c 'cp /tmp/postgresql.conf ${PGDATA}/postgresql.conf'

    #update kernel parameters
    echo "vm.dirty_expire_centisecs=10" >> /etc/sysctl.conf
    echo "vm.dirty_writeback_centisecs=10" >> /etc/sysctl.conf
    echo "vm.swappiness=0" >> /etc/sysctl.conf

    #apply kernel parameter changes
    sysctl -p
    
    #create a service for disabling transparent hugepages
    sudo tee /etc/systemd/system/disable-thp.service > /dev/null <<EOF
[Unit]
Description=Disable Transparent Huge Pages (THP)
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

   sudo systemctl daemon-reload
   sudo systemctl enable disable-thp
   sudo systemctl start disable-thp

    #start database
    su - postgres -c 'pg_ctl -D ${PGDATA} -l ${PGLOG}/logfile start'

else
    echo "/etc/os-release file not found. Cannot determine OS."
    exit 1
fi

