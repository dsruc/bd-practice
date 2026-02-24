#!/bin/bash

BACKUP_DIR=../db/backup
DATE=$(date +%F)

docker exec -t postgres_db pg_dump -U app_user company_db > $BACKUP_DIR/backup_$DATE.sql

echo "Бэкап выполнен: $BACKUP_DIR/backup_$DATE.sql"

