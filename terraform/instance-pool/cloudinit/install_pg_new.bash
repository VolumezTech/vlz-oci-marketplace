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
###	PG_SERVICE_NAME=postgresql
        sudo apt install curl ca-certificates
        sudo install -d /usr/share/postgresql-common/pgdg
        sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
        sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
        sudo apt update
        sudo apt -y install postgresql-${PG_VER}
	#+
	systemctl disable postgresql
	systemctl stop  postgresql
	#+end

        #adding env variables to postgres's .bash_profile
        echo "export PGHOME=/usr/lib/postgresql/${PG_VER}" >> ~postgres/.bash_profile
        echo "export PGDATA=/mnt/volumez/pg_vol/data" >> ~postgres/.bash_profile
        echo "export PGLOG=/mnt/volumez/pg_vol/log" >> ~postgres/.bash_profile
        echo "export LD_LIBRARY_PATH=\${PGHOME}/lib" >> ~postgres/.bash_profile
        echo "export PATH=\${PATH}:\${PGHOME}/bin" >> ~postgres/.bash_profile
        echo "export PGPASSWORD=postgres" >> ~postgres/.bash_profile

    elif [ "$OS" == "rhel" ]; then
        #instal pg on RHEL
###	PG_SERVICE_NAME="postgresql-${PG_VER}"
###	PG_SERVICE_FILE=/usr/lib/systemd/system/${PG_SERVICE_NAME}.service
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

###	#update service file to new data location
###	sed -i "s|Environment=PGDATA=/var/lib/pgsql/${PG_VER}/data/|Environment=PGDATA=/mnt/volumez/pg_vol/data/|" ${PG_SERVICE_FILE}
###	systemctl daemon-reload

    else
        echo "Unsupported OS: $OS"
        exit 1
    fi

    #move wal to separate volume
    mkdir /mnt/volumez/pg_vol/data  /mnt/volumez/pg_vol/log
    chown -R postgres:postgres  /mnt/volumez/pg_vol  /mnt/volumez/pg_wal

###    #stop postgresql service
###    sudo systemctl stop ${PG_SERVICE_NAME}

    #init the database
    su - postgres -c 'pg_ctl -D ${PGDATA} initdb'

    #update postgres parameters
    chown postgres:postgres /tmp/postgresql.conf
    su - postgres -c 'cp /tmp/postgresql.conf ${PGDATA}/postgresql.conf'

    #update kernel parameters
    echo "vm.dirty_expire_centisecs=10" >> /etc/sysctl.conf
    echo "vm.dirty_writeback_centisecs=10" >> /etc/sysctl.conf
    echo "vm.swappiness=0" >> /etc/sysctl.conf

    #apply kernel parameter changes
    sysctl -p
###
###    #disable transparent hugepages
###    echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
###    echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
#+
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
   #+end

###    #start the postgres service
###    systemctl start ${PG_SERVICE_NAME}
###    systemctl enable ${PG_SERVICE_NAME}
    #start database
#+
    su - postgres -c 'pg_ctl -D ${PGDATA} -l ${PGLOG}/logfile start'
#+end

else
    echo "/etc/os-release file not found. Cannot determine OS."
    exit 1
fi

