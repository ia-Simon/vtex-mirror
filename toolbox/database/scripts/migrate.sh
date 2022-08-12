#!/bin/bash

for migration_script in /migrations/*; do
    echo "#### Running migration: $migration_script"
    psql -U postgres -d rehabilita_db -f ${migration_script}
    if ! [ "$?" -eq "0" ]; then
        echo "!!!! Migration failed: $migration_script"
        exit 1
    fi
done